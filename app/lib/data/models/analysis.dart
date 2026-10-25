import 'dart:convert';

import '../../core/util/formatting.dart';
import '../plain_names.dart';

/// Mirrors the `phase1..phase9` dictionary produced by
/// `bone_analyzer/inference/analyzer.py::analyze_image`, so the on-device
/// engine and the server both fill the same model and the UI never needs to
/// know which one ran.

double _d(dynamic v) => v is num ? v.toDouble() : 0.0;

/// 'Human', the animal group's name (e.g. 'Cervid'), or 'Animal' when no
/// group was named. [animalName] says what each one means.
String taxonLabel(String taxon) => animalName(taxon).name;

class Detection {
  const Detection({required this.present, required this.confidence});

  final bool present;
  final double confidence;

  factory Detection.fromJson(Map<String, dynamic> j) => Detection(
        present:
            j['final_verdict'] as bool? ?? j['bone_present'] as bool? ?? false,
        confidence: _d(j['final_confidence'] ?? j['confidence']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'final_verdict': present,
        'final_confidence': confidence,
      };
}

class Scored {
  const Scored({
    required this.label,
    required this.confidence,
    this.available = true,
  });

  final String label;
  final double confidence;
  final bool available;

  String get display => titleCase(label);

  factory Scored.fromJson(Map<String, dynamic> j, String key) => Scored(
        label: (j[key] as String?) ?? 'unknown',
        confidence: _d(j['confidence']),
        available: j['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson(String key) => <String, dynamic>{
        key: label,
        'confidence': confidence,
        'available': available,
      };
}

class DamageProfile {
  const DamageProfile({
    required this.fracture,
    required this.cutMarks,
    required this.burnSigns,
    this.available = true,
  });

  final double fracture;
  final double cutMarks;
  final double burnSigns;
  final bool available;

  /// A trait is called out once it clears the reporting threshold used by the
  /// Python pipeline's summary printout.
  static const double threshold = 0.5;

  List<MapEntry<String, double>> get entries => <MapEntry<String, double>>[
        MapEntry<String, double>('Fracture', fracture),
        MapEntry<String, double>('Cut marks', cutMarks),
        MapEntry<String, double>('Burn signs', burnSigns),
      ];

  /// The same three, keyed by the server's names ('fracture', 'cut_marks',
  /// 'burn_signs') so the screens can word them in the app's language.
  List<MapEntry<String, double>> get traits => <MapEntry<String, double>>[
        MapEntry<String, double>('fracture', fracture),
        MapEntry<String, double>('cut_marks', cutMarks),
        MapEntry<String, double>('burn_signs', burnSigns),
      ];

  List<String> get flagged => entries
      .where((MapEntry<String, double> e) => e.value >= threshold)
      .map((MapEntry<String, double> e) => e.key)
      .toList();

  double get peak => entries
      .map((MapEntry<String, double> e) => e.value)
      .reduce((double a, double b) => a > b ? a : b);

  factory DamageProfile.fromJson(Map<String, dynamic> j) => DamageProfile(
        fracture: _d(j['fracture']),
        cutMarks: _d(j['cut_marks']),
        burnSigns: _d(j['burn_signs']),
        available: j['available'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fracture': fracture,
        'cut_marks': cutMarks,
        'burn_signs': burnSigns,
        'available': available,
      };
}

class BiologicalProfile {
  const BiologicalProfile({
    required this.ageGroup,
    required this.ageConfidence,
    required this.sex,
    required this.sexConfidence,
    required this.applicable,
  });

  final String ageGroup;
  final double ageConfidence;
  final String sex;
  final double sexConfidence;

  /// Age and sex heads only run on human specimens.
  final bool applicable;

  factory BiologicalProfile.fromJson(Map<String, dynamic> j) =>
      BiologicalProfile(
        ageGroup: (j['age_group'] as String?) ?? 'unknown',
        ageConfidence: _d(j['age_confidence']),
        sex: (j['sex'] as String?) ?? 'unknown',
        sexConfidence: _d(j['sex_confidence']),
        applicable: j['applicable'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'age_group': ageGroup,
        'age_confidence': ageConfidence,
        'sex': sex,
        'sex_confidence': sexConfidence,
        'applicable': applicable,
      };
}

/// Length range in centimetres for the identified bone. Current servers send the
/// reference range for that species and bone ([fromReference]); reports saved
/// before that carry the model's own estimate.
class LengthEstimate {
  const LengthEstimate({
    required this.minCm,
    required this.maxCm,
    this.userMeasuredCm,
    this.fromReference = false,
    this.referenceFor,
  });

