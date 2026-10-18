"""Health check for a trained checkpoint.

Usage:
    python scripts/inspect_model.py                     # checkpoints/bone_analyzer.pt
    python scripts/inspect_model.py path/to/other.pt

Checks head sizes, weight statistics, a forward and a backward pass, then prints
the label spread of the annotations and per-class results on the validation set.
"""
import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

import numpy as np
import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer.config import (AGE_LABELS, ANIMAL_CLASSES, BATCH_SIZE, BONE_TYPES, CHECKPOINT_DIR,
                                  COMPLETENESS_LABELS, DAMAGE_LABELS, DATA_DIR, IMG_SIZE, MAMMAL_FAMILIES,
                                  PART_LABELS, SEX_LABELS, SPECIES_CLASSES, annotation_file)
from bone_analyzer.console import Colors, print_colored, print_error, print_header, print_ok, print_separator, print_warn
from bone_analyzer.data.dataset import load_split, make_loader
from bone_analyzer.data.transforms import get_val_transform
from bone_analyzer.model import load_bone_cnn
from bone_analyzer.taxonomy import class_label, family_label

# output name -> number of classes; each output comes from the layer f'{name}_head'
OUTPUT_SIZES = {
    'bone_detection': 1,
    'species': len(SPECIES_CLASSES),
    'bone_type': len(BONE_TYPES),
    'bone_part': len(PART_LABELS),
    'completeness': len(COMPLETENESS_LABELS),
    'damage': len(DAMAGE_LABELS),
    'animal_class': len(ANIMAL_CLASSES),
    'animal_family': len(MAMMAL_FAMILIES),
    'age_group': len(AGE_LABELS),
    'sex': len(SEX_LABELS),
}


def _bar(fraction, width=20):
    filled = int(fraction * width)
    return '#' * filled + '.' * (width - filled)


def _table(counter, total, width):
    for name, n in counter.most_common():
        print(f'  {name:>{width}s}: {n:>5}  {n / total:6.1%}  {_bar(n / total)}')


# --------------------------------------------------------------------------- #
# Checkpoint contents
# --------------------------------------------------------------------------- #

def check_heads(state_dict):
    """True when every head is present with the class count config expects."""
    ok = True
    for name, expected in OUTPUT_SIZES.items():
        weight = state_dict.get(f'{name}_head.weight')
        if weight is None:
            print_error(f'  {name}: missing')
            ok = False
        elif weight.shape[0] != expected:
            print_warn(f'  {name}: {weight.shape[0]} classes, config has {expected}')
            ok = False
        else:
            print_ok(f'  {name}: {expected} classes')
    return ok


def check_weights(state_dict):
    """Weight tensors that are constant (dead) or mostly zero. Returns the dead ones."""
    dead = []
    for key, w in state_dict.items():
        if 'weight' not in key:
            continue
        w = w.float()
        std = w.std().item() if w.numel() > 1 else 1.0
        zeros = (w == 0).float().mean().item()
        if std < 1e-8:
            dead.append(key)
            print_error(f'  {key}: constant (std {std:.2e}, {zeros:.0%} zeros)')
        elif zeros > 0.9:
            print_warn(f'  {key}: {zeros:.0%} zeros (mean {w.mean().item():.4f})')
    if dead:
        print_error(f'  {len(dead)} dead layer(s)')
    else:
        print_ok('  No dead layers')
    backbone = sum(1 for k in state_dict if k.startswith('backbone.'))
    heads = sum(1 for k in state_dict if '_head.' in k)
    print(f'  {backbone} backbone tensors, {heads} head tensors')
    return dead


def head_weight_summary(state_dict):
    for name in OUTPUT_SIZES:
        w, b = state_dict.get(f'{name}_head.weight'), state_dict.get(f'{name}_head.bias')
        if w is not None and b is not None:
            print(f'  {name:<16} weight mean {w.mean().item():7.3f}  std {w.std().item():.3f}  '
                  f'bias mean {b.mean().item():7.3f}')


