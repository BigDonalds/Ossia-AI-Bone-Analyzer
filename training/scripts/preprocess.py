"""Letterbox raw photos into the training images the annotations point at.

Every image_path in data/annotations/*.json is matched to a raw photo anywhere under
data/raw/ by file name without extension (so raw .jpg files become .png outputs),
resized to config.IMG_SIZE and written to data/images/<image_path>. Images that already
exist are left alone, so rerunning only processes new annotations.

Usage: python scripts/preprocess.py
"""
import json
import sys
from pathlib import Path

import cv2

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer.config import DATA_DIR, IMAGES_DIR, IMG_SIZE, RAW_DIR
from bone_analyzer.console import Colors, print_colored, print_error, print_header, print_ok, print_separator, print_warn
from bone_analyzer.data.images import decode_image, letterbox_resize

SUPPORTED_FORMATS = {'.jpg', '.jpeg', '.png', '.webp', '.avif', '.heic', '.heif', '.bmp', '.tiff', '.tif'}


def index_raw_images(raw_dir):
    """{file stem: path} for every supported image under raw_dir. The first of two
    same-named files wins."""
    raw_files = {}
    for f in sorted(raw_dir.rglob('*')):
        if f.is_file() and f.suffix.lower() in SUPPORTED_FORMATS:
            if f.stem in raw_files:
                print_warn(f"Duplicate raw image name {f.stem}: using {raw_files[f.stem]}, ignoring {f}")
                continue
            raw_files[f.stem] = f
    return raw_files


def main():
    print_separator()
    print_header("IMAGE PREPROCESSOR — Letterbox Resize")
    print_separator()

    if not RAW_DIR.exists():
        print_error(f"Raw images directory not found: {RAW_DIR}")
        print_warn("Create it and place your raw bone images inside.")
        sys.exit(1)

    raw_files = index_raw_images(RAW_DIR)
    if not raw_files:
        print_warn(f"No supported images found in {RAW_DIR}")
        print(f"Supported formats: {', '.join(SUPPORTED_FORMATS)}")
        sys.exit(0)
    print_ok(f"Found {len(raw_files)} raw image(s) in {RAW_DIR}")

    json_files = sorted((DATA_DIR / 'annotations').glob('*.json'))
    if not json_files:
        print_warn(f"No annotation JSONs found in {DATA_DIR / 'annotations'}")
        sys.exit(0)

    print(f"Found {len(json_files)} annotation file(s): {[j.name for j in json_files]}")
    print(f"Target size: {IMG_SIZE}x{IMG_SIZE} (letterboxed, aspect ratio preserved)")
    print("-" * 60)

    total_annotations = 0
    total_processed = 0
    total_skipped_exist = 0
    total_skipped_no_raw = 0
    total_skipped_no_path = 0
    total_errors = 0

    for json_path in json_files:
        print(f"\n[{json_path.name}]")
        if json_path.stat().st_size == 0:
            print_warn("  Skipped — file is empty (0 bytes). Remove or populate it.")
            continue

        with open(json_path, encoding='utf-8') as f:
            annotations = json.load(f)

        total_annotations += len(annotations)
        p = s_exist = s_no_raw = s_no_path = err = 0

        for ann in annotations:
            image_path = ann.get('image_path', '')
            if not image_path:
                s_no_path += 1
                total_skipped_no_path += 1
                continue

            img_rel = Path(image_path)
            filename = img_rel.name
            if img_rel.stem not in raw_files:
                s_no_raw += 1
                total_skipped_no_raw += 1
                continue

            dest_path = IMAGES_DIR / image_path
            if dest_path.exists():
                s_exist += 1
                total_skipped_exist += 1
                continue

            try:
                raw_img = decode_image(raw_files[img_rel.stem].read_bytes())
                if raw_img is None:
                    print_colored(f"  Cannot read {filename}", Colors.YELLOW)
                    err += 1
                    total_errors += 1
                    continue

                processed_img = letterbox_resize(raw_img, IMG_SIZE)
                dest_path.parent.mkdir(parents=True, exist_ok=True)
                cv2.imwrite(str(dest_path), processed_img, [cv2.IMWRITE_PNG_COMPRESSION, 3])

                h, w = raw_img.shape[:2]
                print(f"  OK: {filename:30s} ({w}x{h}) -> {image_path}")
                p += 1
                total_processed += 1
            except Exception as e:
                print_colored(f"  ERR: {filename} - {e}", Colors.RED)
                err += 1
                total_errors += 1

        print(f"  [{json_path.name}] {p} processed, {s_exist} exist, {s_no_raw} no raw, {s_no_path} no path, {err} errors")

    print("-" * 60)
    summary = (f"SUMMARY: {total_processed} processed, {total_skipped_exist} already exist, "
               f"{total_skipped_no_raw} no raw file, {total_skipped_no_path} no image_path, {total_errors} errors")
    (print_ok if total_errors == 0 else print_warn)(summary)
    print(f"Total annotation objects: {total_annotations}")


if __name__ == "__main__":
    main()
