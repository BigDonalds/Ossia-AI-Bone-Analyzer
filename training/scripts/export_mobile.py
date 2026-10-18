"""Export a checkpoint for the Ossia app's on-device engine.

Usage:
    python scripts/export_mobile.py checkpoints/bone_analyzer.pt
    python scripts/export_mobile.py checkpoints/bone_analyzer.pt --check 0     (skip the check)

Writes into the app, ../app (or --app), under assets/model/:
  ossia.onnx              the network. Input: one letterboxed IMG_SIZE x IMG_SIZE RGB photo,
                          0-255, channels last. Outputs: calibrated probabilities for every
                          head (softmax, or sigmoid for bone_detection and damage), so the app
                          does no maths on the network's side of the report.
  ossia_model.json        label lists, the family rule and length-check settings: everything
                          inference/analyzer.py and inference/length_check.py read from config
  length_reference.json   copy of inference/length_reference.json

Large weights are stored as float16 and widened back to float32 when the app loads the model
(ONNX Runtime folds the casts away), which halves the file with no float16 arithmetic.

It also writes the app's test cases (test/fixtures/): test photos' probabilities together with
the report the server gives for them, which the app's own report code must reproduce, and
small images with the letterbox data/images.py makes of them.

Then it runs val and test images through both PyTorch and the exported file and checks that
every head gives the same answer.
"""
import argparse
import hashlib
import json
import shutil
import sys
import time
from datetime import date
from pathlib import Path

import cv2
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'src'))

from bone_analyzer import config
from bone_analyzer import server as ossia_server
from bone_analyzer.config import IMAGES_DIR, IMG_SIZE, PROJECT_DIR, annotation_file
from bone_analyzer.console import print_ok, print_warn
from bone_analyzer.data.images import decode_image, letterbox_resize
from bone_analyzer.data.transforms import IMAGENET_MEAN, IMAGENET_STD
from bone_analyzer.inference import length_check
from bone_analyzer.inference.analyzer import calibrated
from bone_analyzer.model import load_bone_cnn
from bone_analyzer.taxonomy import class_label

APP_DIR = PROJECT_DIR.parent / 'app'
MODEL_FILE = 'ossia.onnx'
SPEC_FILE = 'ossia_model.json'
# ONNX Runtime 1.23 (the version flutter_onnxruntime bundles) reads opset 17 / IR 8 models
OPSET = 17
IR_VERSION = 8
# Initializers at least this big are stored as float16; small ones (biases, layer-norm and
# layer-scale weights) stay float32
FP16_MIN_ELEMENTS = 4096
# The float16 weights move probabilities by about 0.001, which can only swap two answers that
# PyTorch itself rated within this much of each other: a coin flip either way, not a change
TIE = 0.005

SOFTMAX_HEADS = ('species', 'bone_type', 'bone_part', 'completeness', 'animal_class', 'animal_family',
                 'age_group', 'sex')
SIGMOID_HEADS = ('bone_detection', 'damage')
OUTPUTS = ('bone_detection', 'species', 'bone_type', 'bone_part', 'completeness', 'damage', 'animal_class',
           'animal_family', 'age_group', 'sex')
LABELS = {
    'species': config.SPECIES_CLASSES, 'bone_type': config.BONE_TYPES, 'bone_part': config.PART_LABELS,
    'completeness': config.COMPLETENESS_LABELS, 'damage': config.DAMAGE_LABELS,
    'animal_class': config.ANIMAL_CLASSES, 'animal_family': config.MAMMAL_FAMILIES,
    'age_group': config.AGE_LABELS, 'sex': config.SEX_LABELS,
}


class MobileBoneCNN(nn.Module):
    """The trained network plus what the analyzer does around it: normalisation on the way in,
    calibration and softmax/sigmoid on the way out."""

    def __init__(self, model):
        super().__init__()
        self.model = model
        self.register_buffer('mean', torch.tensor(IMAGENET_MEAN).view(1, 3, 1, 1) * 255)
        self.register_buffer('std', torch.tensor(IMAGENET_STD).view(1, 3, 1, 1) * 255)

    def forward(self, image):
        x = (image.permute(0, 3, 1, 2) - self.mean) / self.std
        outputs = calibrated(self.model(x), self.model.temperatures)
        probs = {k: torch.sigmoid(outputs[k]) if k in SIGMOID_HEADS else F.softmax(outputs[k], dim=-1)
                 for k in OUTPUTS}
        return tuple(probs[k] for k in OUTPUTS)