# --------------------------------------------------------------------------- #
# Model behaviour on random input
# --------------------------------------------------------------------------- #

def check_forward(model):
    """True when one forward pass gives every output at the expected shape."""
    with torch.no_grad():
        out = model(torch.randn(1, 3, IMG_SIZE, IMG_SIZE))
    ok = True
    for name, size in OUTPUT_SIZES.items():
        expected = (1,) if name == 'bone_detection' else (1, size)
        if name not in out:
            print_error(f'  {name}: missing from the output')
            ok = False
        elif tuple(out[name].shape) != expected:
            print_warn(f'  {name}: shape {tuple(out[name].shape)}, expected {expected}')
            ok = False
    if ok:
        print_ok('  All outputs present with the expected shapes')
    return ok


def check_gradients(model):
    """Backward pass from the detection output on random input. The weights are restored
    afterwards, so the check leaves the model as it was."""
    saved = {k: v.clone() for k, v in model.state_dict().items()}
    try:
        model.train()
        model(torch.randn(2, 3, IMG_SIZE, IMG_SIZE))['bone_detection'].sum().backward()
        norms = {name: p.grad.norm().item() for name, p in model.named_parameters() if p.grad is not None}
    finally:
        model.zero_grad()
        model.load_state_dict(saved)
        model.eval()
    if not norms:
        print_error('  No gradients reached any parameter')
        return

    mean = sum(norms.values()) / len(norms)
    print(f'  Total gradient norm {sum(norms.values()):.4f}, mean per tensor {mean:.6f}, '
          f'max {max(norms.values()):.4f}')
    if mean < 1e-6:
        print_error('  Vanishing gradients')
    elif mean < 1e-4:
        print_warn('  Gradients are small')
    backbone = sum(v for k, v in norms.items() if k.startswith('backbone.'))
    heads = sum(v for k, v in norms.items() if '_head.' in k)
    if heads > 0:
        ratio = backbone / heads
        print(f'  Backbone / head gradient ratio: {ratio:.3f}')
        if ratio < 0.01:
            print_warn('  The backbone gets almost no gradient')
        elif ratio > 100:
            print_warn('  The heads get almost no gradient')


# --------------------------------------------------------------------------- #
# Annotations
# --------------------------------------------------------------------------- #

def dataset_report():
    """Label spread across the bone annotations of all three splits (no-bone sets excluded)."""
    splits = {}
    for split in ('train', 'val', 'test'):
        path = annotation_file(split)
        splits[split] = json.loads(path.read_text(encoding='utf-8')) if path.exists() else []
    annotations = [a for entries in splits.values() for a in entries]
    total = len(annotations)
    if not total:
        print_warn('  No annotation files found')
        return
    print(f'  {total} bone images: ' + ', '.join(f'{s} {len(e)}' for s, e in splits.items()))

    species = Counter(a['phase2_species']['species'] or 'unknown' for a in annotations)
    print_colored('\n  Species', bold=True)
    _table(species, total, 12)

    non_human = [a for a in annotations if a['phase2_species']['species'] == 'non_human']
    for title, label_of in (('Animal class', class_label), ('Mammal family (bones that show it)', family_label)):
        print_colored(f'\n  {title}', bold=True)
        if non_human:
            _table(Counter(label_of(a) or 'not trained' for a in non_human), len(non_human), 20)

    print_colored('\n  Bone type per species', bold=True)
    by_species = defaultdict(Counter)
    for a in annotations:
        by_species[a['phase2_species']['species'] or 'unknown'][a['phase3_bone_type'].get('bone_type') or 'not typed'] += 1
    for name in sorted(by_species):
        print_colored(f'  {name} ({sum(by_species[name].values())})', Colors.CYAN)
        _table(by_species[name], sum(by_species[name].values()), 25)

    print_colored('\n  Bone part', bold=True)
    _table(Counter(a.get('phase4_bone_part', {}).get('part') or 'not assessed' for a in annotations), total, 15)
    print_colored('\n  Completeness', bold=True)
    _table(Counter(a.get('phase5_completeness', {}).get('status') or 'not assessed' for a in annotations), total, 15)

    print_colored('\n  Damage', bold=True)
    for mark in DAMAGE_LABELS:
        n = sum(1 for a in annotations if a.get('phase6_damage', {}).get(mark))
        print(f'  {mark:>15s}: {n:>5}  {n / total:6.1%}')

    profiles = [a.get('phase8_biological_profile', {}) for a in annotations
                if a['phase2_species']['species'] == 'human']
    profiles = [p for p in profiles if p.get('applicable')]
    for field in ('age_group', 'sex'):
        if profiles:
            print_colored(f'\n  {field} (human)', bold=True)
            _table(Counter(p.get(field) or 'not assessed' for p in profiles), len(profiles), 12)

    wrong = sum(1 for a in non_human if a.get('phase8_biological_profile', {}).get('applicable'))
    if wrong:
        print_warn(f'  {wrong} animal bones have a biological profile marked applicable (should be human only)')


