# bone_analyzer

The model behind Ossia: a multi-task classifier that reads a bone photo and
answers the nine stages listed in the [top-level README](../README.md). This
folder trains it, calibrates it, serves it to the app over HTTP and exports it
for the on-device engine.

## Setup

Python 3.10 or newer. Install PyTorch first, following
[pytorch.org](https://pytorch.org/get-started/locally/) for your GPU, then:

```bash
pip install -e .
```

Optional extras:

- `pip install -e ".[export]"` adds `onnx` and `onnxruntime`, needed by
  `scripts/export_mobile.py`.
- `pip install -e ".[heif]"` adds `pillow-heif`, so the server accepts HEIC
  photos straight from an iPhone.

`pip install -r requirements.txt` works too; the scripts find the package in
`src/` without installing it.

## Data

Photos and annotations are not in the repository. Everything lives under
`data/`:

```
data/
  taxonomy_table.json        scientific and common names -> class, order, family (in the repo)
  raw/                       original photos, any folder structure
  images/                    letterboxed training images, written by preprocess.py
    train/  val/  test/
  annotations/
    train.json   val.json   test.json                         photos with a bone
    train_no_bone.json   val_no_bone.json   test_no_bone.json  photos without one
```

Each annotation file is a JSON list with one record per photo:

```json
{
  "image_path": "train/non_human/deer/femur/femur_0412.png",
  "phase1_bone_detection": { "bone_present": true },
  "phase2_species": { "species": "non_human" },
  "phase3_bone_type": { "bone_type": "femur" },
  "phase4_bone_part": { "part": "proximal_end" },
  "phase5_completeness": { "status": "fragment" },
  "phase6_damage": { "fracture": true, "cut_marks": false, "burn_signs": null },
  "phase7_species_detail": { "applicable": true, "species": "Odocoileus virginianus" },
  "phase8_biological_profile": { "applicable": false },
  "phase9_multi_image": { "group_id": "specimen_0412", "angle": "anterior" },
  "bone_length": { "min_length_cm": 21.0, "max_length_cm": 26.0 },
  "scientific_name": "Odocoileus virginianus",
  "source": "...",
  "reference": "...",
  "license": "...",
  "author": "..."
}
```

| Field | Meaning |
| --- | --- |
| `image_path` | Path under `data/images/`. The first folder is the split; the file name without its extension matches the raw photo. |
| `phase1_bone_detection.bone_present` | `true` here, `false` in the `*_no_bone.json` files (where every other label is `null`). |
| `phase2_species.species` | `human` or `non_human`. |
| `phase3_bone_type.bone_type` | One of `config.BONE_TYPES`. |
| `phase4_bone_part.part` | One of `config.PART_LABELS`. |
| `phase5_completeness.status` | `complete` or `fragment`. |
| `phase6_damage` | `true` for a visible mark, `false` when the surface is visible and clean. A fracture means a visible crack or break line, not just being a fragment. |
| `phase7_species_detail` | For animals: `species` is the name the source gave, scientific or common. It is turned into a class and family group through `data/taxonomy_table.json` (`bone_analyzer.taxonomy`), so every name needs an entry there. |
| `phase8_biological_profile` | For human bones: `age_group` (`juvenile`, `adult`, `unknown`) and `sex` (`male`, `female`, `unknown`), when the source states them. |
| `phase9_multi_image.group_id` | Shared by every photo of the same specimen. All photos in a group stay in one split, so the model is never tested on a bone it saw in training. |
| `bone_length` | Optional measured length range, in cm. |
| `scientific_name`, `source`, `reference`, `license`, `author` | Where the photo came from. Not used for training. |

`null`, or a missing field, means "not labelled": that head skips the photo
instead of learning a guess. Label a field only when the photo shows it.

## Workflow

1. **Preprocess.** Letterbox every annotated photo to 384 px. Files that
   already exist are skipped, so rerunning only processes new annotations.

   ```bash
   python scripts/preprocess.py
   ```

2. **Rebalance the splits.** Gives every label enough validation and test
   images to be measured, moving whole specimen groups so nothing leaks between
   splits. Labels with fewer than 8 images stay in train. Run the dry run first
   to see the plan:

   ```bash
   python scripts/rebalance_splits.py --dry-run
   python scripts/rebalance_splits.py
   ```

3. **Train.**

   ```bash
   python scripts/train.py
   ```

   | Option | Effect |
   | --- | --- |
   | `--resume` | Continue an unfinished run without asking. |
   | `--fresh` | Start a new run without asking, deleting any unfinished one. |
   | `--evaluate` | Score the saved model on the test set and exit. |
   | `--epochs N` | Length of a new run (default 40). |
   | `--data-dir`, `--checkpoint-dir`, `--log-dir` | Override the default folders. |
   | `--no-class-weights` | Train without per-class loss weights. |

   Progress is saved after every epoch to `checkpoints/unfinished_run/`, so a
   run that is cut off continues from its last finished epoch. At the end the
   weights of the five best epochs from the second half of the run are
   averaged, confidence is calibrated on the validation set, and the model is
   saved as `checkpoints/bone_analyzer.pt`. When the average wins, the best
   single epoch is kept beside it as `bone_analyzer_best_epoch.pt`. Both are
   scored on the test set. The terminal output is copied to `logs/train.log`.

4. **Inspect** a checkpoint: head sizes, weight statistics, a forward and
   backward pass, the label spread and per-class validation results.

   ```bash
   python scripts/inspect_model.py checkpoints/bone_analyzer.pt
   ```

5. **Recalibrate** (only for older checkpoints, or after the validation set
   changes; training already does this). Nothing is retrained.

   ```bash
   python scripts/calibrate.py checkpoints/bone_analyzer.pt
   ```

### Training on Colab

When Google Drive is mounted at `/content/drive`, checkpoints, the unfinished
run and the logs go to `MyDrive/bone_analyzer/` so they outlive the session,
while images are read from the project folder on Colab's local disk. Install
`timm` in the notebook before training.

### Choosing the saved model

Every setting is in `src/bone_analyzer/config.py`, with the reasoning next to
it. The epoch that is kept is chosen by a save score: a weighted average of
validation F1 and accuracy across the heads (`SAVE_WEIGHTS`), minus penalties
for the mistakes that mislead a user most: a non-bone called a bone, an animal
called human, and a mammal called a bird (`SAVE_PENALTIES`). Missing a human
bone is weighted highest.

## Serving the model to the app

```bash
python scripts/serve.py checkpoints/bone_analyzer.pt
```

The checkpoint is looked up as given, then in this folder and in
`checkpoints/`. The server prints the address to type into the app
(Settings → Analyze on → Online → Online address). The phone and the computer
must be on the same Wi-Fi; on Windows, allow Python through the firewall for
private networks. To reach it from anywhere, run
`cloudflared tunnel --url http://localhost:8000` in another window and use the
`https://….trycloudflare.com` address it prints. `--port`, `--host` and
`--no-warmup` change the defaults.

- `GET /` is a health check: model name, device and uptime.
- `POST /analyze` takes `multipart/form-data` with one `image` field per photo
  (up to 8 angles of the same bone, 25 MB in total) and optional fields
  `length_cm`, `end_width_cm`, `shaft_width_cm`, `head_diameter_cm` and
  `shape` (`long`, `skull`, `flat` or `vertebra`).

The reply is the report built by `inference/analyzer.py`, for example:

```json
{
  "phase1_bone_detection": { "final_verdict": true, "final_confidence": 0.94 },
  "phase2_species":        { "species": "human", "confidence": 0.91 },
  "phase3_bone_type":      { "predictions": [{ "bone_type": "femur", "confidence": 0.79 }] },
  "phase4_bone_part":      { "part": "proximal_end", "confidence": 0.68 },
  "phase5_completeness":   { "status": "fragment", "confidence": 0.83 },
  "phase6_damage":         { "fracture": 0.71, "cut_marks": 0.22, "burn_signs": 0.04 },
  "phase7_species_detail": { "species": "none", "confidence": 0.0, "applicable": false },
  "phase8_biological_profile": { "age_group": "adult", "sex": "male", "applicable": true },
  "bone_length": { "min_cm": 34.4, "max_cm": 55.0, "user_length_cm": 41.0,
                   "range_source": "reference", "reference_for": "human femur" },
  "length_check": { "applied": true, "changed": false,
                    "reason": "41 cm is within the usual range for a human femur (34.4-55 cm), which supports the identification.",
                    "image_only": { "taxon": "human", "bone_type": "femur" } }
}
```

- `length_check` says whether a measured length or width changed the answer,
  and what the photo alone said. Reference sizes are in
  `inference/length_reference.json`.
- `shape_hint` appears when `shape` was sent. Bone types of other shapes keep
  20% of their probability, so a clear photo still wins over a wrong pick.
- `head_sex_hint` appears for an adult human femur or humerus with a head
  diameter: what the size suggests, kept apart from the model's own sex
  estimate.

Errors come back as `{ "error": true, "message": "..." }`. The app parses this
shape, and its tests pin it, so change both together.

## Exporting to the app

```bash
python scripts/export_mobile.py checkpoints/bone_analyzer.pt
```

Writes into `../app` (or `--app PATH`):

- `assets/model/ossia.onnx`: the network with normalisation, calibration and
  the final softmax or sigmoid built in. Large weights are stored as float16
  and widened back to float32 when the app loads them. The file is tracked
  with Git LFS, so a new export shows up as an ordinary changed file to commit.
- `assets/model/ossia_model.json`: label lists, the family rule and the
  length-check settings.
- `assets/model/length_reference.json`: a copy of the reference sizes.
- `test/fixtures/`: cases the app's tests check against, so the report built
  on the phone matches the server's.

It then runs validation and test images through PyTorch and the exported file
and stops if any head gives a different answer. `--check N` sets how many
images are compared (`0` skips the check, `-1` uses all of them).

## Package layout

```
src/bone_analyzer/
  config.py          every setting: labels, image size, training, save score, paths
  taxonomy.py        animal names -> class and family group
  model.py           ConvNeXt-Tiny backbone and the stage heads
  server.py          the HTTP server
  console.py         coloured terminal output
  data/              dataset, image decoding and letterboxing, augmentations
  training/          trainer, losses, class weights, calibration, reports, run log
  inference/         analyzer, length and width check, shape hint, head-size sex hint
scripts/             command-line entry points (above)
```
