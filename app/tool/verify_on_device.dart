// Console check for the on-device engine, runnable with `dart run` where
// `flutter test` can't build (see verify_models.dart). Covers the same ground
// as test/on_device_report_test.dart and test/on_device_prep_test.dart: the
// report built on the phone must equal the server's for the same
// probabilities, and photos must be letterboxed exactly like the training
// images. The cases are written by scripts/export_mobile.py in training/.
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:ossia/data/models/analysis.dart';
import 'package:ossia/data/on_device/image_prep.dart';
import 'package:ossia/data/on_device/model_spec.dart';
import 'package:ossia/data/on_device/report_builder.dart';

int failures = 0;
int compared = 0;
final List<String> differences = <String>[];

void differ(String message) {
  failures++;
  if (differences.length < 40) differences.add(message);
}

/// Same keys, same strings and flags, numbers equal to within rounding.
void same(Object? actual, Object? expected, String path) {
  compared++;
  if (expected is Map) {
    if (actual is! Map) return differ('$path: expected a map, got $actual');
    final Set<dynamic> extra = actual.keys.toSet().difference(expected.keys.toSet());
    final Set<dynamic> missing = expected.keys.toSet().difference(actual.keys.toSet());
    if (extra.isNotEmpty || missing.isNotEmpty) {
      return differ('$path: keys $extra extra, $missing missing');
    }
    for (final dynamic k in expected.keys) {
      same(actual[k], expected[k], '$path.$k');
    }
  } else if (expected is List) {
    if (actual is! List || actual.length != expected.length) {
      return differ('$path: expected a list of ${expected.length}, got $actual');
    }
    for (int i = 0; i < expected.length; i++) {
      same(actual[i], expected[i], '$path[$i]');
    }
  } else if (expected is num) {
    if (actual is! num || (actual - expected).abs() > 1e-9) {
      differ('$path: expected $expected, got $actual');
    }
  } else if (actual != expected) {
    differ('$path:\n    expected "$expected"\n    got      "$actual"');
  }
}

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final ReportBuilder builder = ReportBuilder(
    ModelSpec.fromJson(readJson('assets/model/ossia_model.json')),
    LengthTable.fromJson(readJson('assets/model/length_reference.json')),
  );
  final List<dynamic> cases =
      readJson('test/fixtures/on_device_reports.json')['cases'] as List<dynamic>;
  for (final Map<String, dynamic> c in cases.cast<Map<String, dynamic>>()) {
    final List<HeadProbabilities> photos = <HeadProbabilities>[
      for (final dynamic p in c['photos'] as List<dynamic>)
        (p as Map<String, dynamic>).map((String head, dynamic values) =>
            MapEntry<String, List<double>>(head, <double>[
              for (final dynamic v in values as List<dynamic>) (v as num).toDouble(),
            ])),
    ];
    final Map<String, dynamic> report = builder.report(
      photos,
      (c['names'] as List<dynamic>).cast<String>(),
      (c['length_cm'] as num?)?.toDouble(),
    );
    final Map<String, dynamic> expected = c['expected'] as Map<String, dynamic>;
    same(jsonDecode(jsonEncode(report)), expected, '[${c['name']}]');
    same(AnalysisResult.fromJson(report).toJson(),
        AnalysisResult.fromJson(expected).toJson(), '[${c['name']}] parsed');
  }
  print('${failures == 0 ? "PASS" : "FAIL"}  reports: ${cases.length} cases, '
      '$compared values compared with the server\'s');

  const String dir = 'test/fixtures/prep';
  for (final String file in <String>[
    'shrink_fraction.png',
    'shrink_whole.png',
    'enlarge.png',
    'grey.png',
    'rgba.png',
    'rotated.jpg',
  ]) {
    final RgbImage image = decodeUpright(File('$dir/$file').readAsBytesSync())!;
    final Uint8List ours = letterbox(image, 64);
    final Uint8List theirs = Uint8List.fromList(img
        .decodePng(File('$dir/${file.split('.').first}.expected.png').readAsBytesSync())!
        .getBytes(order: img.ChannelOrder.rgb));
    int worst = 0;
    int identical = 0;
    int total = 0;
    for (int i = 0; i < ours.length; i++) {
      final int d = (ours[i] - theirs[i]).abs();
      if (d > worst) worst = d;
      if (d == 0) identical++;
      total += d;
    }
    // Shrinking matches OpenCV exactly; enlarging runs in its fixed point (a
    // few values one step off); JPEG decoders differ by a level or two.
    final bool ok = file.endsWith('.jpg')
        ? total / ours.length < 3
        : worst <= 1 && identical / ours.length > 0.95;
    if (!ok) failures++;
    print('${ok ? "PASS" : "FAIL"}  letterbox $file (${image.width}x${image.height}): '
        'largest difference $worst, ${(100 * identical / ours.length).toStringAsFixed(1)}% identical');
  }

  final bool g = formatG(45.0) == '45' &&
      formatG(19.05) == '19.05' &&
      formatG(123.456789) == '123.457';
  if (!g) failures++;
  print('${g ? "PASS" : "FAIL"}  lengths written like Python');

  differences.forEach(print);
  print(failures == 0 ? '\nAll checks passed.' : '\n$failures check(s) failed.');
  exit(failures == 0 ? 0 : 1);
}
