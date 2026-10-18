"""Train the bone analyzer.

Usage:
    python scripts/train.py              # asks first if an unfinished run is found
    python scripts/train.py --resume     # carry on an unfinished run without asking
    python scripts/train.py --fresh      # start a new run without asking
    python scripts/train.py --evaluate   # test-set evaluation of the saved model only

The model (bone_analyzer.pt) and an unfinished run's progress go to --checkpoint-dir, by
default config.CHECKPOINT_DIR: checkpoints/ locally, or MyDrive/bone_analyzer/checkpoints when
Google Drive is mounted in Colab. A copy of the terminal output goes to train.log in --log-dir,
by default config.LOG_DIR (logs/ beside the checkpoints folder). Progress is saved after every
epoch, so a run that is cut off continues from its last finished epoch. When the final model is
the average of the best epochs, the best single epoch is kept beside it as
bone_analyzer_best_epoch.pt and both are scored on the test set.
"""
import argparse
import hashlib
import json
import os
import platform
import shutil
import sys
from datetime import datetime
from pathlib import Path

# Plain printed lines only: no download progress bar when timm fetches the pretrained weights
os.environ.setdefault('HF_HUB_DISABLE_PROGRESS_BARS', '1')

import timm
import torch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer.config import (AVERAGE_FROM, AVERAGE_TOLERANCE, AVERAGE_TOP_K, BACKBONE_LR_FACTOR, BATCH_SIZE,
                                  CHECKPOINT_DIR, COLAB_DRIVE, DAMAGE_LABELS, DATA_DIR, DEVICE, EARLY_STOP_PATIENCE,
                                  EPOCHS, IMG_SIZE, LEARNING_RATE, LOG_DIR, LOSS_TASK_WEIGHTS, NO_BONE_RATIO, SAVE_PENALTIES,
                                  SAVE_WEIGHTS, USE_CLASS_WEIGHTS, USE_FOCAL_LOSS, annotation_file)
from bone_analyzer.console import Colors, print_colored, print_error, print_header, print_ok, print_separator, print_warn
from bone_analyzer.data.dataset import BalancedBoneSampler, create_dataloaders, create_test_loader
from bone_analyzer.model import BACKBONE, BoneCNN, load_bone_cnn
from bone_analyzer.training import run_log
from bone_analyzer.training.calibration import fit_temperatures, save_temperatures
from bone_analyzer.training.heads import HEADS
from bone_analyzer.training.reports import counts_json, robustness_report
from bone_analyzer.training.trainer import (PROGRESS_FILES, RUN_DIR_NAME, BoneModelTrainer, best_epoch_path,
                                            load_progress)

MODEL_NAME = 'bone_analyzer.pt'
LOG_NAME = 'train.log'


def run_settings(args):
    """The settings a training run is made with, as logged in CONFIG_JSON; a continued run is
    checked against the ones it started with."""
    return json.loads(json.dumps({
        'epochs': args.epochs, 'batch_size': BATCH_SIZE, 'learning_rate': LEARNING_RATE, 'backbone_lr_factor': BACKBONE_LR_FACTOR,
        'img_size': IMG_SIZE, 'no_bone_ratio': NO_BONE_RATIO, 'focal_loss': USE_FOCAL_LOSS,
        'class_weights': USE_CLASS_WEIGHTS and not args.no_class_weights, 'loss_task_weights': LOSS_TASK_WEIGHTS,
        'save_weights': SAVE_WEIGHTS, 'save_penalties': SAVE_PENALTIES, 'average_top_k': AVERAGE_TOP_K,
        'average_from': AVERAGE_FROM, 'average_tolerance': AVERAGE_TOLERANCE}))


def data_fingerprint(data_dir):
    """A short hash of the annotation files, to tell whether the training data changed."""
    digest = hashlib.sha1()
    for path in sorted((Path(data_dir) / 'annotations').glob('*.json')):
        digest.update(path.name.encode() + path.read_bytes())
    return digest.hexdigest()[:12]