def export(model, path):
    wrapper = MobileBoneCNN(model).eval()
    example = torch.zeros(1, IMG_SIZE, IMG_SIZE, 3)
    torch.onnx.export(wrapper, (example,), str(path), input_names=['image'], output_names=list(OUTPUTS),
                      opset_version=OPSET, dynamo=False)


def store_weights_as_fp16(path):
    """Rewrite big float32 initializers as float16 followed by a Cast back to float32."""
    import onnx
    from onnx import TensorProto, helper, numpy_helper

    m = onnx.load(str(path))
    graph = m.graph
    casts, kept = [], []
    for init in graph.initializer:
        if init.data_type == TensorProto.FLOAT and np.prod(init.dims) >= FP16_MIN_ELEMENTS:
            half = numpy_helper.from_array(numpy_helper.to_array(init).astype(np.float16), init.name + '__fp16')
            kept.append(half)
            casts.append(helper.make_node('Cast', [half.name], [init.name], to=TensorProto.FLOAT,
                                          name=init.name + '__widen'))
        else:
            kept.append(init)
    del graph.initializer[:]
    graph.initializer.extend(kept)
    nodes = list(graph.node)
    del graph.node[:]
    graph.node.extend(casts + nodes)
    m.ir_version = IR_VERSION
    onnx.checker.check_model(m)
    onnx.save(m, str(path))
    return len(casts)


def sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def write_spec(path, checkpoint_path, checkpoint, model, onnx_path):
    spec = {
        'about': 'What the Ossia app needs to run the exported model and build the same report as '
                 'inference/analyzer.py. Written by scripts/export_mobile.py; do not edit by hand.',
        'model_file': MODEL_FILE,
        'model_sha256': sha256(onnx_path),
        'model_bytes': onnx_path.stat().st_size,
        'checkpoint': Path(checkpoint_path).name,
        'epoch': checkpoint.get('epoch', 0) + 1,
        'exported': date.today().isoformat(),
        'img_size': IMG_SIZE,
        'input': {'name': 'image', 'shape': [1, IMG_SIZE, IMG_SIZE, 3],
                  'layout': 'RGB, 0-255, channels last, letterboxed onto black like bone_analyzer.data.images.letterbox_resize'},
        'outputs': list(OUTPUTS),
        'calibrated': bool(model.temperatures),
        'labels': LABELS,
        'family_bone_types': list(config.FAMILY_BONE_TYPES),
        'use_length_rerank': config.USE_LENGTH_RERANK,
        'length_check': {
            'tolerance_above': length_check.TOLERANCE_ABOVE, 'floor_above': length_check.FLOOR_ABOVE,
            'tolerance_below': length_check.TOLERANCE_BELOW, 'floor_below': length_check.FLOOR_BELOW,
            'slack_cm': length_check.SLACK_CM, 'slack_fraction': length_check.SLACK_FRACTION,
            'confidence_pull': length_check.CONFIDENCE_PULL, 'min_checkable_mass': length_check.MIN_CHECKABLE_MASS,
            'candidates_reported': length_check.CANDIDATES_REPORTED,
            'unnamed_taxa': list(length_check.UNNAMED_TAXA), 'shown_as': length_check.SHOWN_AS,
            'part_shown_as': length_check.PART_SHOWN_AS,
        },
    }
    assert length_check.ANIMAL_TAXA == config.MAMMAL_FAMILIES + [c for c in config.ANIMAL_CLASSES if c != 'mammal']
    path.write_text(json.dumps(spec, indent=1), encoding='utf-8')


