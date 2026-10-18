import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ossia/data/models/analysis.dart';
import 'package:ossia/data/on_device/model_spec.dart';
import 'package:ossia/data/on_device/report_builder.dart';

/// The on-device report must be the server's report. The cases are test
/// photos' probabilities with the JSON server.py returned for them,
/// written by `scripts/export_mobile.py` in training/; they cover single
/// photos with and without a measured length (every branch of the length
/// check) and multi-angle sets.
void main() {
  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final ReportBuilder builder = ReportBuilder(
    ModelSpec.fromJson(readJson('assets/model/ossia_model.json')),
    LengthTable.fromJson(readJson('assets/model/length_reference.json')),
  );
  final List<dynamic> cases =
      readJson('test/fixtures/on_device_reports.json')['cases'] as List<dynamic>;

  test('the fixture covers single photos, lengths and multi-angle sets', () {
    final List<Map<String, dynamic>> all = cases.cast<Map<String, dynamic>>();
    expect(all.where((Map<String, dynamic> c) => (c['photos'] as List<dynamic>).length > 1),
        isNotEmpty);
    expect(all.where((Map<String, dynamic> c) => c['length_cm'] != null), isNotEmpty);
    expect(
      all.where((Map<String, dynamic> c) =>
          (c['expected'] as Map<String, dynamic>)['length_check']['changed'] == true),
      isNotEmpty,
    );
  });

  group('on-device report matches the server', () {
    for (final Map<String, dynamic> c in cases.cast<Map<String, dynamic>>()) {
      test(c['name'] as String, () {
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

        // Through JSON, so the comparison sees what the app would store.
        expectSameJson(jsonDecode(jsonEncode(report)), expected, 'report');
        expectSameJson(
          AnalysisResult.fromJson(report).toJson(),
          AnalysisResult.fromJson(expected).toJson(),
          'parsed',
        );
      });
    }
  });

  test('lengths in explanations read like Python\'s :g', () {
    expect(formatG(45.0), '45');
    expect(formatG(19.05), '19.05');
    expect(formatG(34.4), '34.4');
    expect(formatG(0.5), '0.5');
    expect(formatG(100.0), '100');
    expect(formatG(123.456789), '123.457');
  });
}

/// Same keys, same strings and flags, numbers equal to within rounding.
void expectSameJson(Object? actual, Object? expected, String path) {
  if (expected is Map) {
    expect(actual, isA<Map<dynamic, dynamic>>(), reason: path);
    final Map<dynamic, dynamic> a = actual! as Map<dynamic, dynamic>;
    expect(a.keys.toSet(), expected.keys.toSet(), reason: path);
    for (final dynamic k in expected.keys) {
      expectSameJson(a[k], expected[k], '$path.$k');
    }
  } else if (expected is List) {
    expect(actual, isA<List<dynamic>>(), reason: path);
    final List<dynamic> a = actual! as List<dynamic>;
    expect(a.length, expected.length, reason: path);
    for (int i = 0; i < expected.length; i++) {
      expectSameJson(a[i], expected[i], '$path[$i]');
    }
  } else if (expected is num) {
    expect(actual, isA<num>(), reason: path);
    expect((actual! as num).toDouble(), closeTo(expected.toDouble(), 1e-9), reason: path);
  } else {
    expect(actual, expected, reason: path);
  }
}