def ask_about_unfinished_run(args, run_dir):
    """The saved progress to carry on from, or None for a new run. When an unfinished run is
    found, asks first, unless --resume or --fresh already said."""
    if args.fresh:
        return None
    progress = load_progress(run_dir)
    if progress is None:
        if args.resume:
            print('No unfinished run to continue; starting a new one.')
        return None
    print_header('AN UNFINISHED TRAINING RUN WAS FOUND')
    if progress['training_done']:
        print(f"  All {progress['epochs']} epochs were done, but not the finishing steps (averaging, calibration, test).")
    else:
        print(f"  {progress['epoch'] + 1} of {progress['epochs']} epochs done, last saved {progress['saved']}.")
    if progress['run']['data'] != data_fingerprint(args.data_dir):
        print_warn("  The training photos or their labels have changed since it started. Continuing would mix "
                   "the old and new; starting again is the cleaner choice.")
    started_with, now = progress['run']['settings'], run_settings(args)
    changed = sorted(k for k in started_with.keys() | now.keys() if started_with.get(k) != now.get(k))
    if changed:
        print_warn(f"  Settings changed since it started: {', '.join(changed)}. Continuing uses the new values from here on"
                   + (f", but keeps the run's own {progress['epochs']} epochs" if 'epochs' in changed else '') + '.')
    if args.resume:
        return progress
    try:
        answer = input('Continue it? [Y/n] ')
    except EOFError:        # no keyboard to answer with: carry on, which loses nothing
        answer = ''
    if answer.strip().lower().startswith('n'):
        print('Starting a new run from epoch 1; the unfinished one will be deleted.')
        return None
    return progress


def keep_previous_run(paths, run_dir):
    """Make way for a new run: the last run's files (model, best single epoch, log) are renamed
    after the time the model was saved, never overwritten, and an unfinished run's files are
    deleted. paths[0] is the model. Returns the new names."""
    shutil.rmtree(run_dir, ignore_errors=True)
    if not paths[0].exists():
        return []
    stamp = f'{datetime.fromtimestamp(paths[0].stat().st_mtime):%Y-%m-%d_%H%M}'
    kept = []
    for path in paths:
        if path.exists():
            kept.append(path.rename(path.with_name(f'{path.stem}_{stamp}{path.suffix}')).name)
    return kept


def compare_best_epoch(path, averaged_test, averaging, val_loader, test_loader):
    """The best single epoch (kept at path) on the test set beside the averaged model's test
    metrics. Its confidence is calibrated too, so either file is ready for the app."""
    model, _ = load_bone_cnn(path, DEVICE)
    save_temperatures(path, fit_temperatures(model, val_loader, DEVICE))
    trainer = BoneModelTrainer(model, DEVICE, path)
    single_test = trainer.validate(test_loader)
    run_log.detail('BEST_EPOCH_TEST_JSON ' + json.dumps({'epoch': averaging['best_single_epoch'], 'metrics': single_test,
                                                         **counts_json(trainer.last_counts)}))
    print_separator()
    print_header("THE AVERAGE VS THE BEST SINGLE EPOCH, ON THE TEST SET")
    print_separator()
    single = f"epoch {averaging['best_single_epoch']}"
    print(f"  {'':<28}{'average':>10}{single:>12}")
    rows = [('Save score (validation)', None), ('Save score (test)', None), ('Bone / no-bone', 'bone_accuracy'),
            ('Humans found', 'human_found_rate'), ('Animal called human', 'animal_called_human_rate'),
            ('Species F1', 'species_f1'), ('Bone type F1', 'bone_type_f1'),
            ('Animal class F1', 'animal_class_f1'), ('Mammal family F1', 'animal_family_f1')]
    for label, key in rows:
        if label == 'Save score (validation)':
            a, b = averaging['score'], averaging['best_single_score']
        elif key is None:
            a, b = trainer.save_score(averaged_test), trainer.save_score(single_test)
        elif key in averaged_test and key in single_test:
            a, b = averaged_test[key], single_test[key]
        else:
            continue
        print(f"  {Colors.BRIGHT_BLUE}{label:<28}{Colors.END}{a:>10.2%}{b:>12.2%}")
    print(f"  The average stays the main model; epoch {averaging['best_single_epoch']} is kept as {path.name}.")