  final double minCm;
  final double maxCm;
  final double? userMeasuredCm;
  final bool fromReference;

  /// What the range describes, e.g. "human femur".
  final String? referenceFor;

  bool get userAgrees =>
      userMeasuredCm != null &&
      userMeasuredCm! >= minCm &&
      userMeasuredCm! <= maxCm;

  factory LengthEstimate.fromJson(Map<String, dynamic> j) => LengthEstimate(
        minCm: _d(j['min_cm']),
        maxCm: _d(j['max_cm']),
        userMeasuredCm: j['user_length_cm'] == null ? null : _d(j['user_length_cm']),
        fromReference: j['range_source'] == 'reference',
        referenceFor: j['reference_for'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'min_cm': minCm,
        'max_cm': maxCm,
        'user_length_cm': userMeasuredCm,
        'range_source': fromReference ? 'reference' : 'model',
        if (referenceFor != null) 'reference_for': referenceFor,
      };
}

/// What the user's measured length did to the identification (the server's
/// `length_check`): whether it was used, whether it changed the answer, and why.
class LengthCheck {
  const LengthCheck({
    required this.applied,
    required this.changed,
    this.reason,
    this.photoOnlyTaxon,
    this.photoOnlyBone,
  });

  final bool applied;
  final bool changed;

  /// Plain-English explanation from the server, e.g. "45 cm is within the usual
  /// range for a human femur (34.4-55 cm), which supports the identification."
  final String? reason;

  /// The answer from the photo alone, before the length was considered.
  final String? photoOnlyTaxon;
  final String? photoOnlyBone;

  String? get photoOnlyHeadline => photoOnlyTaxon == null || photoOnlyBone == null
      ? null
      : '${taxonLabel(photoOnlyTaxon!)} · ${titleCase(photoOnlyBone!)}';

