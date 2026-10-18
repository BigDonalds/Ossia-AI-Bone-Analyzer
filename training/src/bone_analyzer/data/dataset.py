"""Annotated bone and no-bone images, the epoch sampler and the data loaders."""
import json
from collections import defaultdict

import cv2
import torch
from torch.utils.data import ConcatDataset, DataLoader, Dataset, Sampler

from bone_analyzer.config import (AGE_LABELS, ANIMAL_CLASSES, BONE_TYPES, COMPLETENESS_LABELS, DAMAGE_LABELS,
                                  DEVICE, IMG_SIZE, MAMMAL_FAMILIES, NO_BONE_RATIO, NUM_WORKERS, PART_LABELS,
                                  SEX_LABELS, annotation_file, images_dir)
from bone_analyzer.data.transforms import get_train_transform, get_val_transform
from bone_analyzer.taxonomy import class_label, family_label


def age_label(phase8):
    """The age group an annotation trains, or None."""
    return phase8.get('age_group') if phase8.get('applicable', False) else None


def _index(labels, value):
    """Position of value in labels, or -1 (masked out of the loss) when missing or unknown."""
    return labels.index(value) if value in labels else -1


class BoneDataset(Dataset):
    """One split's bone or no-bone annotations, with every label as a class index.

    A label that is null or not in its class list is returned as -1 and masked out of
    that head's loss, so an image trains the heads it has labels for and nothing else.
    """

    def __init__(self, data_dir, split='train', transform=None, no_bone=False):
        self.images_dir = images_dir(data_dir)
        self.split = split
        self.transform = transform
        self.annotation_file = annotation_file(split, no_bone, data_dir)
        self.annotations = self._load_annotations()

    def _load_annotations(self):
        path = self.annotation_file
        if not path.exists():
            raise FileNotFoundError(f'Annotation file not found: {path}')
        if path.stat().st_size == 0:
            print(f'  Skipped {path.name}: the file is empty')
            return []
        with open(path, encoding='utf-8') as f:
            annotations = json.load(f)
        print(f'Loaded {len(annotations)} {self.split} annotations from {path.name}')
        return annotations

    def __len__(self):
        return len(self.annotations)

    def __getitem__(self, idx):
        ann = self.annotations[idx]

        image_path = self.images_dir / ann['image_path']
        image = cv2.imread(str(image_path))
        if image is None:
            raise FileNotFoundError(f"Image missing or unreadable: {image_path}")

        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        image = cv2.resize(image, (IMG_SIZE, IMG_SIZE))

        if self.transform:
            image = self.transform(image)
        else:
            image = torch.from_numpy(image).float().permute(2, 0, 1) / 255.0

        phase1 = ann.get('phase1_bone_detection', {})
        phase2 = ann.get('phase2_species', {})
        phase3 = ann.get('phase3_bone_type', {})
        phase4 = ann.get('phase4_bone_part', {})
        phase5 = ann.get('phase5_completeness', {})
        phase6 = ann.get('phase6_damage', {})
        phase8 = ann.get('phase8_biological_profile', {})

        # Each damage mark is trained only where it was assessed (null = not assessed), so a
        # record of cut marks alone still teaches cut marks
        damage_values = [phase6.get(name) for name in DAMAGE_LABELS]
        damage_known = [v is not None for v in damage_values]
        damage = [1.0 if v else 0.0 for v in damage_values]

        # Age and sex are masked independently; an explicit 'unknown' is a trained class
        human_profile = phase8.get('applicable', False)

        return {
            'image': image,
            'image_path': str(image_path),
            'bone_detected': torch.tensor(1.0 if phase1.get('bone_present', False) else 0.0),
            'species': torch.tensor({'human': 0, 'non_human': 1}.get(phase2.get('species'), -1)),
            'bone_type': torch.tensor(_index(BONE_TYPES, phase3.get('bone_type'))),
            'part': torch.tensor(_index(PART_LABELS, phase4.get('part'))),
            'completeness': torch.tensor(_index(COMPLETENESS_LABELS, phase5.get('status'))),
            'damage': torch.tensor(damage),
            'damage_known': torch.tensor(damage_known),
            # Class for every non-human bone; family only for mammals whose bone shows it
            'animal_class': torch.tensor(_index(ANIMAL_CLASSES, class_label(ann))),
            'animal_family': torch.tensor(_index(MAMMAL_FAMILIES, family_label(ann))),
            'age_group': torch.tensor(_index(AGE_LABELS, age_label(phase8))),
            'sex': torch.tensor(_index(SEX_LABELS, phase8.get('sex')) if human_profile else -1),
        }


