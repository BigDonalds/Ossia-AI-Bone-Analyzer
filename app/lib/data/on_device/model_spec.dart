/// The files that travel with the on-device model (assets/model/), read into
/// plain Dart objects. Both come from training/: `scripts/export_mobile.py`
/// writes ossia_model.json, and length_reference.json is a copy of
/// `inference/length_reference.json`. Nothing here imports Flutter, so the report
/// logic that uses it runs in plain Dart tests.
library;

/// Everything the Python analyzer reads from `config.py` and
/// `inference/length_check.py`, as exported alongside the model.
class ModelSpec {
  ModelSpec.fromJson(Map<String, dynamic> j)
      : modelFile = j['model_file'] as String,
        modelSha256 = j['model_sha256'] as String,
        modelBytes = (j['model_bytes'] as num).toInt(),
        checkpoint = j['checkpoint'] as String,
        epoch = (j['epoch'] as num).toInt(),
        exported = j['exported'] as String,
        imgSize = (j['img_size'] as num).toInt(),
        inputName = (j['input'] as Map<String, dynamic>)['name'] as String,
        outputs = _strings(j['outputs']),
        calibrated = j['calibrated'] as bool,
        species = _label(j, 'species'),
        boneTypes = _label(j, 'bone_type'),
        parts = _label(j, 'bone_part'),
        completeness = _label(j, 'completeness'),
        damage = _label(j, 'damage'),
        animalClasses = _label(j, 'animal_class'),
        mammalFamilies = _label(j, 'animal_family'),
        ageGroups = _label(j, 'age_group'),
        sexes = _label(j, 'sex'),
        familyBoneTypes = _strings(j['family_bone_types']).toSet(),
        useLengthRerank = j['use_length_rerank'] as bool,
        lengthCheck = LengthCheckSettings.fromJson(
            j['length_check'] as Map<String, dynamic>);

  final String modelFile;
  final String modelSha256;
  final int modelBytes;

  /// The PyTorch checkpoint the model was exported from, and its best epoch.
  final String checkpoint;
  final int epoch;
  final String exported;
  final int imgSize;
  final String inputName;
  final List<String> outputs;
  final bool calibrated;

  final List<String> species;
  final List<String> boneTypes;
  final List<String> parts;
  final List<String> completeness;
  final List<String> damage;
  final List<String> animalClasses;
  final List<String> mammalFamilies;
  final List<String> ageGroups;
  final List<String> sexes;
  final Set<String> familyBoneTypes;
  final bool useLengthRerank;
  final LengthCheckSettings lengthCheck;

  /// The non-human answers a report can give: a mammal family group, or a
  /// class for birds and reptiles (`length_check.ANIMAL_TAXA`).
  late final List<String> animalTaxa = <String>[
    ...mammalFamilies,
    ...animalClasses.where((String c) => c != 'mammal'),
  ];

  static List<String> _strings(Object? v) =>
      (v as List<dynamic>).cast<String>().toList(growable: false);

  static List<String> _label(Map<String, dynamic> j, String head) =>
      _strings((j['labels'] as Map<String, dynamic>)[head]);
}

/// The tuning constants of `inference/length_check.py`.
class LengthCheckSettings {
  LengthCheckSettings.fromJson(Map<String, dynamic> j)
      : toleranceAbove = _d(j['tolerance_above']),
        floorAbove = _d(j['floor_above']),
        toleranceBelow = _d(j['tolerance_below']),
        floorBelow = _d(j['floor_below']),
        slackCm = _d(j['slack_cm']),
        slackFraction = _d(j['slack_fraction']),
        confidencePull = (j['confidence_pull'] as Map<String, dynamic>)
            .map((String k, dynamic v) => MapEntry<String, double>(k, _d(v))),
        minCheckableMass = _d(j['min_checkable_mass']),
        candidatesReported = (j['candidates_reported'] as num).toInt(),
        unnamedTaxa = (j['unnamed_taxa'] as List<dynamic>).cast<String>().toSet(),
        shownAs = (j['shown_as'] as Map<String, dynamic>).cast<String, String>(),
        partShownAs = (j['part_shown_as'] as Map<String, dynamic>).cast<String, String>();

  final double toleranceAbove;
  final double floorAbove;
  final double toleranceBelow;
  final double floorBelow;
  final double slackCm;
  final double slackFraction;
  final Map<String, double> confidencePull;
  final double minCheckableMass;
  final int candidatesReported;
  final Set<String> unnamedTaxa;

  /// How each answer reads in explanations, e.g. 'cervid (deer family)'.
  final Map<String, String> shownAs;

  /// What a partial bone is called in explanations, e.g. 'one end of a bone'.
  final Map<String, String> partShownAs;

  static double _d(Object? v) => (v as num).toDouble();
}

/// One entry of length_reference.json: the usual greatest length of a
/// complete bone for one taxon.
class LengthRange {
  LengthRange.fromJson(Map<String, dynamic> j)
      : minCm = (j['min_cm'] as num).toDouble(),
        maxCm = (j['max_cm'] as num).toDouble(),
        confidence = j['confidence'] as String,
        measuredOn = j['measured_on'] as String?,
        upperBoundOnly = j['upper_bound_only'] as bool? ?? false;

  final double minCm;
  final double maxCm;
  final String confidence;
  final String? measuredOn;

  /// Only the maximum means anything (birds: nothing living is bigger than an
  /// ostrich); a length under it says nothing.
  final bool upperBoundOnly;
}

class LengthTable {
  LengthTable.fromJson(Map<String, dynamic> j)
      : _ranges = (j['ranges'] as Map<String, dynamic>).map(
          (String taxon, dynamic bones) => MapEntry<String, Map<String, LengthRange>>(
            taxon,
            (bones as Map<String, dynamic>).map(
              (String bone, dynamic e) => MapEntry<String, LengthRange>(
                  bone, LengthRange.fromJson(e as Map<String, dynamic>)),
            ),
          ),
        );

  final Map<String, Map<String, LengthRange>> _ranges;

  /// The entry for a taxon ('human' or an animal group) and bone type, or null.
  LengthRange? range(String taxon, String boneType) => _ranges[taxon]?[boneType];
}