def main():
    parser = argparse.ArgumentParser(description='Train the bone analyzer.')
    parser.add_argument('--evaluate', action='store_true',
                        help='evaluate the saved model on the test set and exit')
    parser.add_argument('--no-class-weights', action='store_true',
                        help='train without per-class loss weights')
    parser.add_argument('--epochs', type=int, default=EPOCHS,
                        help=f'epochs for a new run (default {EPOCHS}); a continued run keeps its own')
    parser.add_argument('--data-dir', type=Path, default=DATA_DIR,
                        help='folder holding annotations/ and images/ (default: data/)')
    parser.add_argument('--checkpoint-dir', type=Path, default=CHECKPOINT_DIR,
                        help='folder for the model and an unfinished run (default: config.CHECKPOINT_DIR)')
    parser.add_argument('--log-dir', type=Path, default=LOG_DIR,
                        help='folder for train.log (default: config.LOG_DIR)')
    choice = parser.add_mutually_exclusive_group()
    choice.add_argument('--resume', action='store_true',
                        help='continue an unfinished run without asking')
    choice.add_argument('--fresh', action='store_true',
                        help='start a new run without asking, deleting any unfinished one')
    args = parser.parse_args()

    args.checkpoint_dir.mkdir(parents=True, exist_ok=True)
    args.log_dir.mkdir(parents=True, exist_ok=True)
    model_path = args.checkpoint_dir / MODEL_NAME
    log_file = args.log_dir / LOG_NAME
    run_dir = args.checkpoint_dir / RUN_DIR_NAME

    progress = None if args.evaluate else ask_about_unfinished_run(args, run_dir)
    fresh = not args.evaluate and progress is None
    kept = keep_previous_run([model_path, best_epoch_path(model_path), log_file], run_dir) if fresh else []

    # A new run starts the log afresh; a continued run and --evaluate add to the end of it
    run_log.start(log_file, append=not fresh)
    if progress:
        print(f"\n{'=' * 25} CONTINUED {datetime.now():%Y-%m-%d %H:%M} {'=' * 25}")
    print(f"Logging to {log_file} ({datetime.now():%Y-%m-%d %H:%M}, {'test evaluation' if args.evaluate else 'training run'}; "
          f"per-class detail after each epoch is in the file)")
    for name in kept:
        print_ok(f"The previous run's {'log' if name.endswith('.log') else 'model'} was kept as {name}")

    try:
        _run(args, progress, model_path, run_dir)
    except KeyboardInterrupt:
        print_warn("\n\nStopped (Ctrl+C).")
        if not args.evaluate and any((run_dir / name).exists() for name in PROGRESS_FILES):
            print_ok("Progress up to the last finished epoch is saved: run python scripts/train.py again and answer Y "
                     "to carry on from there.")
        sys.exit(0)


