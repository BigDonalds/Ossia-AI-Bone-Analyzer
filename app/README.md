# Ossia

The phone app for the bone analyzer, built in Flutter. Photograph a bone (from
as many angles as you like) and the app walks the nine analysis stages and
reports what the model saw, with the confidence behind every call shown. The
model runs on the phone itself, or on a computer through the server in
`../training`; both give the same report. The app is in English, German and
Arabic, and works with no signal.

## Running it

```bash
flutter pub get
flutter run -d android
flutter run -d ios
```

iOS builds need a Mac with Xcode. On Windows or Linux the layout can be
previewed in the browser (narrow the window, or use device emulation at
393 × 852). On the web there is no file system, so photos show as a
placeholder:

```bash
flutter run -d chrome
```

An installable Android build:

```bash
flutter build apk --release --split-per-abi
```

The APKs land in `build/app/outputs/flutter-apk/`;
`app-arm64-v8a-release.apk` is the one for a modern phone. Release builds are
signed with the debug key until a release key is configured in
`android/app/build.gradle.kts`, which is fine for sideloading but not for the
Play Store.

Before building, export a model into `assets/model/` (see
[Where the analysis runs](#where-the-analysis-runs)).

## What is in it

Four tabs:

- **Scan**: the home screen. *Snap a bone* opens the in-app camera, *Upload a
  pic* the photo library, plus capture tips and recent finds.
- **Stash**: every saved analysis, grouped by date, searchable and filterable
  by human / faunal / flagged. Swipe a row to delete it.
- **Atlas**: a field reference for the sixteen bone types the model knows, each
  shown lit on a whole skeleton from the front and the back, and a walkthrough
  of the nine analysis stages.
- **Settings**: language, theme and accent, where analysis runs (this phone or
  online), model status, confidence floor, measurement units, haptics and
  library export.

**Capture.** The Bone Cam (`lib/ui/scan/camera_screen.dart`) overlays a dashed
outline for the kind of bone being shot (long bone, skull, flat bone, small
piece) with a rough shooting distance, since filling the outline sets the
distance. Flash, tap to focus and pinch to zoom are built in. The review screen
then takes **more angles of the same bone** (up to eight) and an optional
end-to-end length on a tape measure, or typed in. All photos are analysed
together. A finished report has *Add another angle*, which goes back to the
review with the same photos and length and replaces the report, keeping its
name and note.

**Reports** show the photos (swipe for the other angles), a headline verdict,
which engine read it, an overall confidence (the weakest of detection, species
and bone type), then sections for identification, condition, biological profile
or taxon, and measurements, with a link to the bone's Atlas entry. Reports can
be named, annotated and copied out as JSON.

**Model status** (`lib/ui/status/`) opens from the status pill on the home
screen or from Settings. For the on-device engine it shows the bundled model:
checkpoint, epoch, calibration, size and whether it is loaded. For the online
engine, `ServerMonitor` (`lib/data/server_monitor.dart`) pings the server every
30 s while the app is open, so the pill switches to *Offline* by itself and a
toast reports drops and recoveries. The page runs a five-step connection check
(address, reach, server, model, round trip) with ping history and uptime.

## Languages

English, German (Deutsch) and Arabic (العربية). In Arabic the whole layout
mirrors to right-to-left.

- **First launch** asks for a language before anything else. The phone's own
  language is preselected when the app has it; otherwise English is shown.
  Nothing is saved until *Let's go*.
- **The globe** at the top of the Scan, Stash, Atlas and Settings screens shows
  the current language (EN, DE, ع) and opens the language sheet.
- **Settings → Language → App language** opens the same sheet. *Match my phone*
  follows the phone's language, including changes while the app is open.
- The phone's per-app language setting (Android 13+, and iOS once the phone has
  more than one language) lists the same three. The lists are in
  `android/app/src/main/res/xml/locales_config.xml` and under
  `CFBundleLocalizations` in `ios/Runner/Info.plist`.

Text is worded when it is drawn, so switching language rewords saved reports
too: they store the model's keys (`femur`, `cervid`), not sentences. Two things
stay as written: the length note from an online analysis is reworded only when
`lib/l10n/report_text.dart` recognises it (otherwise it is shown in English),
and error messages from the server are shown as they arrive. Arabic uses
Western digits, so measurements and percentages read the same in every
language.

### Translations

Every word the app shows is in `lib/l10n/`, one file per language:

| File | Language |
| --- | --- |
| `app_en.arb` | English, the template the other two follow |
| `app_de.arb` | German |
| `app_ar.arb` | Arabic |

Each entry is a name and its text; `@name` below it holds the English and a
note on where it appears:

```json
"statusCheckNow": "Verbindung prüfen",
"@statusCheckNow": {
  "description": "English: Check connection (Button)"
},
```

When translating, change only the text in quotes after the name:

- Leave the names, and everything under `@...`, as they are.
- Words in curly brackets, like `{count}` or `{language}`, are filled in by the
  app. Keep them exactly as written, anywhere in the sentence.
- Sentences with a number look like
  `{count, plural, =1{1 report copied} other{{count} reports copied}}`.
  Translate the text inside each inner `{…}` and keep `plural`, `=1` and
  `other`. Arabic can add `=0`, `=2`, `few` (3 to 10) and `many` (11 to 99);
  `other` must always be there.
- A straight double quote inside the text is written `\"`.

Then check the files and regenerate the code:

```bash
dart run tool/check_translations.dart
flutter gen-l10n
```

The checker reports missing lines (they would show in English), a `{…}` that was
dropped or renamed, a plural without `other`, and the line where a file stops
being valid JSON. `flutter run` and `flutter build` regenerate
`app_localizations*.dart` too; never edit those by hand.

To add a sentence, put it in `app_en.arb` with its `@name` description (and
`placeholders` for any `{…}`), then in the other two, and use
`context.l10n.name` in the widget. To add a language: an `app_<code>.arb`, an
entry in `kLanguages` (`lib/l10n/l10n.dart`), the code in `locales_config.xml`,
`CFBundleLocalizations` and the Xcode project's `knownRegions`, and an
`ios/Runner/<code>.lproj/InfoPlist.strings`. A script the bundled fonts don't
cover needs its own font (see `pubspec.yaml`).

The permission messages iOS shows (camera, photos, local network) are in
`ios/Runner/<code>.lproj/InfoPlist.strings`, with the English copy also in
`Info.plist` as the fallback. Keep the two English versions the same.

## Where the analysis runs

**Settings → Analyze on** picks one of two engines behind the same interface
(`lib/data/analysis_engine.dart`). Both return the same report, down to the
wording of the length check. User-facing text avoids technical terms: it says
"Online", "the Ossia computer" and "Analyzer", and scientific names come with
their meaning (`lib/data/plain_names.dart`).

### On this phone (the default)

`LocalEngine` runs the model in `assets/model/` with ONNX Runtime
(`flutter_onnxruntime`). It works offline and photos never leave the phone.
Everything the server does around the network is ported to Dart in
`lib/data/on_device/`: letterbox preprocessing, calibrated confidence, the
class and family rules, reference bone lengths and the length check,
confidence-weighted votes across several photos, and the final tidying of the
report.

The model files come from the training side:

```bash
cd ../training
python scripts/export_mobile.py checkpoints/bone_analyzer.pt
```

This writes `assets/model/ossia.onnx` (about 51 MB, not checked in),
`ossia_model.json`, `length_reference.json` and the test fixtures, and checks
that the exported model gives the same answers as PyTorch. After training a
new model, export again and rebuild the app. The app copies the model out of its
bundle once per model version, so an update never runs a stale copy.

### Online

Start the server on a computer:

```bash
cd ../training
python scripts/serve.py checkpoints/bone_analyzer.pt
```

It prints the address to enter under **Settings → Analyze on → Online →
Online address**, for example `http://192.168.1.42:8000`. The phone and the
computer must be on the same Wi-Fi, or the server can be reached through a
tunnel (see `training/README.md`). If the server drops out mid-scan, the
analyzing screen offers to finish on the phone.

`RemoteEngine` posts the photos to `POST {address}/analyze`, one `image` field
per photo, plus `length_cm` when the bone was measured. The reply format is
documented in `training/README.md`. Unknown keys are ignored and missing ones
degrade gracefully, so the app keeps working while the pipeline changes. The
server also accepts widths and a shape hint that the app doesn't send yet.

Plain `http://` on a local network needs `NSAllowsLocalNetworking` on iOS and
`usesCleartextTraffic` on Android; both are set.

### Safeguards

- When the other of human or animal is 15% or more, or the top bone type is
  under 70%, the report says **"Not certain. It could also be:"** with the
  runner-up (`AnalysisResult.alternatives`).
- A length moves probability only between answers it can check. Answers with
  no reference length keep what the photo gave them, so a length that rules out
  every mammal can't make an unchecked "bird" more certain.
- Birds have an upper bound for the femur and tibia (the ostrich's), so a 45 cm
  femur can't be a bird.

## iOS notes

- `IPHONEOS_DEPLOYMENT_TARGET` is 16.0, the minimum ONNX Runtime supports. The
  bundle ID is `com.ossia.ossia`.
- `ios/Podfile` is checked in: ONNX Runtime needs `platform :ios, '16.0'` and
  `use_frameworks! :linkage => :static`, which the generated one lacks. On
  Android, `android/app/proguard-rules.pro` keeps ONNX Runtime's classes
  through R8.
- The camera, photo library and local-network usage strings are in
  `ios/Runner/Info.plist` and in each `ios/Runner/<code>.lproj/InfoPlist.strings`.

The app icon is generated for iOS and Android. To change it, edit
`tool/make_icon.py`, then run:

```bash
python tool/make_icon.py
dart run flutter_launcher_icons
```

The skeleton on the Atlas pages is drawn by `tool/make_skeleton.py`, which
writes `lib/data/skeleton_geometry.dart`. To change it, edit the script and run:

```bash
python tool/make_skeleton.py
```

## Layout

```
lib/
  core/
    theme/        palette, type scale, motion curves
    util/         haptics, formatting
  data/
    models/                analysis result and saved record, mirroring the report
    analysis_engine.dart   on-device and online engines behind one interface
    on_device/             loading the bundled model, photo preprocessing, and
                           the report the server would build
    history_store.dart     saved analyses and their photos
    settings_controller.dart
    reference_data.dart    the sixteen bone entries and the nine stage descriptions
  l10n/
    app_<code>.arb         the words, one file per language
    l10n.dart              the language list, context.l10n, LocalText
    labels.dart            the model's keys and the settings in words
    report_text.dart       rewording a report's length notes
  ui/
    root_shell.dart        tab scaffold, one navigator per tab
    language/   first-run picker, globe button and language sheet
    scan/       home, Bone Cam and outline guides, review and tape measure, analysing
    results/    report page, sections, collapsing photo header
    library/    saved analyses
    reference/  atlas and pipeline explainer
    settings/   settings and about
    status/     model status page, status pill and toasts
    widgets/    grouped rows, nav bars, sheets, primitives, the mascot
```

Design notes:

- Colours come from `AppColors`, a theme extension. The exception is ink black
  (`0xFF141414`) on surfaces that stay light in both themes: sticker fills, the
  tape measure and the camera overlay.
- Anything raised is a `Chunk` (`lib/ui/widgets/primitives.dart`): fill, 2.2 px
  ink outline and a hard shadow it presses into when tapped. Reuse it rather
  than drawing new borders.
- Type lives in `AppType`. The fonts (Bricolage Grotesque and DM Sans, with
  Baloo Bhaijaan 2 and Readex Pro for Arabic) are bundled in `assets/fonts/`
  under the SIL Open Font License; nothing is fetched at runtime.
  `AppType.tracking()` drops letter-spacing in Arabic, whose joined letters
  come apart when spaced.
- Right to left: padding that belongs to the content is
  `EdgeInsetsDirectional`, so it flips in Arabic. The hard shadows stay
  physical, so stickers cast to the bottom right in every language. The
  wordmark, the tape measure and the status diagrams stay left to right.
- User-facing text never goes in a string literal: it goes in the `.arb` files.
  The data layer hands screens a `LocalText` (worded at build time) rather than
  a finished sentence.
- The navigation bars, tab bar and photo header are custom rather than
  Material's. Back buttons sit at the leading edge (the right, in Arabic).

## Tests

```bash
flutter test
```

`flutter test` builds the plugins' native assets, so it needs a host C
toolchain (on Windows, the MSVC build tools for your architecture). The same
checks also run as plain Dart scripts that need only the Dart VM:

```bash
dart run tool/verify_models.dart
dart run tool/verify_on_device.dart
dart run tool/check_translations.dart
```

The on-device checks (`test/on_device_*_test.dart`, `tool/verify_on_device.dart`)
hold the phone to the server: for each test photo, singly and in multi-angle
sets, with lengths chosen to reach every branch of the length check, the report
built on the phone must equal the one `server.py` produced for the same
probabilities, and small images must letterbox exactly as in training.
`export_mobile.py` regenerates these cases with every export.

## Not a diagnosis

Ossia supports identification. It does not replace examination by a qualified
osteologist, and its output must not be used for medical, legal or forensic
decisions. Age and sex in particular come from the least certain stages of the
pipeline. The interface says so where it matters.
