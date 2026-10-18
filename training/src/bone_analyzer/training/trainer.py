"""The training loop: masked multi-task losses, the save score, epoch averaging and progress
saved after every epoch so an interrupted run can be continued."""
import json
import shutil
import time
from collections import Counter
from contextlib import nullcontext
from datetime import datetime
from pathlib import Path

import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim

from bone_analyzer.config import (AGE_LABELS, ANIMAL_CLASSES, AVERAGE_FROM, AVERAGE_TOLERANCE, AVERAGE_TOP_K,
                                  BACKBONE_LR_FACTOR, BONE_TYPES, CHECKPOINT_DIR, DAMAGE_LABELS, EARLY_STOP_PATIENCE,
                                  EPOCHS, FOCAL_LOSS_GAMMA, GRAD_CLIP_NORM, IMG_SIZE, LEARNING_RATE, LOSS_TASK_WEIGHTS,
                                  LR_MIN, MAMMAL_FAMILIES, MAX_DAMAGE_POS_WEIGHT, SAVE_PENALTIES, SAVE_WEIGHTS,
                                  SEX_LABELS, SPECIES_CLASSES, USE_CLASS_WEIGHTS, USE_FOCAL_LOSS)
from bone_analyzer.console import Colors, print_colored, print_header, print_ok, print_separator, print_warn
from bone_analyzer.training.heads import BALANCED_REPORT, HEADS, WEIGHTED_F1
from bone_analyzer.training.losses import FocalLoss, compute_class_weights
from bone_analyzer.training.reports import counts_json, detail_report
from bone_analyzer.training.run_log import detail

# While a run trains, everything needed to carry on after a disconnect is kept in its run
# folder and updated after every epoch: the weights with the optimiser's state, in two files
# written in turn so one is always whole even if the session dies mid-save, and the epochs
# kept for averaging. The finished model never holds the optimiser's state.
RUN_DIR_NAME = 'unfinished_run'
PROGRESS_FILES = ('progress_a.pt', 'progress_b.pt')
# One more than AVERAGE_TOP_K, so a newly kept epoch never overwrites one the last saved progress points to
CANDIDATE_FILES = AVERAGE_TOP_K + 1


def _save_or_warn(obj, path, what):
    """torch.save that warns instead of stopping the run when the write fails (a full Drive):
    these files only matter if the run is cut off."""
    try:
        torch.save(obj, str(path))
    except (OSError, RuntimeError) as e:
        print_warn(f"  Couldn't save {what} ({e}). Training carries on; if the run is cut off, "
                   f"continuing it would start from an earlier epoch.")


def load_progress(run_dir):
    """The newest saved progress in run_dir that loads whole, or None."""
    newest = None
    for name in PROGRESS_FILES:
        path = Path(run_dir) / name
        if not path.exists():
            continue
        try:
            progress = torch.load(path, map_location='cpu', weights_only=False)
        except Exception:       # cut off mid-save; the other file holds the epoch before
            continue
        if newest is None or progress['epoch'] > newest['epoch']:
            newest = progress
    return newest


def best_epoch_path(model_path):
    """Where the best single epoch is kept when the averaged model replaces it at model_path."""
    model_path = Path(model_path)
    return model_path.with_name(f'{model_path.stem}_best_epoch{model_path.suffix}')