# --------------------------------------------------------------------------- #
# Validation set
# --------------------------------------------------------------------------- #

def validation_results(model, loader):
    """Per-class accuracy, the bone-type confusion matrix and the confidence spread, from one
    pass over the validation set."""
    n_types = len(BONE_TYPES)
    confusion = np.zeros((n_types, n_types), dtype=int)
    species_seen, species_right = Counter(), Counter()
    confidences = []
    with torch.no_grad():
        for batch in loader:
            out = model(batch['image'])
            type_probs = torch.softmax(out['bone_type'], dim=1)
            type_pred = type_probs.argmax(1)
            species_pred = out['species'].argmax(1)
            has_type = batch['bone_type'] >= 0
            confidences.extend(type_probs.max(1).values[has_type].tolist())
            for true, pred in zip(batch['bone_type'][has_type].tolist(), type_pred[has_type].tolist()):
                confusion[true, pred] += 1
            for true, pred in zip(batch['species'].tolist(), species_pred.tolist()):
                if true >= 0:
                    species_seen[SPECIES_CLASSES[true]] += 1
                    species_right[SPECIES_CLASSES[true]] += pred == true

    if not confusion.sum():
        print_warn('  No bone-type labels in the validation set')
        return

    print_colored('  Species accuracy', bold=True)
    for name in sorted(species_seen):
        print(f'  {name:>12s}: {species_right[name] / species_seen[name]:6.1%}  '
              f'({species_right[name]}/{species_seen[name]})')

    print_colored('\n  Bone-type accuracy', bold=True)
    seen = [i for i in range(n_types) if confusion[i].sum()]
    for i in seen:
        acc = confusion[i, i] / confusion[i].sum()
        color = Colors.GREEN if acc >= 0.8 else Colors.YELLOW if acc >= 0.5 else Colors.RED
        print(f'  {BONE_TYPES[i]:>25s}: {color}{acc:6.1%}{Colors.END}  ({confusion[i, i]}/{confusion[i].sum()})  {_bar(acc)}')

    print_colored('\n  Bone-type confusion (rows: true, columns: predicted)', bold=True)
    print(' ' * 24 + ''.join(f'{BONE_TYPES[j][:8]:>9s}' for j in seen))
    for i in seen:
        cells = ''.join(f'{confusion[i, j]:>9d}' for j in seen)
        print(f'  {BONE_TYPES[i]:>22s}{cells}')
    wrong = 1 - np.trace(confusion) / confusion.sum()
    (print_warn if wrong > 0.3 else print_ok)(f'  {wrong:.0%} of bone-type predictions are another class')

    conf = np.array(confidences)
    print_colored('\n  Bone-type confidence (uncalibrated softmax)', bold=True)
    print(f'  mean {conf.mean():.1%}, median {np.median(conf):.1%}, '
          f'below 50%: {(conf < 0.5).mean():.0%}, above 90%: {(conf > 0.9).mean():.0%}')
    buckets = np.bincount(np.minimum((conf * 10).astype(int), 9), minlength=10)
    for i, n in enumerate(buckets):
        print(f'  {i * 10:>3d}-{i * 10 + 10:<3d}%  {_bar(n / buckets.max(), 30)}  {n}')
    if conf.mean() > 0.95:
        print_warn('  Very confident on almost everything: likely overconfident')
    elif conf.mean() < 0.5:
        print_warn('  Mostly unsure')