def check(model, onnx_path, limit):
    """Same answer from PyTorch and the exported file on val and test images, for every head.
    Answers PyTorch itself rated as a tie (top two within TIE) are counted apart."""
    import onnxruntime as ort

    session = ort.InferenceSession(str(onnx_path), providers=['CPUExecutionProvider'])
    wrapper = MobileBoneCNN(model).eval()
    paths = sorted(p for split in ('val', 'test') for p in (IMAGES_DIR / split).rglob('*.png'))
    if limit and len(paths) > limit:
        paths = paths[::len(paths) // limit + 1]
    print(f'Checking {len(paths)} val/test images (PyTorch vs {onnx_path.name}) ...')
    changed = {k: 0 for k in OUTPUTS}
    ties = {k: 0 for k in OUTPUTS}
    worst = {k: 0.0 for k in OUTPUTS}
    started = time.time()
    for i in range(0, len(paths), 16):
        batch = []
        for p in paths[i:i + 16]:
            image = cv2.cvtColor(cv2.imread(str(p)), cv2.COLOR_BGR2RGB)
            batch.append(letterbox_resize(image, IMG_SIZE).astype(np.float32))
        with torch.no_grad():
            expected = wrapper(torch.from_numpy(np.stack(batch)))
        for j, image in enumerate(batch):
            got = session.run(None, {'image': image[None]})
            for k, e, g in zip(OUTPUTS, expected, got):
                e, g = e[j].numpy(), g[0]
                worst[k] = max(worst[k], float(np.abs(e - g).max()))
                if k in SIGMOID_HEADS:
                    flipped = (e > 0.5) != (g > 0.5)
                    margin = 2 * float(np.abs(e - 0.5)[flipped].max()) if flipped.any() else None
                else:
                    top2 = np.sort(e)[-2:]
                    margin = float(top2[1] - top2[0]) if e.argmax() != g.argmax() else None
                if margin is not None:
                    (ties if margin < TIE else changed)[k] += 1
    print(f'  {time.time() - started:.0f} s')
    ok = True
    for k in OUTPUTS:
        flag = 'ok' if changed[k] == 0 and worst[k] < 0.01 else 'DIFFERS'
        ok &= flag == 'ok'
        tie = f' (+{ties[k]} tie{"s" * (ties[k] > 1)} decided the other way)' if ties[k] else ''
        print(f'  [{flag}] {k:<15} answer changed on {changed[k]}/{len(paths)}{tie}, '
              f'largest probability gap {worst[k]:.5f}')
    return ok


class ReplayModel(nn.Module):
    """Stands in for the network inside the analyzer, handing back logits recorded earlier, so
    many lengths can be tried on a photo without running the network again."""

    def __init__(self, temperatures):
        super().__init__()
        self.temperatures = temperatures
        self.queue = []

    def forward(self, x):
        return self.queue.pop(0)


def probabilities(logits, temperatures):
    """What the exported model outputs for these logits, computed the way the analyzer does."""
    cal = calibrated(logits, temperatures)
    return {k: [torch.sigmoid(cal[k][0]).item()] if k == 'bone_detection'
            else torch.sigmoid(cal[k][0]).tolist() if k == 'damage'
            else F.softmax(cal[k][0], dim=0).tolist()
            for k in OUTPUTS}


def reason_kind(reason):
    """Which branch of length_check wrote this explanation."""
    kinds = [('No length was entered', 'no length'), ('No bone was found', 'no bone'),
             ('This looks like', 'not a whole bone'), ("We don't have usual lengths", 'no ranges'),
             ("We don't have a usual length", 'unchecked answer'), ("doesn't fit", 'fits nothing'),
             ('is a normal length', 'inside'), ('still points to it. It could', 'short, kept'),
             ('still points to it. Worth', 'long, kept')]
    for text, kind in kinds:
        if text in reason:
            return kind
    if 'the length changed the answer' in reason:
        why = next(w for t, w in (('is too long', 'long'), ('is too short', 'short'), ('cm fits', 'inside'),
                                  ("can't be checked", 'unchecked')) if t in reason)
        return f"moved ({why}, {'fits' if ', and it fits' in reason else 'unchecked'})"
    raise ValueError(f'Unknown length-check reason: {reason}')


def write_report_cases(checkpoint_path, path):
    """Test photos' probabilities and the report the server sends for them: single photos with
    and without a length (one or two per branch of the length check), and multi-angle sets."""
    with open(annotation_file('test'), encoding='utf-8') as f:
        ann = json.load(f)
    with open(annotation_file('test', no_bone=True), encoding='utf-8') as f:
        no_bone = [a['image_path'] for a in json.load(f)]

    def pick(cond, n):
        found = [a['image_path'] for a in ann if cond(a)]
        return found[::max(1, len(found) // n)][:n]

    def part(a):
        return a['phase4_bone_part']['part']

    def bone(a):
        return a['phase3_bone_type'].get('bone_type') or ''

    def human(a):
        return a['phase2_species'].get('species') == 'human'

    limbs = ('femur', 'humerus', 'tibia', 'radius', 'ulna')
    whole = (pick(lambda a: human(a) and part(a) == 'complete' and bone(a) in limbs + ('cranium',), 10)
             + pick(lambda a: not human(a) and part(a) == 'complete' and bone(a) in limbs + ('cranium', 'mandible'), 10))
    skulls = pick(lambda a: human(a) and bone(a) in ('skull', 'cranium'), 4)
    others = (pick(lambda a: part(a) in ('fragment', 'shaft'), 4)
              + pick(lambda a: 'vertebrae' in bone(a) or 'rib' in bone(a), 4)
              + pick(lambda a: class_label(a) in ('bird', 'reptile'), 4)
              + skulls + no_bone[::max(1, len(no_bone) // 4)][:4])
    groups = {}
    for a in ann:
        gid = (a.get('phase9_multi_image') or {}).get('group_id')
        if gid:
            groups.setdefault(gid, []).append(a['image_path'])
    real_sets = [g[:4] for g in groups.values() if len(g) >= 2][:4]
    pool = list(dict.fromkeys(whole + others + [p for g in real_sets for p in g]))
    # Every complete bone is tried with many lengths, to find each branch of the length check
    search = list(dict.fromkeys(whole + pick(lambda a: part(a) == 'complete', 1000)))

    service = ossia_server.ModelService(Path(checkpoint_path).resolve())
    analyzer = service.analyzer
    temperatures = analyzer.model.temperatures
    logits = {}
    with torch.no_grad():
        for rel in dict.fromkeys(pool + search):
            image = cv2.cvtColor(decode_image((IMAGES_DIR / rel).read_bytes()), cv2.COLOR_BGR2RGB)
            logits[rel] = analyzer.model(analyzer.preprocess_for_model(image))
    replay = ReplayModel(temperatures)
    analyzer.model = replay

    def case(name, rels, length):
        replay.queue = [logits[r] for r in rels]
        report = service.analyze([str(IMAGES_DIR / r) for r in rels], length)
        return {'name': name, 'photos': [probabilities(logits[r], temperatures) for r in rels],
                'names': [Path(r).name for r in rels], 'length_cm': length, 'expected': report}

    cases = [case(f'{Path(r).stem}, no length', [r], None) for r in pool]
    per_kind = {}
    since_new = 0
    for r in others[:4] + search:
        kinds_before = len(per_kind)
        for length in [x / 2 for x in range(5, 241, 3)]:
            c = case(f'{Path(r).stem}, {length:g} cm', [r], length)
            kind = reason_kind(c['expected']['length_check']['reason'])
            if len(per_kind.setdefault(kind, [])) < 2:
                per_kind[kind].append(c)
        # Not every branch is reachable with every model: stop once a long run of photos finds nothing new
        since_new = 0 if len(per_kind) > kinds_before else since_new + 1
        if since_new >= 60 and all(len(v) == 2 for v in per_kind.values()):
            break
    for kind, found in sorted(per_kind.items()):
        cases += found
    print(f'  length-check branches covered: {", ".join(f"{k} x{len(v)}" for k, v in sorted(per_kind.items()))}')

    labels = {a['image_path']: a for a in ann}

    def first(cond):
        return next(r for r in pool if r in labels and cond(labels[r]))

    sets = [(f'real set {i + 1}', g, length) for i, g in enumerate(real_sets) for length in (None, 30)]
    sets += [
        ('human and animal limb bone', [first(lambda a: human(a) and bone(a) in limbs),
                                        first(lambda a: not human(a) and bone(a) in limbs)], 42),
        ('bone and no bone', [whole[0], others[-1]], 20),
        ('no bone twice', others[-2:], None),
        ('human skulls', skulls[:3], None),
        ('eight photos', pool[:8], 25),
    ]
    cases += [case(name, rels, length) for name, rels, length in sets]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({'about': 'Written by scripts/export_mobile.py from ' + Path(checkpoint_path).name
                                         + '; regenerate it rather than editing it.', 'cases': cases}),
                    encoding='utf-8')
    return len(cases)


def write_prep_cases(folder):
    """Small images and the 64 px letterbox letterbox_resize makes of them: a fractional
    shrink, a whole-number shrink, an enlargement, grey, RGBA, and a JPEG whose EXIF says to
    turn it."""
    from PIL import Image

    rng = np.random.default_rng(7)

    def pattern(w, h):
        y, x = np.mgrid[0:h, 0:w]
        base = np.stack([x * 255 / (w - 1), y * 255 / (h - 1), (x + y) % 32 * 8], -1)
        return np.clip(base * 0.8 + rng.integers(0, 50, (h, w, 3)), 0, 255).astype(np.uint8)

    folder.mkdir(parents=True, exist_ok=True)
    images = {
        'shrink_fraction.png': Image.fromarray(pattern(257, 173)),
        'shrink_whole.png': Image.fromarray(pattern(256, 128)),
        'enlarge.png': Image.fromarray(pattern(40, 25)),
        'grey.png': Image.fromarray(pattern(90, 150)[..., 0]),
        'rgba.png': Image.fromarray(np.dstack([pattern(120, 90), rng.integers(0, 256, (90, 120), dtype=np.uint8)])),
        'rotated.jpg': Image.fromarray(pattern(120, 80)),
    }
    for name, im in images.items():
        src = folder / name
        if src.suffix == '.jpg':
            exif = Image.Exif()
            exif[0x0112] = 6  # stored sideways: turn 90 degrees clockwise to view
            im.save(src, quality=95, exif=exif)
        else:
            im.save(src)
        decoded = decode_image(src.read_bytes())
        if src.suffix == '.jpg':
            assert decoded.shape[:2] == (120, 80), 'OpenCV did not apply the EXIF orientation'
        cv2.imwrite(str(folder / f'{src.stem}.expected.png'), letterbox_resize(decoded, 64))
    return len(images)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('checkpoint')
    parser.add_argument('--app', type=Path, default=APP_DIR, help='the Flutter app folder')
    parser.add_argument('--check', type=int, default=600, help='val/test images to compare (0 = skip, -1 = all)')
    args = parser.parse_args()

    model, checkpoint = load_bone_cnn(args.checkpoint, 'cpu')
    if not model.temperatures:
        print_warn('This checkpoint has no calibration; run python scripts/calibrate.py <checkpoint> first '
                   'so the app shows honest confidence.')
    out = args.app / 'assets' / 'model'
    out.mkdir(parents=True, exist_ok=True)
    onnx_path = out / MODEL_FILE
    tmp = onnx_path.with_suffix('.tmp.onnx')
    export(model, tmp)
    n = store_weights_as_fp16(tmp)
    tmp.replace(onnx_path)
    print_ok(f'{onnx_path} ({onnx_path.stat().st_size / 1e6:.1f} MB, {n} weight tensors stored as float16)')

    write_spec(out / SPEC_FILE, args.checkpoint, checkpoint, model, onnx_path)
    shutil.copyfile(length_check.REFERENCE_FILE, out / 'length_reference.json')
    print_ok(f'{out / SPEC_FILE} and length_reference.json')

    print("Writing the app's test cases ...")
    fixtures = args.app / 'test' / 'fixtures'
    n_reports = write_report_cases(args.checkpoint, fixtures / 'on_device_reports.json')
    n_images = write_prep_cases(fixtures / 'prep')
    print_ok(f'{fixtures}: {n_reports} report cases, {n_images} letterbox cases')

    if args.check:
        if not check(model, onnx_path, None if args.check < 0 else args.check):
            sys.exit('The exported model does not match PyTorch; do not ship it.')
        print_ok('The exported model gives the same answers as PyTorch.')


if __name__ == '__main__':
    main()