def _run(args, progress, model_path, run_dir):
    data_dir = args.data_dir
    print_separator()
    print_header("BONE ANALYZER — Training")
    print_separator()
    print_colored(f"Device: {DEVICE}", Colors.CYAN)
    run_log.detail(f"python {platform.python_version()} | torch {torch.__version__} | timm {timm.__version__} | "
                   + (f"GPU {torch.cuda.get_device_name(0)}" if torch.cuda.is_available() else 'no GPU'))
    settings = run_settings(args)
    run_log.detail('CONFIG_JSON ' + json.dumps(settings))
    # Class order of every confusion matrix in the EPOCH_JSON / TEST_JSON lines (rows true, columns predicted)
    run_log.detail('LABELS_JSON ' + json.dumps({**{head: spec[2] for head, spec in HEADS.items()}, 'damage': DAMAGE_LABELS}))

    if args.evaluate:
        if not model_path.exists():
            print_error(f"No trained model found at {model_path}")
            print_warn("Run training first: python scripts/train.py")
            sys.exit(1)
        print_colored(f"Loading trained model from {model_path}...", Colors.CYAN)
        model, _ = load_bone_cnn(model_path, DEVICE)
        test_loader = create_test_loader(data_dir, BATCH_SIZE)
        print(f"  {Colors.BRIGHT_BLUE}Test samples:{Colors.END} {len(test_loader.dataset)}")
        BoneModelTrainer(model, DEVICE, model_path).evaluate(test_loader)
        robustness_report(model, DEVICE, data_dir)
        return

    print("\nLoading data...")
    train_loader, val_loader = create_dataloaders(data_dir, BATCH_SIZE)
    print(f"  {Colors.BRIGHT_BLUE}Training samples:{Colors.END}   {len(train_loader.dataset)} ({len(train_loader.sampler)} used per epoch)")
    print(f"  {Colors.BRIGHT_BLUE}Validation samples:{Colors.END} {len(val_loader.dataset)}")
    sampler = train_loader.sampler
    detection_counts = ((sampler.expected_bone, sampler.num_no_bone_per_epoch)
                        if isinstance(sampler, BalancedBoneSampler) else None)
    epochs = progress['epochs'] if progress else args.epochs

    print(f"\nCreating model: ConvNeXt-Tiny, ImageNet-22k pretrained, fine-tuned on ImageNet-1k at 384 ({BACKBONE})...")
    model = BoneCNN()
    total_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    print_colored(f"Total trainable parameters: {total_params:,}", Colors.MAGENTA)
    stopping = (f'early stop after {EARLY_STOP_PATIENCE} epochs without improvement'
                if EARLY_STOP_PATIENCE else f'no early stop, all {epochs} epochs')
    print(f"  Save criterion: weighted average of {len(SAVE_WEIGHTS)} metrics (F1 for species, type, class and "
          f"family) minus penalties for false recognitions; {stopping}")
    if AVERAGE_TOP_K > 1:
        print(f"  Final model: average of the {AVERAGE_TOP_K} best epochs from epoch {int(epochs * AVERAGE_FROM) + 1} on, "
              f"if it scores as well as the best single epoch")
    print("  Loss task weights:")
    for name, w in LOSS_TASK_WEIGHTS.items():
        print(f"    {name:20s}: {w:.1f}")

    annotations_path = None if args.no_class_weights else annotation_file('train', data_dir=data_dir)
    trainer = BoneModelTrainer(model, DEVICE, model_path, annotations_path=annotations_path, epochs=epochs,
                               detection_counts=detection_counts, run_dir=run_dir)
    if progress:
        trainer.restore(progress)
        run = progress['run']
        print_ok(f"Continuing from epoch {trainer.start_epoch + 1} of {epochs}" if trainer.start_epoch < epochs
                 else "All epochs were done; doing the finishing steps")
    else:
        run = {'data': data_fingerprint(data_dir), 'settings': settings}
    run_dir.mkdir(parents=True, exist_ok=True)
    trainer.train(train_loader, val_loader, run)

    print_separator()
    print_header("TRAINING COMPLETE - FINISHING STEPS NEXT, DON'T STOP THE RUN")
    print_separator()
    print_warn("  Averaging the best epochs, calibrating confidence, the test set and the shortcut check "
               "take several more minutes. Wait for ALL DONE (if the run is cut off, running scripts/train.py "
               "again finishes them).")
    # Done once: a run continued after this point goes straight on to calibration. The file
    # holds what was decided.
    averaging_done = run_dir / 'averaging_done'
    if averaging_done.exists():
        print("  The best epochs were already averaged before the run was cut off.")
        averaging = json.loads(averaging_done.read_text(encoding='utf-8'))
    else:
        averaging = trainer.average_best_epochs(val_loader)
        averaging_done.write_text(json.dumps(averaging), encoding='utf-8')
    print_ok(f"Model saved to: {model_path}")

    # Evaluate the best saved checkpoint, not the last epoch, after calibrating its confidence
    # on the validation set (stored in the checkpoint; the analyzer and server apply it)
    best_model, _ = load_bone_cnn(model_path, DEVICE)
    temperatures = fit_temperatures(best_model, val_loader, DEVICE)
    save_temperatures(model_path, temperatures)
    print_ok(f"Confidence calibration fitted on the validation set and saved in the checkpoint: {temperatures}")
    run_log.detail('CALIBRATION_JSON ' + json.dumps(temperatures))
    test_loader = create_test_loader(data_dir, BATCH_SIZE)
    final = BoneModelTrainer(best_model, DEVICE, model_path)
    test_metrics = final.evaluate(test_loader)
    robustness_report(best_model, DEVICE, data_dir)
    if averaging['kept_average'] and best_epoch_path(model_path).exists():
        compare_best_epoch(best_epoch_path(model_path), test_metrics, averaging, val_loader, test_loader)
    shutil.rmtree(run_dir, ignore_errors=True)
    print(f"  The files kept for continuing after a disconnect ({run_dir.name}, about 1.4 GB) are deleted."
          + (" Google Drive keeps deleted files in its Bin, still taking up space, until the Bin is emptied "
             "or 30 days pass." if COLAB_DRIVE in run_dir.parents else ''))
    print_separator()
    val_score = averaging['score'] if averaging['kept_average'] else averaging['best_single_score']
    print_header(f"ALL DONE - {model_path.name} is ready: validation score {val_score:.2%}, "
                 f"test score {final.save_score(test_metrics):.2%}")
    print_separator()


if __name__ == "__main__":
    main()
