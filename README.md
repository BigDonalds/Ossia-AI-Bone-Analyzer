# Ossia: AI Bone Analyzer

Identifies a bone from a photograph. One network reads the photo and answers
nine questions about it, from "is this a bone at all?" down to the taxon and,
for human bones, an age group and sex. The project has two parts:

- **`training/`** is the Python package `bone_analyzer`. It trains the model,
  calibrates its confidence, serves it over HTTP and exports it for phones.
- **`app/`** is the Ossia app itself, built in Flutter for Android and iOS.
  It runs the exported model on the phone, offline, or sends photos to the
  server in `training/`. It is available in English, German and Arabic.

## What the model reports

| Stage | Question | Answers |
| --- | --- | --- |
| 1 | Is there a bone in the photo? | yes / no |
| 2 | Human or animal? | `human`, `non_human` |
| 3 | Which bone? | 16 types: `skull`, `cranium`, `mandible`, `femur`, `humerus`, `tibia`, `radius`, `ulna`, `scapula`, `os_coxa`, `cervical_vertebrae`, `thoracic_vertebrae`, `lumbar_vertebrae`, `rib_1_2`, `typical_rib`, `rib_11_12` |
| 4 | Which part of it? | `complete`, `shaft`, `proximal_end`, `distal_end`, `fragment` |
| 5 | Complete or a fragment? | `complete`, `fragment` |
| 6 | Damage | `fracture`, `cut_marks`, `burn_signs` (each yes / no) |
| 7 | Which animal? | class (`mammal`, `bird`, `reptile`) and, for mammals, a family group: `canid`, `cervid`, `bovid`, `suid`, `felid`, `ursid`, `leporid`, `procyonid`, `equid`, `rodent`, `other_mammal` |
| 8 | Biological profile (human only) | age `juvenile` / `adult`, sex `male` / `female` |
| 9 | Several photos of one bone | the answers from every angle combined |

The family group is only reported for bones that show it (skulls, jaws, whole
limb bones, pelvis and scapula). A measured length (and, through the server,
end width, shaft width or head diameter) is checked against reference sizes
for each bone and can change the answer; the report says when it did.

The backbone is ConvNeXt-Tiny from `timm` (pretrained on ImageNet-22k,
fine-tuned on ImageNet-1k at 384 px), fed 384 px letterboxed images, with one
head per stage. Each head's confidence is calibrated with temperature scaling
on the validation set.

## Repository layout

```
training/
  src/bone_analyzer/   the package: config, data, model, training, inference, server
  scripts/             train, preprocess, rebalance, calibrate, inspect, serve, export
  data/                taxonomy_table.json (photos and annotations are not in the repo)
app/
  lib/                 the Flutter app
  assets/model/        the exported model (written by training/scripts/export_mobile.py)
  test/, tool/         tests and check scripts
```

`training/README.md` and `app/README.md` cover each part in detail.

## Quick start

Train and export (Python 3.10 or newer):

```bash
cd training
pip install -e ".[export]"
python scripts/preprocess.py
python scripts/train.py
python scripts/export_mobile.py checkpoints/bone_analyzer.pt
```

Run the app (a Flutter SDK with Dart 3.12 or newer):

```bash
cd app
flutter pub get
flutter run
```

The training photos and annotations are not part of this repository. The photos
come from many sources under different licences, so they can't be
redistributed together. `training/README.md` describes the folder layout and the
annotation format, so a dataset can be assembled in the same shape.

The exported model (`app/assets/model/ossia.onnx`, about 51 MB) is not checked
in either. Export one from a trained checkpoint before building the app.
Without it the app still builds and runs, but only the Online engine (the
server in `training/`) can analyse photos.

## Not a diagnosis

This project supports identification. It does not replace examination by a
qualified osteologist, and its output must not be used for medical, legal or
forensic decisions. Age and sex in particular come from the least certain
stages of the pipeline.

## License

The code is released under the [MIT License](LICENSE). The fonts in
`app/assets/fonts/` keep their own licence, the SIL Open Font License
(`app/assets/fonts/OFL.txt`).
