"""ConvNeXt-Tiny with one output head per question the report answers."""
import timm
import torch
import torch.nn as nn

from bone_analyzer.config import (BONE_TYPES, IMG_SIZE, NUM_AGE_GROUPS, NUM_ANIMAL_CLASSES, NUM_COMPLETENESS,
                                  NUM_DAMAGE_TYPES, NUM_MAMMAL_FAMILIES, NUM_PARTS, NUM_SEX, SPECIES_CLASSES)

# Pretrained on ImageNet-22k (14 million photos), fine-tuned on ImageNet-1k at 384 pixels, the
# size the photos are trained at here. It beat ResNet50 in a backbone comparison.
BACKBONE = 'convnext_tiny.fb_in22k_ft_in1k_384'


class BoneCNN(nn.Module):
    """Shared ConvNeXt-Tiny features feeding one linear head per output; forward() returns raw
    logits keyed by output name. bone_detection and damage are sigmoid outputs, the rest
    softmax.

    Bone length is not predicted: a photo has no scale, so usual lengths come from
    inference/length_reference.json instead.
    """

    def __init__(self, num_bone_types=len(BONE_TYPES), num_species=len(SPECIES_CLASSES),
                 num_parts=NUM_PARTS, num_completeness=NUM_COMPLETENESS,
                 num_damage_types=NUM_DAMAGE_TYPES, num_age_groups=NUM_AGE_GROUPS, num_sex=NUM_SEX,
                 pretrained=True):
        super().__init__()
        # {output name: temperature} from the checkpoint (training.calibration). forward()
        # never applies it; the analyzer divides the logits.
        self.temperatures = {}

        # Pretrained weights unless a checkpoint replaces them. num_classes=0: timm's own pooling
        # and final LayerNorm, no classifier, so one feature vector per photo. Parameter names
        # must start with 'backbone': the trainer gives those the lower learning rate.
        self.backbone = timm.create_model(BACKBONE, pretrained=pretrained, num_classes=0)
        self.shared_fc = nn.Sequential(
            nn.Dropout(0.5),
            nn.Linear(self.backbone.num_features, 1024),
            nn.ReLU(inplace=True),
            nn.Dropout(0.3),
        )

        self.bone_detection_head = nn.Linear(1024, 1)
        self.species_head = nn.Linear(1024, num_species)
        self.bone_type_head = nn.Linear(1024, num_bone_types)
        self.bone_part_head = nn.Linear(1024, num_parts)
        self.completeness_head = nn.Linear(1024, num_completeness)
        self.damage_head = nn.Linear(1024, num_damage_types)        # multi-label
        self.animal_class_head = nn.Linear(1024, NUM_ANIMAL_CLASSES)
        self.animal_family_head = nn.Linear(1024, NUM_MAMMAL_FAMILIES)
        self.age_group_head = nn.Linear(1024, num_age_groups)
        self.sex_head = nn.Linear(1024, num_sex)

    def forward(self, x):
        x = self.shared_fc(self.backbone(x))

        return {
            'bone_detection': self.bone_detection_head(x).squeeze(-1),
            'species': self.species_head(x),
            'bone_type': self.bone_type_head(x),
            'bone_part': self.bone_part_head(x),
            'completeness': self.completeness_head(x),
            'damage': self.damage_head(x),
            'animal_class': self.animal_class_head(x),
            'animal_family': self.animal_family_head(x),
            'age_group': self.age_group_head(x),
            'sex': self.sex_head(x),
        }


def load_bone_cnn(model_path, device='cpu'):
    """Load a checkpoint into a new BoneCNN. Returns (model in eval mode, checkpoint dict)."""
    checkpoint = torch.load(model_path, map_location=device)
    state_dict = checkpoint.get('model_state_dict', checkpoint)

    model = BoneCNN(pretrained=False)
    try:
        model.load_state_dict(state_dict)
    except RuntimeError as error:
        current = model.state_dict()
        if any(key not in current for key in state_dict):
            raise RuntimeError(f'{model_path} was trained with a different network than model.py builds '
                               f'({BACKBONE}); older checkpoints may be ResNet50. Retrain with '
                               f'scripts/train.py.') from error
        # A head whose class list changed in config can't take old weights. Name the head
        # instead of leaving a wall of tensor shapes.
        mismatched = []
        for key, value in state_dict.items():
            if key in current and current[key].shape != value.shape:
                mismatched.append(f'{key.split(".")[0]}: checkpoint {tuple(value.shape)} vs config {tuple(current[key].shape)}')
        if not mismatched:
            raise
        raise RuntimeError('\n'.join(
            ['This checkpoint was trained with different class lists than bone_analyzer/config.py:']
            + ['  ' + m for m in mismatched]
            + ['Retrain with the current config, or use the config that produced it.']
        )) from error
    # A model fed a different input size than it was trained at gives quietly wrong answers
    trained_at = checkpoint.get('img_size') if isinstance(checkpoint, dict) else None
    if trained_at and trained_at != IMG_SIZE:
        print(f'WARNING: this checkpoint was trained at {trained_at}x{trained_at} but config.IMG_SIZE is '
              f'{IMG_SIZE}. Predictions will be unreliable until you retrain or change IMG_SIZE back.')
    model.temperatures = checkpoint.get('temperatures', {}) if isinstance(checkpoint, dict) else {}
    model.to(device).eval()
    return model, checkpoint