def feature_norms(model, loader):
    """Size of the pooled backbone features on one validation batch."""
    norms = []
    hook = model.backbone.register_forward_hook(lambda m, i, out: norms.append(out.flatten(1).norm(dim=1)))
    try:
        with torch.no_grad():
            model(next(iter(loader))['image'])
    finally:
        hook.remove()
    norms = torch.cat(norms).numpy()
    mean, std = norms.mean(), norms.std()
    print(f'  mean {mean:.2f}, std {std:.2f}, range {norms.min():.2f} to {norms.max():.2f}')
    if not 1 < mean < 100:
        print_error('  Feature size is far outside the usual range')
    elif not 5 < mean < 50:
        print_warn('  Feature size is at the edge of the usual range')
    if std / (mean + 1e-8) > 1:
        print_warn(f'  Feature size varies a lot between images (CV {std / mean:.2f})')


def main():
    parser = argparse.ArgumentParser(description='Health check for a trained checkpoint.')
    parser.add_argument('model', type=Path, nargs='?', default=CHECKPOINT_DIR / 'bone_analyzer.pt',
                        help='checkpoint to inspect (default: checkpoints/bone_analyzer.pt)')
    model_path = parser.parse_args().model
    if not model_path.exists():
        print_error(f'No checkpoint at {model_path}')
        sys.exit('Train one first: python scripts/train.py')

    print_separator()
    print_header(f'Checkpoint: {model_path}')
    checkpoint = torch.load(model_path, map_location='cpu')
    state_dict = checkpoint['model_state_dict']
    print(f'  {model_path.stat().st_size / 1e6:.1f} MB, saved after epoch {checkpoint.get("epoch", "?")}')
    if checkpoint.get('temperatures'):
        print(f'  Calibrated: {checkpoint["temperatures"]}')
    else:
        print_warn('  Not calibrated (run scripts/calibrate.py)')

    print_header('\nHeads')
    heads_ok = check_heads(state_dict)
    print_header('\nWeights')
    dead = check_weights(state_dict)
    print_header('\nHead weights')
    head_weight_summary(state_dict)

    metrics = checkpoint.get('val_metrics', {})
    if metrics:
        print_header('\nValidation metrics saved with the checkpoint')
        for key, value in metrics.items():
            (print_ok if value > 0.8 else print_warn if value > 0.5 else print_error)(f'  {key}: {value:.1%}')

    print_header('\nAnnotations')
    dataset_report()

    model, _ = load_bone_cnn(model_path, 'cpu')
    print_header('\nForward pass')
    forward_ok = check_forward(model)
    print_header('\nGradients')
    check_gradients(model)

    val_dataset, _, _ = load_split(DATA_DIR, 'val', get_val_transform())
    val_loader = make_loader(val_dataset, BATCH_SIZE, shuffle=False)
    print_header(f'\nValidation set ({len(val_dataset)} images)')
    validation_results(model, val_loader)
    print_header('\nBackbone feature size')
    feature_norms(model, val_loader)

    print_separator()
    issues = (not heads_ok) + bool(dead) + (not forward_ok)
    if issues:
        print_warn(f'{issues} problem(s) found; see the red and yellow lines above')
    else:
        print_ok('No problems found')


if __name__ == '__main__':
    main()
