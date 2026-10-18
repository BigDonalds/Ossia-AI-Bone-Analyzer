"""Loss functions and per-class loss weights."""
from collections import Counter

import torch
import torch.nn as nn
import torch.nn.functional as F

from bone_analyzer.config import MAX_CLASS_WEIGHT, MIN_CLASS_IMAGES, MIN_CLASS_WEIGHT


class FocalLoss(nn.Module):
    """Cross-entropy scaled by (1 - p_t)^gamma, p_t being the probability given to the true
    class, so examples the model already gets right count for less."""

    def __init__(self, gamma=2.0, weight=None):
        super().__init__()
        self.gamma = gamma
        self.weight = weight

    def forward(self, logits, targets):
        ce_loss = F.cross_entropy(logits, targets, weight=self.weight, reduction='none')
        p_t = torch.exp(-ce_loss)
        return ((1 - p_t) ** self.gamma * ce_loss).mean()


def compute_class_weights(annotations, label_of, class_list):
    """Per-class weights as inverse square root frequency, normalised to mean 1 and clamped.

    Classes with fewer than MIN_CLASS_IMAGES images, and classes absent from training, stay
    at 1.0: too few images to learn from, and weighting them up drags every other class onto
    the floor (one image once outweighed a 237-image class 92 to 1).
    """
    counts = Counter(label_of(a) for a in annotations)
    weights = torch.ones(len(class_list), dtype=torch.float32)
    usable = [c for c in class_list if counts.get(c, 0) >= MIN_CLASS_IMAGES]
    if not usable:
        return weights
    total = sum(counts[c] for c in usable)
    raw = torch.tensor([(total / counts[c]) ** 0.5 for c in usable], dtype=torch.float32)
    raw = torch.clamp(raw / raw.mean(), min=MIN_CLASS_WEIGHT, max=MAX_CLASS_WEIGHT)
    for c, w in zip(usable, raw):
        weights[class_list.index(c)] = w
    return weights