# Photo sources that make up most of a bone type on their own. Within those bone types,
# photos from anywhere else are repeated each epoch so they are drawn about as often as the
# dominant source. Nothing is dropped. The owl-pellet crops (all greyscale rat bones on the
# same lab background) are most of femur and os coxa; without this, "femur" is learned
# mostly from them rather than from photos like the ones the app receives.
DOMINANT_SOURCES = ('osf',)
MAX_REPEAT = 3


def bone_repeats(annotations):
    """Expected draws per epoch for each bone image (1.0 for almost all of them). Fractions
    are honoured on average: 1.35 means once, plus a second draw in 35% of epochs."""
    source = lambda a: (a.get('source') or 'original').split(':')[0]
    bone_type = lambda a: (a.get('phase3_bone_type') or {}).get('bone_type')
    dominant, other = defaultdict(int), defaultdict(int)
    for a in annotations:
        (dominant if source(a) in DOMINANT_SOURCES else other)[bone_type(a)] += 1
    repeats = []
    for a in annotations:
        bt = bone_type(a)
        if bt and source(a) not in DOMINANT_SOURCES and dominant[bt] > other[bt] > 0:
            repeats.append(min(MAX_REPEAT, dominant[bt] / other[bt]))
        else:
            repeats.append(1.0)
    return repeats


class BalancedBoneSampler(Sampler):
    """Sampler for ConcatDataset([bone, no_bone]): each epoch yields every bone image once (or
    `bone_repeats[i]` times), plus `ratio` times as many no-bone images drawn fresh at random,
    all shuffled together."""

    def __init__(self, num_bone, num_no_bone, ratio=NO_BONE_RATIO, bone_repeats=None):
        self.num_bone = num_bone
        self.num_no_bone = num_no_bone
        self.repeats = torch.tensor(bone_repeats or [1.0] * num_bone, dtype=torch.float64)
        self.expected_bone = int(round(float(self.repeats.sum())))
        self.num_no_bone_per_epoch = min(num_no_bone, round(self.expected_bone * ratio))

    def _bone_draws(self):
        whole = self.repeats.floor()
        extra = (torch.rand(self.num_bone, dtype=torch.float64) < self.repeats - whole).double()
        return torch.repeat_interleave(torch.arange(self.num_bone), (whole + extra).long())

    def __iter__(self):
        draws = self._bone_draws()
        bone = draws[torch.randperm(len(draws))]
        no_bone = torch.randperm(self.num_no_bone)[:self.num_no_bone_per_epoch] + self.num_bone
        order = torch.cat([bone, no_bone])
        return iter(order[torch.randperm(len(order))].tolist())

    def __len__(self):
        return self.expected_bone + self.num_no_bone_per_epoch     # exact on average


def load_split(data_dir, split, transform):
    """A split's bone images joined with its no-bone images when it has any.
    Returns (dataset, number of bone images, number of no-bone images)."""
    bone = BoneDataset(data_dir, split=split, transform=transform)
    if not annotation_file(split, no_bone=True, data_dir=data_dir).exists():
        return bone, len(bone), 0
    no_bone = BoneDataset(data_dir, split=split, transform=transform, no_bone=True)
    if len(no_bone) == 0:
        return bone, len(bone), 0
    return ConcatDataset([bone, no_bone]), len(bone), len(no_bone)


def make_loader(dataset, batch_size, **kwargs):
    """DataLoader with the project's worker and pin-memory settings."""
    return DataLoader(dataset, batch_size=batch_size, num_workers=NUM_WORKERS,
                      pin_memory=DEVICE == 'cuda', **kwargs)


def create_dataloaders(data_dir, batch_size=32):
    """Train loader (augmented, balanced sampling) and validation loader."""
    train_dataset, num_bone, num_no_bone = load_split(data_dir, 'train', get_train_transform())
    val_dataset, _, _ = load_split(data_dir, 'val', get_val_transform())

    if num_no_bone:
        bone_annotations = train_dataset.datasets[0].annotations
        sampler = BalancedBoneSampler(num_bone, num_no_bone, bone_repeats=bone_repeats(bone_annotations))
        train_loader = make_loader(train_dataset, batch_size, sampler=sampler)
    else:
        train_loader = make_loader(train_dataset, batch_size, shuffle=True)
    return train_loader, make_loader(val_dataset, batch_size, shuffle=False)


def create_test_loader(data_dir, batch_size=32):
    test_dataset, _, _ = load_split(data_dir, 'test', get_val_transform())
    return make_loader(test_dataset, batch_size, shuffle=False)