  factory LengthCheck.fromJson(Map<String, dynamic> j) {
    // Multi-photo reports nest one check per photo; explain with the one that
    // changed the answer, else the first.
    Map<String, dynamic> explained = j;
    final List<Map<String, dynamic>> perImage =
        ((j['per_image'] as List<dynamic>?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();
    if (j['reason'] == null && perImage.isNotEmpty) {
      explained = perImage.firstWhere(
        (Map<String, dynamic> c) => c['changed'] == true,
        orElse: () => perImage.first,
      );
    }
    final Map<String, dynamic> before =
        (explained['image_only'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return LengthCheck(
      applied: j['applied'] as bool? ?? false,
      changed: j['changed'] as bool? ?? false,
      reason: explained['reason'] as String?,
      photoOnlyTaxon: before['taxon'] as String?,
      photoOnlyBone: before['bone_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'applied': applied,
        'changed': changed,
        'reason': reason,
        if (photoOnlyTaxon != null && photoOnlyBone != null)
          'image_only': <String, dynamic>{
            'taxon': photoOnlyTaxon,
            'bone_type': photoOnlyBone,
          },
      };
}

/// Which engine wrote a report: the phone's own model or the Ossia computer.
class AnalysisSource {
  const AnalysisSource({required this.onDevice, this.model, this.elapsedMs});

  final bool onDevice;

  /// The checkpoint it ran, e.g. "bone_analyzer.pt".
  final String? model;
  final int? elapsedMs;

  String get label => onDevice ? 'On this phone' : 'On the Ossia computer';

  factory AnalysisSource.fromJson(Map<String, dynamic> j) => AnalysisSource(
        onDevice: j['kind'] == 'on_device',
        model: j['model'] as String?,
        elapsedMs: (j['elapsed_ms'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': onDevice ? 'on_device' : 'server',
        'model': model,
        'elapsed_ms': elapsedMs,
      };
}

class AnalysisResult {
  const AnalysisResult({
    required this.detection,
    required this.species,
    required this.boneTypes,
    required this.part,
    required this.completeness,
    required this.damage,
    required this.animalSpecies,
    required this.biological,
    this.length,
    this.lengthCheck,
    this.imageCount = 1,
    this.photosWithBone,
    this.source,
  });

  final Detection detection;
  final Scored species;

  /// Top-3, highest first.
  final List<Scored> boneTypes;
  final Scored part;
  final Scored completeness;
  final DamageProfile damage;

  /// Only meaningful when [species] is non-human.
  final Scored animalSpecies;
  final BiologicalProfile biological;
  final LengthEstimate? length;

  /// Present when the server compared a measured length against reference
  /// ranges; species and element above already reflect it.
  final LengthCheck? lengthCheck;
  final int imageCount;

  /// Of several photos, how many showed the bone; only those were read.
  /// Null for one photo, or a report from before this was recorded.
  final int? photosWithBone;
  final AnalysisSource? source;

  bool get isHuman => species.label == 'human';
  Scored? get topBone => boneTypes.isEmpty ? null : boneTypes.first;

  /// The one-line verdict shown under the specimen image.
  String get headline {
    if (!detection.present) return 'No bone detected';
    final String kind = taxonLabel(isHuman ? 'human' : animalSpecies.label);
    final String bone = topBone?.display ?? 'Unidentified';
    return '$kind · $bone';
  }

  /// Other answers worth showing when the top one isn't clear-cut: the other
  /// of human or animal, and the runner-up bone. Each comes with its chance.
  /// Empty when the headline is solid.
  List<(String, double)> get alternatives => alternativeKeys
      .map((({bool isTaxon, String key, double chance}) a) =>
          (a.isTaxon ? taxonLabel(a.key) : titleCase(a.key), a.chance))
      .toList();

  /// [alternatives] before wording: an animal group key ('human', or 'none'
  /// for an unnamed animal) or a bone type key, so the screens can name each
  /// in the app's language.
  List<({bool isTaxon, String key, double chance})> get alternativeKeys {
    if (!detection.present) return const <({bool isTaxon, String key, double chance})>[];
    final List<({bool isTaxon, String key, double chance})> out =
        <({bool isTaxon, String key, double chance})>[];
    final double other = 1 - species.confidence;
    if (species.confidence < 0.85 && other >= 0.1) {
      out.add((isTaxon: true, key: isHuman ? 'none' : 'human', chance: other));
    }
    if (boneTypes.length > 1 &&
        boneTypes.first.confidence < 0.7 &&
        boneTypes[1].confidence >= 0.15) {
      out.add((isTaxon: false, key: boneTypes[1].label, chance: boneTypes[1].confidence));
    }
    return out;
  }

  /// The chance the named animal group is right: animal at all, times that
  /// group among animals. Zero for a human bone.
  double get animalChance =>
      isHuman ? 0 : species.confidence * animalSpecies.confidence;

  /// The steps behind the headline and how sure each one is, in order:
  /// finding the bone, human or animal, which bone and, for an animal with a
  /// named group, which animal. Empty when no bone was found.
  List<({String step, double chance})> get confidenceSteps => detection.present
      ? <({String step, double chance})>[
          (step: 'detect', chance: detection.confidence),
          (step: 'species', chance: species.confidence),
          if (topBone != null) (step: 'bone', chance: topBone!.confidence),
          if (!isHuman && animalSpecies.confidence > 0)
            (step: 'animal', chance: animalChance),
        ]
      : const <({String step, double chance})>[];

  /// Overall trust in the result: the weakest of [confidenceSteps], or, when
  /// no bone was found, how sure the model is that there is none.
  double get overallConfidence {
    if (!detection.present) return 1 - detection.confidence;
    return confidenceSteps
        .map((({String step, double chance}) s) => s.chance)
        .reduce((double a, double b) => a < b ? a : b);
  }

  factory AnalysisResult.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic> m(String k) =>
        (j[k] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final List<dynamic> preds =
        (m('phase3_bone_type')['predictions'] as List<dynamic>?) ??
            const <dynamic>[];

    return AnalysisResult(
      detection: Detection.fromJson(m('phase1_bone_detection')),
      species: Scored.fromJson(m('phase2_species'), 'species'),
      boneTypes: preds
          .cast<Map<String, dynamic>>()
          .map((Map<String, dynamic> p) => Scored(
                label: (p['bone_type'] as String?) ?? 'unknown',
                confidence: _d(p['confidence']),
              ))
          .toList(),
      part: Scored.fromJson(m('phase4_bone_part'), 'part'),
      completeness: Scored.fromJson(m('phase5_completeness'), 'status'),
      damage: DamageProfile.fromJson(m('phase6_damage')),
      animalSpecies: Scored.fromJson(m('phase7_species_detail'), 'species'),
      biological: BiologicalProfile.fromJson(m('phase8_biological_profile')),
      length: j['bone_length'] == null
          ? null
          : LengthEstimate.fromJson(j['bone_length'] as Map<String, dynamic>),
      lengthCheck: j['length_check'] is Map<String, dynamic>
          ? LengthCheck.fromJson(j['length_check'] as Map<String, dynamic>)
          : null,
      imageCount: (j['num_images_analyzed'] as int?) ?? 1,
      photosWithBone: (m('phase9_multi_image')['photos_with_bone'] as num?)?.toInt(),
      source: j['engine'] is Map<String, dynamic>
          ? AnalysisSource.fromJson(j['engine'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'phase1_bone_detection': detection.toJson(),
        'phase2_species': species.toJson('species'),
        'phase3_bone_type': <String, dynamic>{
          'predictions': boneTypes
              .map((Scored s) => <String, dynamic>{
                    'bone_type': s.label,
                    'confidence': s.confidence,
                  })
              .toList(),
          'available': boneTypes.isNotEmpty,
        },
        'phase4_bone_part': part.toJson('part'),
        'phase5_completeness': completeness.toJson('status'),
        'phase6_damage': damage.toJson(),
        'phase7_species_detail': animalSpecies.toJson('species'),
        'phase8_biological_profile': biological.toJson(),
        if (length != null) 'bone_length': length!.toJson(),
        if (lengthCheck != null) 'length_check': lengthCheck!.toJson(),
        'num_images_analyzed': imageCount,
        if (photosWithBone != null)
          'phase9_multi_image': <String, dynamic>{
            'num_angles': imageCount,
            'photos_with_bone': photosWithBone,
          },
        if (source != null) 'engine': source!.toJson(),
      };
}

/// A saved analysis: the result plus the specimen photos and user annotations.
class AnalysisRecord {
  const AnalysisRecord({
    required this.id,
    required this.imagePath,
    this.extraImagePaths = const <String>[],
    required this.createdAt,
    required this.result,
    this.label,
    this.note,
    this.measuredLengthCm,
  });

  final String id;

  /// The first photo: the cover in the Library and the report header.
  final String imagePath;

  /// More angles of the same bone, analysed together with the first.
  final List<String> extraImagePaths;
  final DateTime createdAt;
  final AnalysisResult result;

  /// User-given specimen name, e.g. a site catalogue number.
  final String? label;
  final String? note;

  /// End-to-end length the user measured by hand before analysis, if they
  /// gave one. Optional: most photographs will not have it.
  final double? measuredLengthCm;

  List<String> get imagePaths => <String>[imagePath, ...extraImagePaths];

  String get displayTitle =>
      label != null && label!.trim().isNotEmpty ? label!.trim() : result.headline;

  AnalysisRecord copyWith({String? label, String? note}) => AnalysisRecord(
        id: id,
        imagePath: imagePath,
        extraImagePaths: extraImagePaths,
        createdAt: createdAt,
        result: result,
        label: label ?? this.label,
        note: note ?? this.note,
        measuredLengthCm: measuredLengthCm,
      );

  factory AnalysisRecord.fromJson(Map<String, dynamic> j) => AnalysisRecord(
        id: j['id'] as String,
        imagePath: j['image_path'] as String,
        extraImagePaths:
            ((j['extra_image_paths'] as List<dynamic>?) ?? const <dynamic>[]).cast<String>(),
        createdAt: DateTime.parse(j['created_at'] as String),
        result: AnalysisResult.fromJson(j['result'] as Map<String, dynamic>),
        label: j['label'] as String?,
        note: j['note'] as String?,
        measuredLengthCm: (j['measured_length_cm'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'image_path': imagePath,
        if (extraImagePaths.isNotEmpty) 'extra_image_paths': extraImagePaths,
        'created_at': createdAt.toIso8601String(),
        'result': result.toJson(),
        'label': label,
        'note': note,
        'measured_length_cm': measuredLengthCm,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}