class BoneModelTrainer:
    """Trains, validates and saves a BoneCNN.

    model_save_path gets the best-scoring epoch (later replaced by the averaged model if that
    scores as well, the epoch then moving to best_epoch_path); run_dir gets the progress files
    for continuing after a disconnect and defaults to an unfinished_run folder next to the model. annotations_path, the training
    annotations, sets the per-class loss weights; without it every class weighs the same.
    """

    def __init__(self, model, device='cuda', model_save_path=None, annotations_path=None, epochs=EPOCHS,
                 detection_counts=None, run_dir=None):
        self.model = model.to(device)
        self.device = device
        self.scaler = torch.amp.GradScaler('cuda') if device == 'cuda' else None
        self.model_save_path = Path(model_save_path) if model_save_path else CHECKPOINT_DIR / 'bone_analyzer.pt'
        self.run_dir = Path(run_dir) if run_dir else self.model_save_path.parent / RUN_DIR_NAME
        self.task_weights = LOSS_TASK_WEIGHTS
        self.epochs, self.start_epoch = epochs, 0
        self.best_score, self.best_epoch = -1.0, -1
        # (score, epoch, file slot in run_dir, weights on the CPU), best first
        self.candidates = []

        # The bone/no-bone answer, weighted so both sides count equally in its loss however many
        # of each an epoch draws (detection_counts: bone, no-bone images per epoch)
        self.detection_weight = None
        if detection_counts and all(detection_counts):
            bone, no_bone = detection_counts
            weights = [(bone + no_bone) / (2 * no_bone), (bone + no_bone) / (2 * bone)]     # by label: no-bone, bone
            self.detection_weight = torch.tensor(weights, device=device)
            print(f"  Bone/no-bone answer: {bone} bone and {no_bone} no-bone photos per epoch; each no-bone photo "
                  f"counts x{weights[0]:.2f} and each bone photo x{weights[1]:.2f}, so both sides weigh the same")

        annotations = []
        if annotations_path and Path(annotations_path).exists():
            with open(annotations_path, 'r', encoding='utf-8') as f:
                annotations = json.load(f)

        self.losses = {}
        weight_table = []
        for head, (_, _, classes, _, label_of, _) in HEADS.items():
            weight = compute_class_weights(annotations, label_of, classes).to(device) if annotations and USE_CLASS_WEIGHTS else None
            self.losses[head] = FocalLoss(FOCAL_LOSS_GAMMA, weight) if USE_FOCAL_LOSS else nn.CrossEntropyLoss(weight=weight)
            if annotations:
                counts = Counter(label_of(a) for a in annotations)
                weights = weight.tolist() if weight is not None else [1.0] * len(classes)
                weight_table.append(f'  {head}: ' + ', '.join(f'{c} {counts.get(c, 0)} x{w:.2f}' for c, w in zip(classes, weights)))
        if weight_table:
            detail('Training images and loss weight per class (name count xweight):\n' + '\n'.join(weight_table))
        # Each damage mark's positives weighted by sqrt(negatives / positives), capped
        self.damage_pos_weight = None
        if annotations and USE_CLASS_WEIGHTS:
            pos, neg = torch.zeros(len(DAMAGE_LABELS)), torch.zeros(len(DAMAGE_LABELS))
            for a in annotations:
                marks = a.get('phase6_damage') or {}
                for i, m in enumerate(DAMAGE_LABELS):
                    pos[i] += marks.get(m) is True
                    neg[i] += marks.get(m) is False
            ratio = torch.where(pos > 0, (neg / pos.clamp(min=1)).sqrt(), torch.ones_like(pos))
            self.damage_pos_weight = ratio.clamp(1.0, MAX_DAMAGE_POS_WEIGHT).to(device)
            print('  Damage positive weights: ' + ', '.join(
                f'{m} {w:.1f} ({int(p)} yes / {int(n)} no)'
                for m, w, p, n in zip(DAMAGE_LABELS, self.damage_pos_weight.tolist(), pos, neg)))

        loss_name = 'Focal' if USE_FOCAL_LOSS else 'CrossEntropy'
        weighting = f'class-weighted from {len(annotations)} annotations' if annotations and USE_CLASS_WEIGHTS else 'no class weights'
        print(f"  {loss_name} losses, {weighting}")

        backbone_params = [p for n, p in model.named_parameters() if n.startswith('backbone')]
        head_params = [p for n, p in model.named_parameters() if not n.startswith('backbone')]
        self.optimizer = optim.AdamW([
            {'params': backbone_params, 'lr': LEARNING_RATE * BACKBONE_LR_FACTOR},
            {'params': head_params, 'lr': LEARNING_RATE},
        ], weight_decay=0.01)

        # Cosine decay across the whole run. With early stopping off, training length is
        # known up front, so a smooth schedule beats reacting to a noisy validation score.
        self.scheduler = optim.lr_scheduler.CosineAnnealingLR(self.optimizer, T_max=epochs, eta_min=LR_MIN)

    def _batch(self, batch):
        return {k: v.to(self.device) for k, v in batch.items() if torch.is_tensor(v)}

    def _detection_loss(self, logits, labels):
        loss = F.binary_cross_entropy_with_logits(logits.float(), labels, reduction='none')
        if self.detection_weight is not None:
            loss = loss * self.detection_weight[labels.long()]
        return loss.mean()

    def train_epoch(self, train_loader):
        self.model.train()
        W = self.task_weights
        sums, batches = Counter(), Counter()
        # Time spent waiting for the next batch of photos. The .item() calls at the end of each
        # step wait for the GPU to finish, so this is time the GPU sat idle for want of photos.
        self.image_wait = 0.0
        asked = time.perf_counter()

        for batch in train_loader:
            self.image_wait += time.perf_counter() - asked
            b = self._batch(batch)
            autocast_ctx = torch.amp.autocast('cuda') if self.device == 'cuda' else nullcontext()
            with autocast_ctx:
                outputs = self.model(b['image'])
                losses = {'bone_detection': W['bone_detection'] * self._detection_loss(outputs['bone_detection'], b['bone_detected'])}

                # Categorical heads, each on the images labelled for it
                for head, (label_key, output_key, _, _, _, mask_of) in HEADS.items():
                    mask = mask_of(b)
                    if mask.any():
                        losses[head] = W[head] * self.losses[head](outputs[output_key][mask], b[label_key][mask])

                # Damage: each mark on the bone images where it was assessed
                known = b['damage_known'] & (b['bone_detected'] == 1).unsqueeze(1)
                if known.any():
                    per_mark = F.binary_cross_entropy_with_logits(outputs['damage'].float(), b['damage'], reduction='none',
                                                                  pos_weight=self.damage_pos_weight)
                    losses['damage'] = W['damage'] * per_mark[known].mean()

                total = sum(losses.values())

            self.optimizer.zero_grad()
            if self.scaler:
                self.scaler.scale(total).backward()
                if GRAD_CLIP_NORM:
                    # Gradients must be unscaled before they can be compared to a threshold
                    self.scaler.unscale_(self.optimizer)
                    torch.nn.utils.clip_grad_norm_(self.model.parameters(), GRAD_CLIP_NORM)
                self.scaler.step(self.optimizer)
                self.scaler.update()
            else:
                total.backward()
                if GRAD_CLIP_NORM:
                    torch.nn.utils.clip_grad_norm_(self.model.parameters(), GRAD_CLIP_NORM)
                self.optimizer.step()

            sums['total'] += total.item()
            for name, value in losses.items():
                sums[name] += value.item()
                batches[name] += 1
            asked = time.perf_counter()

        # Total per batch; each head's loss per batch that had images labelled for it, which
        # is how validate() measures it too, so the two can be compared
        result = {'total_loss': sums.pop('total') / len(train_loader)}
        result.update({f'{name}_loss': value / batches[name] for name, value in sums.items()})
        return result

    def validate(self, val_loader):
        """Accuracy and F1 per head over the images labelled for it (heads with none are left
        out), plus the false-recognition rates the save score subtracts. Heads in BALANCED_REPORT
        report accuracy as the mean of their per-class hit rates.

        The counts behind the numbers (a confusion matrix per head, damage and detection
        errors, and each head's loss on this set) are kept in self.last_counts for the
        detailed report in the training log.
        """
        self.model.eval()
        W = self.task_weights
        confusion = {head: torch.zeros(len(spec[2]), len(spec[2]), dtype=torch.long) for head, spec in HEADS.items()}
        damage = torch.zeros(len(DAMAGE_LABELS), 4, dtype=torch.long)   # per mark: found, missed, false+, correct no
        bone_correct, bone_seen = [0, 0], [0, 0]  # [no-bone, bone]
        loss_sums, loss_batches = Counter(), Counter()

        with torch.no_grad():
            for batch in val_loader:
                b = self._batch(batch)
                outputs = self.model(b['image'])

                loss_sums['bone_detection'] += W['bone_detection'] * self._detection_loss(outputs['bone_detection'], b['bone_detected']).item()
                loss_batches['bone_detection'] += 1
                bone_preds = (torch.sigmoid(outputs['bone_detection']) > 0.5).float()
                for cls in (0, 1):
                    cls_mask = b['bone_detected'] == cls
                    bone_correct[cls] += (bone_preds[cls_mask] == cls).sum().item()
                    bone_seen[cls] += cls_mask.sum().item()

                for head, (label_key, output_key, classes, _, _, mask_of) in HEADS.items():
                    mask = mask_of(b)
                    if not mask.any():
                        continue
                    logits, labels = outputs[output_key][mask], b[label_key][mask]
                    loss_sums[head] += W[head] * self.losses[head](logits, labels).item()
                    loss_batches[head] += 1
                    pairs = (labels * len(classes) + logits.argmax(1)).cpu()
                    confusion[head] += torch.bincount(pairs, minlength=len(classes) ** 2).view(len(classes), len(classes))

                known = b['damage_known'] & (b['bone_detected'] == 1).unsqueeze(1)
                if known.any():
                    per_mark = F.binary_cross_entropy_with_logits(outputs['damage'].float(), b['damage'], reduction='none',
                                                                  pos_weight=self.damage_pos_weight)
                    loss_sums['damage'] += W['damage'] * per_mark[known].mean().item()
                    loss_batches['damage'] += 1
                    said_yes, is_yes = torch.sigmoid(outputs['damage']) > 0.5, b['damage'] > 0.5
                    for i in range(len(DAMAGE_LABELS)):
                        p, t = said_yes[known[:, i], i], is_yes[known[:, i], i]
                        damage[i] += torch.stack([(p & t).sum(), (~p & t).sum(), (p & ~t).sum(), (~p & ~t).sum()]).cpu()

        self.last_counts = {'confusion': confusion, 'damage': damage, 'bone': (bone_correct, bone_seen),
                            'loss': {name: loss_sums[name] / loss_batches[name] for name in loss_sums}}
        metrics = {}
        for head, (_, _, _, metric, _, _) in HEADS.items():
            cm = confusion[head].double()
            n, found = cm.sum(1), cm.diag()
            if not n.sum():
                continue
            present = n > 0
            metrics[metric] = ((found[present] / n[present]).mean().item() if head in BALANCED_REPORT
                               else found.sum().item() / n.sum().item())
            # Per class 2TP / (2TP + FP + FN): the row (true) plus column (claimed) totals
            f1 = 2 * found / (n + cm.sum(0)).clamp(min=1)
            metrics[f'{head}_f1'] = ((f1 * n).sum() / n.sum()).item() if head in WEIGHTED_F1 else f1[present].mean().item()
        # The false recognitions the save score penalises (config.SAVE_PENALTIES)
        species_cm, class_cm = confusion['species'], confusion['animal_class']
        animal, mammal = SPECIES_CLASSES.index('non_human'), ANIMAL_CLASSES.index('mammal')
        if species_cm[animal].sum():
            metrics['animal_called_human_rate'] = (species_cm[animal].sum() - species_cm[animal, animal]).item() / species_cm[animal].sum().item()
        if class_cm[mammal].sum():
            metrics['mammal_called_bird_rate'] = (class_cm[mammal].sum() - class_cm[mammal, mammal]).item() / class_cm[mammal].sum().item()
        if damage.sum():
            metrics['damage_accuracy'] = (damage[:, 0].sum() + damage[:, 3].sum()).item() / damage.sum().item()
        # Humans and animals separately: the balanced species score can't say which side is weak
        n, found = confusion['species'].sum(1), confusion['species'].diag()
        for i, name in enumerate(SPECIES_CLASSES):
            if n[i]:
                metrics[f'{name}_found_rate'] = found[i].item() / n[i].item()
        # Bone detection: mean of per-class accuracy, so a large no-bone set can't hide missed bones
        class_accuracies = [c / t for c, t in zip(bone_correct, bone_seen) if t > 0]
        if class_accuracies:
            metrics['bone_accuracy'] = sum(class_accuracies) / len(class_accuracies)
        if bone_seen[1]:
            metrics['bone_detected_rate'] = bone_correct[1] / bone_seen[1]
        if bone_seen[0]:
            metrics['no_bone_rejected_rate'] = bone_correct[0] / bone_seen[0]
            metrics['no_bone_called_bone_rate'] = 1 - metrics['no_bone_rejected_rate']
        return metrics

    @staticmethod
    def save_score(metrics):
        """Weighted average of SAVE_WEIGHTS over the metrics this validation set could measure,
        minus SAVE_PENALTIES times each false-recognition rate."""
        present = {k: w for k, w in SAVE_WEIGHTS.items() if k in metrics}
        if not present:
            return 0.0
        gain = sum(metrics[k] * w for k, w in present.items())
        cost = sum(metrics[k] * w for k, w in SAVE_PENALTIES.items() if k in metrics)
        return (gain - cost) / sum(present.values())

    @staticmethod
    def _fmt(metrics, key):
        return f"{metrics[key]:.0%}" if key in metrics else 'n/a'

    def _checkpoint(self, epoch, metrics, **extra):
        # Weights only: the optimiser's state, which would triple the file, is kept in the run
        # folder's progress files while the run trains (see _save_progress)
        torch.save({
            'epoch': epoch,
            'model_state_dict': self.model.state_dict(),
            'val_metrics': metrics,
            'img_size': IMG_SIZE,
            # The class lists this checkpoint's heads were trained on
            'labels': {'animal_classes': ANIMAL_CLASSES, 'mammal_families': MAMMAL_FAMILIES,
                       'age_labels': AGE_LABELS, 'sex_labels': SEX_LABELS, 'bone_types': BONE_TYPES},
            **extra,
        }, str(self.model_save_path))

    def _save_progress(self, epoch, training_done, run):
        """Everything needed to carry on after a disconnect, written over the older of the two
        progress files so the newer one stays whole if the session dies mid-save."""
        _save_or_warn({
            'epoch': epoch, 'epochs': self.epochs, 'training_done': training_done,
            'saved': f'{datetime.now():%Y-%m-%d %H:%M}', 'run': run,
            'model_state_dict': self.model.state_dict(), 'optimizer': self.optimizer.state_dict(),
            'scheduler': self.scheduler.state_dict(), 'scaler': self.scaler.state_dict() if self.scaler else None,
            'best_score': self.best_score, 'best_epoch': self.best_epoch,
            'candidates': [(score, e, slot) for score, e, slot, _ in self.candidates],
        }, self.run_dir / PROGRESS_FILES[epoch % 2], 'the progress for continuing after a disconnect')

    def restore(self, progress):
        """Pick up an unfinished run where its saved progress left off (see _save_progress)."""
        self.model.load_state_dict(progress['model_state_dict'])
        self.optimizer.load_state_dict(progress['optimizer'])
        self.scheduler.load_state_dict(progress['scheduler'])
        if self.scaler and progress['scaler']:
            self.scaler.load_state_dict(progress['scaler'])
        self.best_score, self.best_epoch = progress['best_score'], progress['best_epoch']
        self.start_epoch = self.epochs if progress['training_done'] else progress['epoch'] + 1
        for score, epoch, slot in progress['candidates']:
            try:
                kept = torch.load(self.run_dir / f'kept_epoch_{slot}.pt', map_location='cpu', weights_only=False)
            except Exception:
                kept = None
            # A file cut off mid-save, or already reused for a later epoch, is left out
            if kept and kept['epoch'] == epoch:
                self.candidates.append((score, epoch, slot, kept['weights']))
            else:
                print_warn(f"  Epoch {epoch + 1}'s saved copy for averaging didn't survive; averaging goes ahead without it")

    def train(self, train_loader, val_loader, run):
        """Train from self.start_epoch to self.epochs, saving the best-scoring epoch as it goes and
        keeping a copy of the AVERAGE_TOP_K best epochs of the averaging window for
        average_best_epochs(). After every epoch, what's needed to carry on after a disconnect
        goes to run_dir, with `run` (the data and settings the run started with)."""
        window_start = int(self.epochs * AVERAGE_FROM)

        for epoch in range(self.start_epoch, self.epochs):
            started = time.time()
            lr = self.optimizer.param_groups[-1]['lr']      # heads; the backbone runs at BACKBONE_LR_FACTOR x this
            train_metrics = self.train_epoch(train_loader)
            train_seconds = time.time() - started
            m = self.validate(val_loader)
            f = lambda key: self._fmt(m, key)

            print_colored(f"Epoch {epoch+1}/{self.epochs}", Colors.BOLD + Colors.CYAN)
            print(f"  {Colors.YELLOW}Loss{Colors.END}: {train_metrics['total_loss']:.2f}")
            print(f"  {Colors.YELLOW}Time{Colors.END}: {(time.time() - started) / 60:.1f} min; waiting for photos took "
                  f"{self.image_wait / train_seconds:.0%} of the training part")
            print(f"  {Colors.BRIGHT_BLUE}Bone{Colors.END}      {f('bone_accuracy')}  |  {Colors.BRIGHT_BLUE}Species{Colors.END}   {f('species_accuracy')}  |  {Colors.BRIGHT_BLUE}Type{Colors.END}     {f('bone_type_accuracy')}")
            print(f"  {Colors.BRIGHT_BLUE}Part{Colors.END}      {f('part_accuracy')}  |  {Colors.BRIGHT_BLUE}Comp{Colors.END}      {f('completeness_accuracy')}  |  {Colors.BRIGHT_BLUE}Damage{Colors.END}   {f('damage_accuracy')}")
            print(f"  {Colors.BRIGHT_BLUE}Class{Colors.END}    {f('animal_class_accuracy')}  |  {Colors.BRIGHT_BLUE}Family{Colors.END}    {f('animal_family_accuracy')}  |  {Colors.BRIGHT_BLUE}Age{Colors.END}      {f('age_accuracy')}  |  {Colors.BRIGHT_BLUE}Sex{Colors.END} {f('sex_accuracy')}")
            if 'no_bone_rejected_rate' in m:
                print(f"  {Colors.BRIGHT_BLUE}Detect{Colors.END}   bones found {f('bone_detected_rate')}, no-bone rejected {f('no_bone_rejected_rate')}")
            if 'human_found_rate' in m:
                print(f"  {Colors.BRIGHT_BLUE}Species{Colors.END}  humans found {f('human_found_rate')}, animals found {f('non_human_found_rate')}")
            print(f"  {Colors.BRIGHT_BLUE}F1{Colors.END}       species {f('species_f1')} | type {f('bone_type_f1')} | class {f('animal_class_f1')}"
                  f" | family {f('animal_family_f1')}")
            print(f"  {Colors.BRIGHT_BLUE}Wrongly{Colors.END}  no-bone called bone {f('no_bone_called_bone_rate')}, animal called human "
                  f"{f('animal_called_human_rate')}, mammal called bird/reptile {f('mammal_called_bird_rate')}")

            score = self.save_score(m)
            self.scheduler.step()
            saved = score > self.best_score
            detail(f'\n=== Epoch {epoch + 1}/{self.epochs} | {time.time() - started:.0f}s | lr {lr:.2e} | save score {score:.2%}'
                   f'{" (new best, saved)" if saved else f" (best {self.best_score:.2%}, epoch {self.best_epoch + 1})"} ===')
            detail(detail_report(self.last_counts, train_metrics))
            detail('EPOCH_JSON ' + json.dumps({'epoch': epoch + 1, 'seconds': round(time.time() - started),
                                               'train_seconds': round(train_seconds), 'image_wait_seconds': round(self.image_wait),
                                               'lr': lr, 'score': score, 'saved': saved, 'metrics': m,
                                               'train_loss': train_metrics, **counts_json(self.last_counts)}))
            if AVERAGE_TOP_K > 1 and epoch >= window_start and (
                    len(self.candidates) < AVERAGE_TOP_K or score > self.candidates[-1][0]):
                weights = {k: v.detach().cpu().clone() for k, v in self.model.state_dict().items()}
                # A file no kept epoch uses: the last saved progress never points at it
                slot = min(set(range(CANDIDATE_FILES)) - {c[2] for c in self.candidates})
                _save_or_warn({'epoch': epoch, 'weights': weights}, self.run_dir / f'kept_epoch_{slot}.pt',
                              f"epoch {epoch + 1}'s copy for averaging")
                self.candidates = sorted(self.candidates + [(score, epoch, slot, weights)], key=lambda c: -c[0])[:AVERAGE_TOP_K]
            if saved:
                self.best_score, self.best_epoch = score, epoch
                self._checkpoint(epoch, m)
                print_ok(f"  Saved model (score: {score:.1%})")
            stop = not saved and EARLY_STOP_PATIENCE and epoch - self.best_epoch >= EARLY_STOP_PATIENCE
            self._save_progress(epoch, bool(stop) or epoch == self.epochs - 1, run)
            if stop:
                print_warn(f"  No improvement for {EARLY_STOP_PATIENCE} epochs; stopping early (best: epoch {self.best_epoch + 1})")
                break

        return self.model

    def average_best_epochs(self, val_loader):
        """Average the weights of the epochs train() kept and save the average over the best
        single epoch if it scores within AVERAGE_TOLERANCE of it; the best single epoch then
        moves to best_epoch_path so the two can be compared on the test set. With fewer than
        two epochs kept, the best single one stays. Returns what was decided.

        ConvNeXt has no batch norm, so the averaged weights are the whole model. (With a
        batch-norm backbone such as ResNet50, its statistics would have to be recomputed too.)"""
        candidates, best_score, best_epoch = self.candidates, self.best_score, self.best_epoch
        if len(candidates) < 2:
            return {'kept_average': False, 'best_single_epoch': best_epoch + 1, 'best_single_score': best_score}
        print_header(f"AVERAGING THE {len(candidates)} BEST EPOCHS "
                     f"({', '.join(str(e + 1) for _, e, _, _ in sorted(candidates, key=lambda c: c[1]))})")
        averaged = {}
        for key, value in candidates[0][3].items():
            averaged[key] = (torch.stack([c[3][key].float() for c in candidates]).mean(0).to(value.dtype)
                             if value.is_floating_point() else value)
        self.model.load_state_dict(averaged)
        m = self.validate(val_loader)
        score = self.save_score(m)
        epochs = sorted(e + 1 for _, e, _, _ in candidates)
        kept = score >= best_score - AVERAGE_TOLERANCE
        decision = {'epochs': epochs, 'score': score, 'best_single_epoch': best_epoch + 1,
                    'best_single_score': best_score, 'kept_average': kept}
        detail('AVERAGE_JSON ' + json.dumps({**decision, 'metrics': m, **counts_json(self.last_counts)}))
        if kept:
            # The file still holds the best single epoch, unless a run cut off after this point
            # already saved the average over it (the epoch was copied then)
            if 'averaged_epochs' not in torch.load(self.model_save_path, map_location='cpu'):
                shutil.copyfile(self.model_save_path, best_epoch_path(self.model_save_path))
            self._checkpoint(max(epochs) - 1, m, averaged_epochs=epochs)
            print_ok(f"  Saved the average of epochs {epochs} (score {score:.1%}; best single epoch "
                     f"{best_epoch + 1}: {best_score:.1%}, kept as {best_epoch_path(self.model_save_path).name})")
        else:
            print_warn(f"  The average scored {score:.1%}, below epoch {best_epoch + 1}'s {best_score:.1%}; kept that epoch")
        self.candidates = []
        return decision

    def evaluate(self, test_loader):
        """Print the test-set metrics and log the per-class detail. Returns the metrics."""
        print_separator()
        print_header("FINAL TEST SET EVALUATION")
        print_separator()
        m = self.validate(test_loader)
        rows = [('Bone Detection (balanced)', 'bone_accuracy'), ('  bones found', 'bone_detected_rate'),
                ('  no-bone rejected', 'no_bone_rejected_rate'), ('Species (balanced)', 'species_accuracy'),
                ('  species F1', 'species_f1'), ('  animal called human', 'animal_called_human_rate'),
                ('  humans found', 'human_found_rate'), ('  animals found', 'non_human_found_rate'),
                ('Bone Type', 'bone_type_accuracy'), ('Bone Part', 'part_accuracy'),
                ('Completeness', 'completeness_accuracy'), ('Damage', 'damage_accuracy'),
                ('  bone type F1', 'bone_type_f1'),
                ('Animal Class (balanced)', 'animal_class_accuracy'), ('  animal class F1', 'animal_class_f1'),
                ('  mammal called bird/reptile', 'mammal_called_bird_rate'),
                ('Mammal Family (balanced)', 'animal_family_accuracy'), ('  mammal family F1', 'animal_family_f1'),
                ('Age', 'age_accuracy'), ('Sex', 'sex_accuracy')]
        for label, key in rows:
            value = f"{m[key]:.2%}" if key in m else 'n/a (no labelled test images)'
            print(f"  {Colors.BRIGHT_BLUE}{label + ':':<27s}{Colors.END} {value}")
        print(f"  {Colors.BRIGHT_BLUE}{'Save score on the test set:':<27s}{Colors.END} {self.save_score(m):.2%}")
        print_separator()
        detail('\n=== TEST SET (untouched until now) ===')
        detail(detail_report(self.last_counts))
        detail('TEST_JSON ' + json.dumps({'metrics': m, **counts_json(self.last_counts)}))
        return m
