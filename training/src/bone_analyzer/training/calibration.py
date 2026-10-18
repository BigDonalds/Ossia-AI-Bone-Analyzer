"""Per-head temperature scaling, fitted on the validation set and stored in the checkpoint."""
from collections import defaultdict
from pathlib import Path

import torch
import torch.nn.functional as F

from bone_analyzer.config import DAMAGE_LABELS
from bone_analyzer.training.heads import HEADS

# A head needs at least this many labelled validation images to fit a temperature; below it,
# the head keeps its raw confidence (temperature 1)
MIN_CALIBRATION_IMAGES = 10
TEMPERATURE_GRID = torch.logspace(-0.6, 1.3, 400)     # 0.25 .. 20


def fit_temperatures(model, loader, device):
    """One temperature per head: the scale that, dividing the head's logits, makes the stated
    confidence match how often the head is right on this set (lowest negative log-likelihood).
    Training to a near-zero loss leaves the raw scores far too sure of themselves (one model claimed
    97% on bone types it got right 81% of the time). The answers never change; only the
    percentages. Damage gets one temperature per mark. Returns {output name: temperature}."""
    model.eval()
    logits, labels = defaultdict(list), defaultdict(list)
    with torch.no_grad():
        for batch in loader:
            b = {k: v.to(device) for k, v in batch.items() if torch.is_tensor(v)}
            out = model(b['image'])
            logits['bone_detection'].append(out['bone_detection'].float().cpu())
            labels['bone_detection'].append(b['bone_detected'].cpu())
            for head, (label_key, output_key, _, _, _, mask_of) in HEADS.items():
                mask = mask_of(b)
                logits[output_key].append(out[output_key][mask].float().cpu())
                labels[output_key].append(b[label_key][mask].cpu())
            known = b['damage_known'] & (b['bone_detected'] == 1).unsqueeze(1)
            for i, mark in enumerate(DAMAGE_LABELS):
                logits[mark].append(out['damage'][:, i][known[:, i]].float().cpu())
                labels[mark].append(b['damage'][:, i][known[:, i]].cpu())

    def best(x, y, binary):
        if len(y) < MIN_CALIBRATION_IMAGES:
            return 1.0
        nll = (lambda t: F.binary_cross_entropy_with_logits(x / t, y).item()) if binary else \
              (lambda t: F.cross_entropy(x / t, y).item())
        return round(float(min(TEMPERATURE_GRID, key=nll)), 3)

    temperatures = {'bone_detection': best(torch.cat(logits['bone_detection']), torch.cat(labels['bone_detection']), True)}
    for _, output_key, _, _, _, _ in HEADS.values():
        temperatures[output_key] = best(torch.cat(logits[output_key]), torch.cat(labels[output_key]), False)
    temperatures['damage'] = [best(torch.cat(logits[m]), torch.cat(labels[m]), True) for m in DAMAGE_LABELS]
    return temperatures


def save_temperatures(model_path, temperatures):
    """Store the temperatures inside the checkpoint (weights untouched), via a temporary file
    so an interrupted write can't corrupt the only copy."""
    checkpoint = torch.load(model_path, map_location='cpu', weights_only=False)
    checkpoint['temperatures'] = temperatures
    tmp = Path(str(model_path) + '.tmp')
    torch.save(checkpoint, str(tmp))
    tmp.replace(model_path)
