"""Give every label enough val and test images to be measured, without leaking specimens.

Every label value with at least MIN_TOTAL images (bone type, species, animal class, mammal family, each
damage mark, completeness, bone part, human age group and sex) gets
max(MIN_EVAL, SHARE of its images) in val and in test. Whole specimen groups move from train
(or from an eval split holding more than it needs), so every photo of one specimen stays in
one split, and at least KEEP_IN_TRAIN of every label stays in train. Rare labels are served
first; among the groups that would help, the one costing train the least is moved.
Photos from TRAIN_ONLY_SOURCES always go to train and don't count towards what val and test need.

Run after every build and preprocess:
    python scripts/rebalance_splits.py            # move files and rewrite the annotations
    python scripts/rebalance_splits.py --dry-run  # only print the plan
"""
import argparse
import json
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer.config import DAMAGE_LABELS, IMAGES_DIR, annotation_file
from bone_analyzer.data.dataset import age_label
from bone_analyzer.taxonomy import class_label, family_label

SPLITS = ('train', 'val', 'test')
EVAL_SPLITS = ('val', 'test')
MIN_TOTAL = 8          # labels rarer than this stay in train: too few to learn from and measure
SHARE = 0.10           # wanted in val and in test, as a share of the label's images...
MIN_EVAL = {8: 2, 15: 3}   # ...but at least this many (by label total)
KEEP_IN_TRAIN = 0.55   # never let train fall below this share of any label
# One studio, one background, about half of all humerus photos: learned from, never measured on,
# so val and test humerus scores come from photos like the ones the app receives.
TRAIN_ONLY_SOURCES = ('zenodo_ducks',)


def tags(e):
    """Every label value an annotation carries, as 'field:value' strings."""
    out = []
    bone_type = (e.get('phase3_bone_type') or {}).get('bone_type')
    if bone_type:
        out.append(f'bone_type:{bone_type}')
    species = (e.get('phase2_species') or {}).get('species')
    if species:
        out.append(f'species:{species}')
    if species == 'non_human':
        animal_class, family = class_label(e), family_label(e)
        if animal_class:
            out.append(f'class:{animal_class}')
        if family:                      # only bones that show the family, as the family head trains
            out.append(f'family:{family}')
    damage = e.get('phase6_damage') or {}
    out += [f'damage:{m}' for m in DAMAGE_LABELS if damage.get(m) is True]
    status = (e.get('phase5_completeness') or {}).get('status')
    if status:
        out.append(f'completeness:{status}')
    part = (e.get('phase4_bone_part') or {}).get('part')
    if part:
        out.append(f'part:{part}')
    profile = e.get('phase8_biological_profile') or {}
    if profile.get('applicable'):
        if age_label(profile) not in (None, 'unknown'):
            out.append(f"age:{age_label(profile)}")
        if profile.get('sex') not in (None, 'unknown'):
            out.append(f"sex:{profile['sex']}")
    return out


def group_of(e):
    # split_group joins groups that show one specimen, skeleton or shooting session
    multi = e.get('phase9_multi_image') or {}
    return multi.get('split_group') or multi.get('group_id') or e['image_path']


def train_only(e):
    return (e.get('source') or '').split(':')[0] in TRAIN_ONLY_SOURCES


def wanted(total):
    if total < MIN_TOTAL:
        return 0
    floor = max(n for threshold, n in MIN_EVAL.items() if total >= threshold)
    return max(floor, round(total * SHARE))


