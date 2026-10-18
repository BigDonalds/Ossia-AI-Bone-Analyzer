"""Per-class tables for the training log and the test-set shortcut check."""
import json
import random
from collections import defaultdict

import torch
from torchvision import transforms

from bone_analyzer.config import ANIMAL_CLASSES, BATCH_SIZE, DAMAGE_LABELS
from bone_analyzer.console import print_header
from bone_analyzer.data.dataset import load_split, make_loader
from bone_analyzer.data.transforms import PrintedMarks, RandomRightAngle, get_val_transform
from bone_analyzer.training.heads import HEADS
from bone_analyzer.training.run_log import detail


def _pct(part, whole):
    return f'{part / whole:.0%}' if whole else '-'


def detail_report(counts, train_losses=None):
    """Plain-text tables of what one validation or test pass got right and wrong, per class.

    found = true positives, missed = false negatives (the class was there, the model said
    something else), false+ = false positives (the model said this class, it was something else).
    """
    lines = []
    if train_losses:
        lines.append('  loss per head, train / val (val climbing while train keeps falling = memorising):')
        for name in ['bone_detection', *HEADS, 'damage']:
            train, val = train_losses.get(f'{name}_loss'), counts['loss'].get(name)
            if train is not None and val is not None:
                lines.append(f'    {name:<16}{train:8.3f} / {val:.3f}')
    correct, seen = counts['bone']
    lines.append(f'  bone detection: {seen[1]} bone photos, {seen[1] - correct[1]} missed (called no-bone) | '
                 f'{seen[0]} no-bone photos, {seen[0] - correct[0]} false alarms (called bone)')
    for head, (_, _, classes, _, _, _) in HEADS.items():
        cm = counts['confusion'][head]          # rows: true class, columns: predicted class
        n, found, predicted = cm.sum(1), cm.diag(), cm.sum(0)
        total = int(n.sum())
        if not total:
            continue
        present = n > 0
        lines.append(f'  {head}: {total} labelled | plain {found.sum().item() / total:.1%} | '
                     f'balanced {(found[present] / n[present]).mean().item():.1%}')
        lines.append(f"    {'class':<20}{'n':>5}{'found':>7}{'missed':>8}{'false+':>8}{'recall':>8}{'precision':>11}"
                     f'  most often mistaken for')
        for i, name in enumerate(classes):
            if not n[i] and not predicted[i]:
                continue
            wrong = cm[i].clone()
            wrong[i] = 0
            mistaken = f'{classes[int(wrong.argmax())]} ({int(wrong.max())})' if wrong.sum() else ''
            lines.append(f'    {name:<20}{int(n[i]):>5}{int(found[i]):>7}{int(n[i] - found[i]):>8}'
                         f'{int(predicted[i] - found[i]):>8}{_pct(int(found[i]), int(n[i])):>8}'
                         f'{_pct(int(found[i]), int(predicted[i])):>11}  {mistaken}')
    lines.append('  damage (bones where the mark was assessed):')
    lines.append(f"    {'mark':<14}{'yes':>5}{'found':>7}{'missed':>8}{'no':>6}{'false+':>8}{'recall':>8}{'precision':>11}")
    for i, mark in enumerate(DAMAGE_LABELS):
        tp, fn, fp, tn = counts['damage'][i].tolist()
        lines.append(f'    {mark:<14}{tp + fn:>5}{tp:>7}{fn:>8}{fp + tn:>6}{fp:>8}{_pct(tp, tp + fn):>8}{_pct(tp, tp + fp):>11}')
    return '\n'.join(lines)


def counts_json(counts):
    """The raw counts behind detail_report, for the one-line JSON record of each pass."""
    return {'confusion': {head: cm.tolist() for head, cm in counts['confusion'].items() if cm.sum()},
            'damage_tp_fn_fp_tn': counts['damage'].tolist(),
            'bone_correct_seen': [counts['bone'][0], counts['bone'][1]], 'eval_loss': counts['loss']}


# Shortcut checks on the test set: the same photos turned a quarter, and with printed marks.
# A model trained without these augmentations found 73% of human bones as taken but 53% turned
# 90 degrees, and read a watermark as "bird". A model that learned the bones and not the photo style scores about the same in
# every column.
ROBUSTNESS_VARIANTS = {'as taken': None, 'turned 90 degrees': RandomRightAngle(turns=1),
                       'printed marks': PrintedMarks(p=1.0)}


def robustness_report(model, device, data_dir):
    """Test-set scores as taken, turned 90 degrees and with printed marks, plus how often the
    human/animal and bone-type answers change from the photo as taken. Returns the numbers."""
    model.eval()
    preds, results = {}, {}
    for name, variant in ROBUSTNESS_VARIANTS.items():
        random.seed(0)
        transform = get_val_transform() if variant is None else transforms.Compose([variant, get_val_transform()])
        dataset, _, _ = load_split(data_dir, 'test', transform)
        got = defaultdict(list)
        with torch.no_grad():
            for batch in make_loader(dataset, BATCH_SIZE, shuffle=False):
                out = model(batch['image'].to(device))
                got['bone'].append((out['bone_detection'] > 0).cpu())
                for key in ('species', 'bone_type', 'animal_class'):
                    got[key].append(out[key].argmax(1).cpu())
                    got[key + '_label'].append(batch[key])
                got['bone_label'].append(batch['bone_detected'] == 1)
        g = {k: torch.cat(v) for k, v in got.items()}
        preds[name] = g
        bone = g['bone_label']

        def rate(mask, hit):
            return round(float(hit[mask].float().mean()), 4) if mask.any() else None

        cls = [rate((g['animal_class_label'] == c) & bone, g['animal_class'] == c)
               for c in range(len(ANIMAL_CLASSES))]
        cls = [c for c in cls if c is not None]
        results[name] = {
            'bones found': rate(bone, g['bone']),
            'no-bone rejected': rate(~bone, ~g['bone']),
            'humans found': rate(bone & (g['species_label'] == 0), g['species'] == 0),
            'animals found': rate(bone & (g['species_label'] == 1), g['species'] == 1),
            'bone type': rate(bone & (g['bone_type_label'] >= 0), g['bone_type'] == g['bone_type_label']),
            'animal class (balanced)': round(sum(cls) / len(cls), 4) if cls else None,
        }
        if variant is not None:
            base = preds['as taken']
            results[name]['human/animal answer changed'] = rate(bone, g['species'] != base['species'])
            results[name]['bone type answer changed'] = rate(bone, g['bone_type'] != base['bone_type'])

    print_header('SHORTCUT CHECK (test set: as taken / turned 90 degrees / with printed marks)')
    names = list(ROBUSTNESS_VARIANTS)
    for metric in results['printed marks']:
        cells = [results[n].get(metric) for n in names]
        print(f"  {metric + ':':<30s}" + ''.join(f"{'' if v is None else f'{v:.1%}':>16s}" for v in cells))
    print('  A model that learned the bones, not the photo style, scores about the same in every column.')
    detail('ROBUSTNESS_JSON ' + json.dumps(results))
    return results
