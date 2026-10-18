"""Fit confidence calibration for an already-trained checkpoint and store it inside it.

Usage: python scripts/calibrate.py checkpoints/bone_analyzer.pt

Runs the model over the validation set only: nothing is trained and the weights are not
touched. Training runs do this themselves at the end; this is for older checkpoints, or to
refit after the validation set changes.
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer.config import BATCH_SIZE, DATA_DIR, DEVICE
from bone_analyzer.console import print_ok
from bone_analyzer.data.dataset import load_split, make_loader
from bone_analyzer.data.transforms import get_val_transform
from bone_analyzer.model import load_bone_cnn
from bone_analyzer.training.calibration import fit_temperatures, save_temperatures


def main():
    parser = argparse.ArgumentParser(description='Fit confidence calibration for a trained checkpoint.')
    parser.add_argument('model', type=Path, help='checkpoint to calibrate, e.g. checkpoints/bone_analyzer.pt')
    model_path = parser.parse_args().model
    model, checkpoint = load_bone_cnn(model_path, DEVICE)
    if checkpoint.get('temperatures'):
        print(f"Replacing the calibration already stored: {checkpoint['temperatures']}")
    val_dataset, _, _ = load_split(DATA_DIR, 'val', get_val_transform())
    temperatures = fit_temperatures(model, make_loader(val_dataset, BATCH_SIZE, shuffle=False), DEVICE)
    save_temperatures(model_path, temperatures)
    print_ok(f'Saved in {model_path.name}: {temperatures}')


if __name__ == '__main__':
    main()