def main():
    parser = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    parser.add_argument('--dry-run', action='store_true', help='print the plan without moving anything')
    args = parser.parse_args()
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')   # uploader names aren't always ASCII

    splits = {s: json.loads(annotation_file(s).read_text(encoding='utf-8')) for s in SPLITS}
    split_of = {}
    groups = defaultdict(list)
    for s, entries in splits.items():
        for e in entries:
            groups[group_of(e)].append(e)
            split_of[group_of(e)] = s
    group_tags = {g: Counter(t for e in items for t in tags(e)) for g, items in groups.items()}
    # A group built in two rounds can land in two splits (same uploader, new photos). Rejoin it
    # in the split holding most of its images, train winning ties, before anything else moves.
    leaking = sorted(g for g, items in groups.items() if len({e['image_path'].split('/', 1)[0] for e in items}) > 1)
    for g in leaking:
        held = Counter(e['image_path'].split('/', 1)[0] for e in groups[g])
        split_of[g] = max(SPLITS, key=lambda s: (held[s], s == 'train'))
    if leaking:
        print(f'rejoined {len(leaking)} specimen groups that spanned splits')
    pinned = {g for g, items in groups.items() if any(train_only(e) for e in items)}
    sent = sorted(g for g in pinned if split_of[g] != 'train')
    for g in sent:
        split_of[g] = 'train'
    if sent:
        print(f'sent {len(sent)} train-only specimen groups ({sum(len(groups[g]) for g in sent)} images) to train')

    before = {s: Counter() for s in SPLITS}
    counts = {s: Counter() for s in SPLITS}
    measurable = Counter()   # images that may sit in val or test
    for s, entries in splits.items():
        for e in entries:
            before[s].update(tags(e))
            counts[split_of[group_of(e)]].update(tags(e))
            if not train_only(e):
                measurable.update(tags(e))
    totals = sum(counts.values(), Counter())
    want = {t: wanted(measurable[t]) for t in totals}

    def can_move(g, source, target):
        for t, n in group_tags[g].items():
            if source == 'train' and counts['train'][t] - n < KEEP_IN_TRAIN * totals[t]:
                return False
            if source != 'train' and counts[source][t] - n < want[t]:
                return False   # don't break the other eval split's coverage to fix this one
        return True

    def cost(g, source):
        # share of each label's training images this move takes away, summed; rare labels cost most
        if source != 'train':
            return 0.0
        return sum(n / max(1, counts['train'][t]) for t, n in group_tags[g].items())

    moved = []
    for tag in sorted((t for t in totals if want[t]), key=lambda t: totals[t]):
        for target in EVAL_SPLITS:
            while counts[target][tag] < want[tag]:
                other = 'val' if target == 'test' else 'test'
                options = [(cost(g, s), len(groups[g]), g, s) for g, s in split_of.items()
                           if s in ('train', other) and g not in pinned and group_tags[g][tag]
                           and can_move(g, s, target)]
                if not options:
                    break
                _, _, g, source = min(options)
                counts[source].subtract(group_tags[g])
                counts[target].update(group_tags[g])
                split_of[g] = target
                moved.append((g, source, target, tag))

    print(f"{'moved' if not args.dry_run else 'would move'} {len(moved)} specimen groups "
          f"({sum(len(groups[g]) for g, *_ in moved)} images)")
    for g, source, target, tag in moved:
        print(f'  {len(groups[g]):>3} image(s) {source:>5} -> {target:<5} for {tag:<32} {g}')

    if not args.dry_run and (moved or leaking or sent):
        new = {s: [] for s in SPLITS}
        for s, entries in splits.items():
            for e in entries:
                target = split_of[group_of(e)]
                if target != s:
                    old = e['image_path']
                    e['image_path'] = f"{target}/{old.split('/', 1)[1]}"
                    if (IMAGES_DIR / old).exists():        # not yet preprocessed is fine too
                        (IMAGES_DIR / e['image_path']).parent.mkdir(parents=True, exist_ok=True)
                        shutil.move(str(IMAGES_DIR / old), str(IMAGES_DIR / e['image_path']))
                new[target].append(e)
        for s, entries in new.items():
            annotation_file(s).write_text(json.dumps(entries, indent=2, ensure_ascii=False), encoding='utf-8')

    print(f"\n{'label':<34s} {'total':>6s} {'train':>6s} {'val':>9s} {'test':>9s}   wanted")
    for tag in sorted(totals, key=lambda t: (t.split(':')[0], -totals[t])):
        change = lambda s: f"{counts[s][tag]:>4d}" + (f" ({counts[s][tag] - before[s][tag]:+d})"
                                                       if counts[s][tag] != before[s][tag] else '     ')
        short = '' if counts['val'][tag] >= want[tag] and counts['test'][tag] >= want[tag] else '  SHORT'
        print(f"{tag:<34s} {totals[tag]:>6d} {counts['train'][tag]:>6d} {change('val'):>9s} {change('test'):>9s}"
              f"   {want[tag] or '-'}{short}")


if __name__ == '__main__':
    main()
