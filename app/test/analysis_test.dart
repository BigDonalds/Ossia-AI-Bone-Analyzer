import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ossia/core/theme/app_theme.dart';
import 'package:ossia/core/theme/palette.dart';
import 'package:ossia/data/models/analysis.dart';
import 'package:ossia/data/plain_names.dart';
import 'package:ossia/data/reference_data.dart';

void main() {
  group('AnalysisResult', () {
    AnalysisResult parse(Map<String, dynamic> json) =>
        AnalysisResult.fromJson(json);

    test('reads the phase dictionary the Python pipeline emits', () {
      final AnalysisResult r = parse(<String, dynamic>{
        'phase1_bone_detection': <String, dynamic>{
          'bone_present': true,
          'confidence': 0.81,
          'final_verdict': true,
          'final_confidence': 0.88,
        },
        'phase2_species': <String, dynamic>{
          'species': 'human',
          'confidence': 0.93,
          'available': true,
        },
        'phase3_bone_type': <String, dynamic>{
          'predictions': <Map<String, dynamic>>[
            <String, dynamic>{'bone_type': 'femur', 'confidence': 0.77},
            <String, dynamic>{'bone_type': 'tibia', 'confidence': 0.14},
          ],
          'available': true,
        },
        'phase4_bone_part': <String, dynamic>{
          'part': 'proximal_end',
          'confidence': 0.6,
        },
        'phase5_completeness': <String, dynamic>{
          'status': 'fragment',
          'confidence': 0.7,
        },
        'phase6_damage': <String, dynamic>{
          'fracture': 0.62,
          'cut_marks': 0.11,
          'burn_signs': 0.02,
        },
        'phase7_species_detail': <String, dynamic>{
          'species': 'none',
          'confidence': 0.0,
          'applicable': false,
        },
        'phase8_biological_profile': <String, dynamic>{
          'age_group': 'adult',
          'age_confidence': 0.71,
          'sex': 'male',
          'sex_confidence': 0.55,
          'applicable': true,
        },
      });

      expect(r.isHuman, isTrue);
      expect(r.topBone?.display, 'Femur');
      expect(r.part.display, 'Proximal End');
      expect(r.headline, 'Human · Femur');
      expect(r.damage.flagged, <String>['Fracture']);
      // Weakest of detection (0.88), species (0.93) and element (0.77).
      expect(r.overallConfidence, closeTo(0.77, 0.001));
    });

    test('survives the abbreviated dictionary sent when no bone is found', () {
      final AnalysisResult r = parse(<String, dynamic>{
        'phase1_bone_detection': <String, dynamic>{
          'final_verdict': false,
          'final_confidence': 0.2,
        },
        'phase2_species': <String, dynamic>{
          'species': 'unknown',
          'confidence': 0.0,
          'available': false,
        },
        'phase3_bone_type': <String, dynamic>{
          'predictions': <dynamic>[],
          'available': false,
        },
      });

      expect(r.detection.present, isFalse);
      expect(r.topBone, isNull);
      expect(r.headline, 'No bone detected');
      // How sure the model is that there is no bone.
      expect(r.overallConfidence, closeTo(0.8, 0.001));
    });

    test('round-trips through JSON', () {
      final AnalysisRecord record = AnalysisRecord(
        id: 'abc',
        imagePath: '/tmp/x.jpg',
        createdAt: DateTime.utc(2026, 3, 4, 10, 30),
        label: 'TR2-114',
        result: parse(<String, dynamic>{
          'phase1_bone_detection': <String, dynamic>{
            'final_verdict': true,
            'final_confidence': 0.9,
          },
          'phase2_species': <String, dynamic>{
            'species': 'non_human',
            'confidence': 0.8,
          },
          'phase3_bone_type': <String, dynamic>{
            'predictions': <Map<String, dynamic>>[
              <String, dynamic>{'bone_type': 'typical_rib', 'confidence': 0.6},
            ],
          },
          'phase7_species_detail': <String, dynamic>{
            'species': 'deer',
            'confidence': 0.5,
          },
        }),
      );

      final AnalysisRecord back =
          AnalysisRecord.fromJson(record.toJson());

      expect(back.id, record.id);
      expect(back.label, 'TR2-114');
      expect(back.result.headline, 'Deer · Typical Rib');
      expect(back.displayTitle, 'TR2-114');
    });

    test('reads the length check and reference range', () {
      final AnalysisResult r = parse(<String, dynamic>{
        'phase1_bone_detection': <String, dynamic>{'final_verdict': true, 'final_confidence': 0.97},
        'phase2_species': <String, dynamic>{'species': 'non_human', 'confidence': 0.71},
        'phase3_bone_type': <String, dynamic>{
          'predictions': <Map<String, dynamic>>[
            <String, dynamic>{'bone_type': 'femur', 'confidence': 0.88},
          ],
        },
        'phase7_species_detail': <String, dynamic>{'species': 'pig', 'confidence': 0.66, 'applicable': true},
        'bone_length': <String, dynamic>{
          'min_cm': 12.9, 'max_cm': 28.3, 'user_length_cm': 19.0,
          'range_source': 'reference', 'reference_for': 'pig femur',
        },
        'length_check': <String, dynamic>{
          'applied': true,
          'changed': true,
          'reason': '19 cm fits a pig femur, so the length moved the answer.',
          'image_only': <String, dynamic>{'taxon': 'human', 'bone_type': 'femur'},
        },
      });

      expect(r.lengthCheck?.changed, isTrue);
      expect(r.lengthCheck?.photoOnlyHeadline, 'Human · Femur');
      expect(r.length?.fromReference, isTrue);
      expect(r.length?.referenceFor, 'pig femur');
      final AnalysisResult back = AnalysisResult.fromJson(r.toJson());
      expect(back.lengthCheck?.reason, r.lengthCheck?.reason);
      expect(back.length?.fromReference, isTrue);
    });

    test('a shaky answer says what else it could be', () {
      final AnalysisResult shaky = parse(<String, dynamic>{
        'phase1_bone_detection': <String, dynamic>{'final_verdict': true, 'final_confidence': 0.97},
        'phase2_species': <String, dynamic>{'species': 'non_human', 'confidence': 0.78},
        'phase3_bone_type': <String, dynamic>{
          'predictions': <Map<String, dynamic>>[
            <String, dynamic>{'bone_type': 'humerus', 'confidence': 0.65},
            <String, dynamic>{'bone_type': 'femur', 'confidence': 0.32},
          ],
        },
        'phase7_species_detail': <String, dynamic>{'species': 'bird', 'confidence': 0.75},
      });
      expect(shaky.alternatives.map(((String, double) a) => a.$1), <String>['Human', 'Femur']);
      expect(shaky.alternatives.first.$2, closeTo(0.22, 1e-9));
    });

    test('animal groups and bones come with everyday meanings', () {
      expect(animalName('cervid').name, 'Cervid');
      expect(animalName('cervid').meaning, contains('deer'));
      expect(animalName('none').name, 'Animal');
      expect(animalName('deer').name, 'Deer');
      expect(boneMeaning('femur'), 'the thigh bone');
    });

    test('keeps every photo of the bone and which engine read it', () {
      final AnalysisRecord record = AnalysisRecord(
        id: 'r1',
        imagePath: '/docs/specimens/r1_a.jpg',
        extraImagePaths: const <String>['/docs/specimens/r1_b.jpg', '/docs/specimens/r1_c.jpg'],
        createdAt: DateTime.utc(2026, 9, 29),
        result: parse(<String, dynamic>{
          'phase1_bone_detection': <String, dynamic>{'final_verdict': true, 'final_confidence': 0.9},
          'num_images_analyzed': 3,
          'engine': <String, dynamic>{
            'kind': 'on_device', 'model': 'bone_analyzer.pt', 'elapsed_ms': 1400,
          },
        }),
      );

      final AnalysisRecord back = AnalysisRecord.fromJson(
          jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>);
      expect(back.imagePaths, record.imagePaths);
      expect(back.result.imageCount, 3);
      expect(back.result.source?.onDevice, isTrue);
      expect(back.result.source?.label, 'On this phone');
      expect(back.copyWith(note: 'n').imagePaths.length, 3);

      final AnalysisRecord single = AnalysisRecord.fromJson(<String, dynamic>{
        ...record.toJson()..remove('extra_image_paths'),
      });
      expect(single.imagePaths, <String>['/docs/specimens/r1_a.jpg']);
    });
  });

  test('every model bone class has a reference entry', () {
    // The bone types of the model bundled with the app — a class the model
    // can predict but the Bones tab cannot explain is a gap in the app.
    final Map<String, dynamic> spec = jsonDecode(
            File('assets/model/ossia_model.json').readAsStringSync())
        as Map<String, dynamic>;
    final List<String> modelClasses =
        ((spec['labels'] as Map<String, dynamic>)['bone_type'] as List<dynamic>)
            .cast<String>();

    for (final String key in modelClasses) {
      expect(boneEntryFor(key), isNotNull, reason: 'missing atlas entry: $key');
    }
    expect(kBoneReference.length, modelClasses.length);
  });

  testWidgets('theme resolves colours for both brightnesses', (
    WidgetTester tester,
  ) async {
    for (final Brightness b in Brightness.values) {
      final ThemeData theme = AppTheme.build(b, AccentTone.lime);
      final AppColors? colors = theme.extension<AppColors>();
      expect(colors, isNotNull);
      expect(colors!.accent, AccentTone.lime.resolve(b));
      expect(theme.scaffoldBackgroundColor, colors.canvas);
    }
  });
}
