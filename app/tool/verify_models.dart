// Console check for the model layer, runnable with `dart run`.
//
// `flutter test` needs a host C toolchain to build plugin native assets,
// which is not available on every development machine. This script covers
// the same parsing and reference-data invariants as test/analysis_test.dart
// with nothing but the Dart VM.
//
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:ossia/data/models/analysis.dart';
import 'package:ossia/data/plain_names.dart';
import 'package:ossia/data/reference_data.dart';

int failures = 0;
void check(String name, bool ok, [String? detail]) {
  print('${ok ? "PASS" : "FAIL"}  $name${detail == null ? "" : "  ($detail)"}');
  if (!ok) failures++;
}

void main() {
  final AnalysisResult r = AnalysisResult.fromJson(<String, dynamic>{
    'phase1_bone_detection': {'bone_present': true, 'confidence': 0.81, 'final_verdict': true, 'final_confidence': 0.88},
    'phase2_species': {'species': 'human', 'confidence': 0.93, 'available': true},
    'phase3_bone_type': {'predictions': [
      {'bone_type': 'femur', 'confidence': 0.77},
      {'bone_type': 'tibia', 'confidence': 0.14},
    ], 'available': true},
    'phase4_bone_part': {'part': 'proximal_end', 'confidence': 0.6},
    'phase5_completeness': {'status': 'fragment', 'confidence': 0.7},
    'phase6_damage': {'fracture': 0.62, 'cut_marks': 0.11, 'burn_signs': 0.02},
    'phase7_species_detail': {'species': 'none', 'confidence': 0.0, 'applicable': false},
    'phase8_biological_profile': {'age_group': 'adult', 'age_confidence': 0.71, 'sex': 'male', 'sex_confidence': 0.55, 'applicable': true},
  });

  check('human headline', r.headline == 'Human · Femur', r.headline);
  check('part title-cased', r.part.display == 'Proximal End', r.part.display);
  check('damage flagged', r.damage.flagged.join(',') == 'Fracture', r.damage.flagged.join(','));
  check('overall = weakest link', (r.overallConfidence - 0.77).abs() < 1e-9, '${r.overallConfidence}');

  final AnalysisResult none = AnalysisResult.fromJson(<String, dynamic>{
    'phase1_bone_detection': {'final_verdict': false, 'final_confidence': 0.2},
    'phase2_species': {'species': 'unknown', 'confidence': 0.0, 'available': false},
    'phase3_bone_type': {'predictions': [], 'available': false},
  });
  check('no-bone headline', none.headline == 'No bone detected', none.headline);
  check('no-bone topBone null', none.topBone == null);
  check('no-bone overall = sure there is none', (none.overallConfidence - 0.8).abs() < 1e-9, '${none.overallConfidence}');

  final AnalysisRecord rec = AnalysisRecord(
    id: 'abc', imagePath: '/tmp/x.jpg', createdAt: DateTime.utc(2026, 3, 4), label: 'TR2-114',
    result: AnalysisResult.fromJson(<String, dynamic>{
      'phase1_bone_detection': {'final_verdict': true, 'final_confidence': 0.9},
      'phase2_species': {'species': 'non_human', 'confidence': 0.8},
      'phase3_bone_type': {'predictions': [{'bone_type': 'typical_rib', 'confidence': 0.6}]},
      'phase7_species_detail': {'species': 'deer', 'confidence': 0.5},
    }),
  );
  final AnalysisRecord back = AnalysisRecord.fromJson(rec.toJson());
  check('round-trip id', back.id == 'abc');
  check('round-trip label', back.label == 'TR2-114');
  check('faunal headline', back.result.headline == 'Deer · Typical Rib', back.result.headline);

  // Shape returned by bone_analyzer/server.py for a faunal specimen
  // with a user-supplied length.
  final AnalysisResult served = AnalysisResult.fromJson(<String, dynamic>{
    'phase1_bone_detection': {'bone_present': true, 'confidence': 0.6, 'cnn_confidence': 0.99, 'final_confidence': 0.998, 'final_verdict': true},
    'phase2_species': {'species': 'non_human', 'confidence': 0.998, 'available': true},
    'phase3_bone_type': {'predictions': [
      {'bone_type': 'mandible', 'confidence': 0.34},
      {'bone_type': 'cervical_vertebrae', 'confidence': 0.27},
    ], 'available': true},
    'phase4_bone_part': {'part': 'complete', 'confidence': 0.99, 'available': true},
    'phase5_completeness': {'status': 'complete', 'confidence': 0.99, 'available': true},
    'phase6_damage': {'fracture': 0.005, 'cut_marks': 6.9e-05, 'burn_signs': 3.6e-06, 'available': true},
    'phase7_species_detail': {'species': 'deer', 'confidence': 0.6, 'available': true, 'applicable': true},
    'phase8_biological_profile': {'available': true, 'applicable': false, 'note': 'Non-human bone'},
    'bone_length': {'predicted_cm': 11.8, 'min_cm': 11.5, 'max_cm': 12.1, 'user_length_cm': 18.5},
    'num_images_analyzed': 1,
    'phase9_multi_image': {'num_angles': 1, 'user_length_cm': 18.5},
    'server': {'model': 'bone_analyzer.pt', 'device': 'cpu', 'elapsed_ms': 2088},
  });
  check('server headline', served.headline == 'Deer · Mandible', served.headline);
  check('server length range', served.length?.minCm == 11.5 && served.length?.maxCm == 12.1);
  check('server user length', served.length?.userMeasuredCm == 18.5);
  check('server profile not applicable', !served.biological.applicable);

  // Reference length range and a length check that changed the answer.
  final AnalysisResult checked = AnalysisResult.fromJson(<String, dynamic>{
    'phase1_bone_detection': {'final_verdict': true, 'final_confidence': 0.97},
    'phase2_species': {'species': 'non_human', 'confidence': 0.71},
    'phase3_bone_type': {'predictions': [{'bone_type': 'femur', 'confidence': 0.88}]},
    'phase7_species_detail': {'species': 'pig', 'confidence': 0.66, 'applicable': true},
    'bone_length': {'min_cm': 12.9, 'max_cm': 28.3, 'user_length_cm': 19.0, 'range_source': 'reference', 'reference_for': 'pig femur'},
    'length_check': {
      'applied': true, 'changed': true, 'user_length_cm': 19.0,
      'reason': '19 cm is shorter than a typical human femur (34.4-55 cm), and fits a pig femur (12.9-28.3 cm), so the length moved the answer.',
      'image_only': {'taxon': 'human', 'bone_type': 'femur', 'species_confidence': 0.55, 'bone_type_confidence': 0.9},
    },
  });
  check('length check parsed', checked.lengthCheck?.changed == true && checked.lengthCheck!.reason!.startsWith('19 cm'));
  check('photo-only headline', checked.lengthCheck?.photoOnlyHeadline == 'Human · Femur', checked.lengthCheck?.photoOnlyHeadline);
  check('reference range', checked.length?.fromReference == true && checked.length?.referenceFor == 'pig femur');
  final AnalysisResult checkedBack = AnalysisResult.fromJson(checked.toJson());
  check('length check round-trip', checkedBack.lengthCheck?.reason == checked.lengthCheck?.reason &&
      checkedBack.lengthCheck?.photoOnlyHeadline == 'Human · Femur' && checkedBack.length?.fromReference == true);
  final AnalysisResult multi = AnalysisResult.fromJson(<String, dynamic>{
    'phase1_bone_detection': {'final_verdict': true, 'final_confidence': 0.9},
    'length_check': {'applied': true, 'changed': false, 'per_image': [
      {'applied': true, 'changed': false, 'reason': 'first photo reason'},
    ]},
  });
  check('multi-photo length check reason', multi.lengthCheck?.reason == 'first photo reason');
  check('no length check key', r.lengthCheck == null);

  final AnalysisRecord measured = AnalysisRecord(
    id: 'm1', imagePath: '/tmp/m.jpg', createdAt: DateTime.utc(2026, 9, 13),
    result: served, measuredLengthCm: 18.5,
  );
  check('measured length round-trip',
      AnalysisRecord.fromJson(measured.toJson()).measuredLengthCm == 18.5);
  check('measured length optional', back.measuredLengthCm == null);

  final AnalysisRecord angles = AnalysisRecord(
    id: 'a1', imagePath: '/docs/a.jpg', extraImagePaths: const <String>['/docs/b.jpg', '/docs/c.jpg'],
    createdAt: DateTime.utc(2026, 9, 29),
    result: AnalysisResult.fromJson(<String, dynamic>{
      'phase1_bone_detection': {'final_verdict': true, 'final_confidence': 0.9},
      'num_images_analyzed': 3,
      'engine': {'kind': 'on_device', 'model': 'bone_analyzer.pt', 'elapsed_ms': 1400},
    }),
  );
  final AnalysisRecord anglesBack =
      AnalysisRecord.fromJson(jsonDecode(jsonEncode(angles.toJson())) as Map<String, dynamic>);
  check('every photo of the bone kept', anglesBack.imagePaths.join(',') == '/docs/a.jpg,/docs/b.jpg,/docs/c.jpg',
      anglesBack.imagePaths.join(','));
  check('photos survive renaming', anglesBack.copyWith(label: 'x').imagePaths.length == 3);
  check('single photo has no extras', back.imagePaths.length == 1);
  check('engine that read it', anglesBack.result.source?.label == 'On this phone', anglesBack.result.source?.label);

  // A shaky answer says what else it could be; a solid one doesn't.
  final AnalysisResult shaky = AnalysisResult.fromJson(<String, dynamic>{
    'phase1_bone_detection': {'final_verdict': true, 'final_confidence': 0.97},
    'phase2_species': {'species': 'non_human', 'confidence': 0.78},
    'phase3_bone_type': {'predictions': [
      {'bone_type': 'humerus', 'confidence': 0.65},
      {'bone_type': 'femur', 'confidence': 0.32},
    ]},
    'phase7_species_detail': {'species': 'bird', 'confidence': 0.75, 'applicable': true},
  });
  final String alts = shaky.alternatives.map(((String, double) a) => '${a.$1} ${a.$2.toStringAsFixed(2)}').join(', ');
  check('shaky answer offers alternatives', alts == 'Human 0.22, Femur 0.32', alts);
  check('solid answer offers none', r.alternatives.isEmpty);
  check('family name explained', animalName('cervid').name == 'Cervid' && animalName('cervid').meaning.contains('deer'));
  check('unnamed animal', animalName('none').name == 'Animal');
  check('older saved names kept', animalName('deer').name == 'Deer' && animalName('deer').meaning.isEmpty);
  check('bone explained', boneMeaning('femur') == 'the thigh bone');

  // The bone types of the model bundled with the app.
  final List<String> modelClasses = ((jsonDecode(File('assets/model/ossia_model.json').readAsStringSync())
          as Map<String, dynamic>)['labels']['bone_type'] as List<dynamic>)
      .cast<String>();
  final List<String> missing = modelClasses.where((String k) => boneEntryFor(k) == null).toList();
  check('atlas covers all ${modelClasses.length} model classes', missing.isEmpty, missing.join(','));
  check('no extra atlas entries', kBoneReference.length == modelClasses.length, '${kBoneReference.length}');

  print(failures == 0 ? '\nAll checks passed.' : '\n$failures check(s) failed.');
}
