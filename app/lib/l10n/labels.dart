/// Turns the model's keys ('femur', 'cervid', 'proximal_end') and the app's
/// enums into words in the app's language. The data layer keeps the keys; the
/// screens word them here at build time.
library;

import 'package:intl/intl.dart';

import '../core/theme/palette.dart';
import '../core/util/formatting.dart';
import '../data/models/analysis.dart';
import '../data/reference_data.dart';
import '../data/settings_controller.dart';
import 'app_localizations.dart';

/// How many stages the Analyzing screen walks through ([Labels.phaseLabel]).
const int kPhaseCount = 9;

/// One Atlas page's words in the app's language.
class AtlasText {
  const AtlasText({
    required this.name,
    required this.blurb,
    required this.summary,
    required this.landmarks,
    required this.siding,
    this.aka,
  });

  final String name;
  final String blurb;
  final String summary;
  final List<String> landmarks;
  final String siding;
  final String? aka;
}

const Set<String> _unnamedTaxa = <String>{'none', 'unknown', 'non_human'};

extension Labels on AppLocalizations {
  // ── Bones ────────────────────────────────────────────────────────────────

  String boneName(String key) => switch (key) {
        'skull' => boneSkull,
        'cranium' => boneCranium,
        'mandible' => boneMandible,
        'femur' => boneFemur,
        'tibia' => boneTibia,
        'humerus' => boneHumerus,
        'radius' => boneRadius,
        'ulna' => boneUlna,
        'scapula' => boneScapula,
        'os_coxa' => boneOsCoxa,
        'rib_1_2' => boneRib12,
        'typical_rib' => boneTypicalRib,
        'rib_11_12' => boneRib1112,
        'cervical_vertebrae' => boneCervical,
        'thoracic_vertebrae' => boneThoracic,
        'lumbar_vertebrae' => boneLumbar,
        _ => titleCase(key),
      };

  /// What a bone type is in everyday words, or null for a key we don't know.
  String? boneMeaningOf(String key) => switch (key) {
        'skull' => boneSkullMeaning,
        'cranium' => boneCraniumMeaning,
        'mandible' => boneMandibleMeaning,
        'femur' => boneFemurMeaning,
        'tibia' => boneTibiaMeaning,
        'humerus' => boneHumerusMeaning,
        'radius' => boneRadiusMeaning,
        'ulna' => boneUlnaMeaning,
        'scapula' => boneScapulaMeaning,
        'os_coxa' => boneOsCoxaMeaning,
        'rib_1_2' => boneRib12Meaning,
        'typical_rib' => boneTypicalRibMeaning,
        'rib_11_12' => boneRib1112Meaning,
        'cervical_vertebrae' => boneCervicalMeaning,
        'thoracic_vertebrae' => boneThoracicMeaning,
        'lumbar_vertebrae' => boneLumbarMeaning,
        _ => null,
      };

  // ── Animals ──────────────────────────────────────────────────────────────

  /// 'Human', the animal group's name, or 'Animal' when no group was named.
  String animalName(String taxon) => switch (taxon) {
        'human' => animalHuman,
        'canid' => animalCanid,
        'cervid' => animalCervid,
        'bovid' => animalBovid,
        'suid' => animalSuid,
        'felid' => animalFelid,
        'ursid' => animalUrsid,
        'leporid' => animalLeporid,
        'procyonid' => animalProcyonid,
        'equid' => animalEquid,
        'rodent' => animalRodent,
        'other_mammal' || 'mammal' => animalMammal,
        'bird' => animalBird,
        'reptile' => animalReptile,
        _ => _unnamedTaxa.contains(taxon) ? animalUnnamed : titleCase(taxon),
      };

  /// What an animal group means, or '' for a name we don't know.
  String animalMeaningOf(String taxon) => switch (taxon) {
        'human' => animalHumanMeaning,
        'canid' => animalCanidMeaning,
        'cervid' => animalCervidMeaning,
        'bovid' => animalBovidMeaning,
        'suid' => animalSuidMeaning,
        'felid' => animalFelidMeaning,
        'ursid' => animalUrsidMeaning,
        'leporid' => animalLeporidMeaning,
        'procyonid' => animalProcyonidMeaning,
        'equid' => animalEquidMeaning,
        'rodent' => animalRodentMeaning,
        'other_mammal' => animalOtherMammalMeaning,
        'mammal' => animalMammalMeaning,
        'bird' => animalBirdMeaning,
        'reptile' => animalReptileMeaning,
        _ => _unnamedTaxa.contains(taxon) ? animalUnnamedMeaning : '',
      };

  // ── Part, condition, damage, age and sex ─────────────────────────────────

  String partName(String part) => switch (part) {
        'complete' => partComplete,
        'shaft' => partShaft,
        'proximal_end' => partProximal,
        'distal_end' => partDistal,
        'fragment' => partFragment,
        _ => titleCase(part),
      };

  String completenessName(String status) => switch (status) {
        'complete' => statusComplete,
        'fragment' => statusFragment,
        _ => titleCase(status),
      };

  /// Part and completeness in one phrase, without saying the same thing
  /// twice: "Whole bone", "Near end, broken", "Broken piece".
  String conditionName(String part, String status) {
    if (part == 'complete') {
      return status == 'fragment' ? conditionWholeButBroken : partComplete;
    }
    return status == 'fragment' && part != 'fragment'
        ? conditionPartBroken(partName(part))
        : partName(part);
  }

  /// Takes the server's keys ('cut_marks') or the older English names
  /// ('Cut marks') that [DamageProfile.flagged] gives.
  String damageName(String key) => switch (key) {
        'fracture' || 'Fracture' => damageFracture,
        'cut_marks' || 'Cut marks' => damageCutMarks,
        'burn_signs' || 'Burn signs' => damageBurnSigns,
        _ => titleCase(key),
      };

  String ageName(String key) => switch (key) {
        'adult' => ageAdult,
        'juvenile' => ageJuvenile,
        'unknown' => unknownValue,
        _ => titleCase(key),
      };

  String sexName(String key) => switch (key) {
        'male' => sexMale,
        'female' => sexFemale,
        'unknown' => unknownValue,
        _ => titleCase(key),
      };

  // ── Whole results ────────────────────────────────────────────────────────

  /// The one-line verdict, e.g. "Cervid · Femur".
  String resultHeadline(AnalysisResult r) {
    if (!r.detection.present) return noBoneDetected;
    final String kind = animalName(r.isHuman ? 'human' : r.animalSpecies.label);
    final String bone = r.topBone == null ? boneUnidentified : boneName(r.topBone!.label);
    return '$kind · $bone';
  }

  /// The name the person gave a find, else its headline.
  String recordTitle(AnalysisRecord record) {
    final String? label = record.label?.trim();
    return label != null && label.isNotEmpty ? label : resultHeadline(record.result);
  }

  /// [AnalysisResult.alternativeKeys], worded.
  List<(String, double)> alternativesOf(AnalysisResult r) => <(String, double)>[
        for (final ({bool isTaxon, String key, double chance}) a in r.alternativeKeys)
          (a.isTaxon ? animalName(a.key) : boneName(a.key), a.chance),
      ];

  /// What the photo alone said, before the measured length was weighed in.
  String? photoOnlyHeadline(LengthCheck k) =>
      k.photoOnlyTaxon == null || k.photoOnlyBone == null
          ? null
          : '${animalName(k.photoOnlyTaxon!)} · ${boneName(k.photoOnlyBone!)}';

  String sourceName(AnalysisSource s) => s.onDevice ? sourceOnDevice : sourceServer;

  /// One of the [kPhaseCount] stages the Analyzing screen walks through.
  String phaseLabel(int i) => switch (i) {
        0 => phaseFinding,
        1 => phaseHumanOrAnimal,
        2 => phaseWhichBone,
        3 => phaseWhichPart,
        4 => phaseWholeOrBroken,
        5 => phaseMarks,
        6 => phaseWhichAnimal,
        7 => phaseAgeSex,
        _ => phaseWriting,
      };

  // ── Atlas ────────────────────────────────────────────────────────────────

  String regionName(BoneRegion r) => switch (r) {
        BoneRegion.cranial => regionCranial,
        BoneRegion.axial => regionAxial,
        BoneRegion.thoracic => regionThoracic,
        BoneRegion.upperLimb => regionUpperLimb,
        BoneRegion.lowerLimb => regionLowerLimb,
        BoneRegion.girdle => regionGirdle,
      };

  AtlasText atlas(BoneEntry e) {
    final String name = boneName(e.key);
    AtlasText page(String blurb, String summary, List<String> landmarks, String siding,
            [String? aka]) =>
        AtlasText(
          name: name,
          blurb: blurb,
          summary: summary,
          landmarks: landmarks,
          siding: siding,
          aka: aka,
        );
    return switch (e.key) {
      'skull' => page(atlasSkullBlurb, atlasSkullSummary,
          <String>[atlasSkullLm1, atlasSkullLm2, atlasSkullLm3, atlasSkullLm4], atlasSkullSiding),
      'cranium' => page(
          atlasCraniumBlurb,
          atlasCraniumSummary,
          <String>[atlasCraniumLm1, atlasCraniumLm2, atlasCraniumLm3, atlasCraniumLm4],
          atlasCraniumSiding,
          atlasCraniumAka),
      'mandible' => page(
          atlasMandibleBlurb,
          atlasMandibleSummary,
          <String>[atlasMandibleLm1, atlasMandibleLm2, atlasMandibleLm3, atlasMandibleLm4],
          atlasMandibleSiding),
      'femur' => page(atlasFemurBlurb, atlasFemurSummary,
          <String>[atlasFemurLm1, atlasFemurLm2, atlasFemurLm3, atlasFemurLm4], atlasFemurSiding),
      'tibia' => page(atlasTibiaBlurb, atlasTibiaSummary,
          <String>[atlasTibiaLm1, atlasTibiaLm2, atlasTibiaLm3, atlasTibiaLm4], atlasTibiaSiding),
      'humerus' => page(
          atlasHumerusBlurb,
          atlasHumerusSummary,
          <String>[atlasHumerusLm1, atlasHumerusLm2, atlasHumerusLm3, atlasHumerusLm4],
          atlasHumerusSiding),
      'radius' => page(atlasRadiusBlurb, atlasRadiusSummary,
          <String>[atlasRadiusLm1, atlasRadiusLm2, atlasRadiusLm3, atlasRadiusLm4], atlasRadiusSiding),
      'ulna' => page(atlasUlnaBlurb, atlasUlnaSummary,
          <String>[atlasUlnaLm1, atlasUlnaLm2, atlasUlnaLm3, atlasUlnaLm4], atlasUlnaSiding),
      'scapula' => page(
          atlasScapulaBlurb,
          atlasScapulaSummary,
          <String>[atlasScapulaLm1, atlasScapulaLm2, atlasScapulaLm3, atlasScapulaLm4],
          atlasScapulaSiding),
      'os_coxa' => page(
          atlasOsCoxaBlurb,
          atlasOsCoxaSummary,
          <String>[atlasOsCoxaLm1, atlasOsCoxaLm2, atlasOsCoxaLm3, atlasOsCoxaLm4],
          atlasOsCoxaSiding,
          atlasOsCoxaAka),
      'rib_1_2' => page(atlasRib12Blurb, atlasRib12Summary,
          <String>[atlasRib12Lm1, atlasRib12Lm2, atlasRib12Lm3, atlasRib12Lm4], atlasRib12Siding),
      'typical_rib' => page(
          atlasTypicalRibBlurb,
          atlasTypicalRibSummary,
          <String>[atlasTypicalRibLm1, atlasTypicalRibLm2, atlasTypicalRibLm3, atlasTypicalRibLm4],
          atlasTypicalRibSiding),
      'rib_11_12' => page(
          atlasRib1112Blurb,
          atlasRib1112Summary,
          <String>[atlasRib1112Lm1, atlasRib1112Lm2, atlasRib1112Lm3, atlasRib1112Lm4],
          atlasRib1112Siding),
      'cervical_vertebrae' => page(
          atlasCervicalBlurb,
          atlasCervicalSummary,
          <String>[atlasCervicalLm1, atlasCervicalLm2, atlasCervicalLm3, atlasCervicalLm4],
          atlasCervicalSiding),
      'thoracic_vertebrae' => page(
          atlasThoracicBlurb,
          atlasThoracicSummary,
          <String>[atlasThoracicLm1, atlasThoracicLm2, atlasThoracicLm3, atlasThoracicLm4],
          atlasThoracicSiding),
      'lumbar_vertebrae' => page(
          atlasLumbarBlurb,
          atlasLumbarSummary,
          <String>[atlasLumbarLm1, atlasLumbarLm2, atlasLumbarLm3, atlasLumbarLm4],
          atlasLumbarSiding),
      // Not translated yet: the English from reference_data.dart.
      _ => AtlasText(
          name: e.name,
          blurb: e.blurb,
          summary: e.summary,
          landmarks: e.landmarks,
          siding: e.siding,
          aka: e.alsoKnownAs,
        ),
    };
  }

  /// A "How analysis works" step: (title, detail).
  (String, String) phaseDoc(PhaseDoc d) => switch (d.number) {
        1 => (phaseDoc1Title, phaseDoc1Detail),
        2 => (phaseDoc2Title, phaseDoc2Detail),
        3 => (phaseDoc3Title, phaseDoc3Detail),
        4 => (phaseDoc4Title, phaseDoc4Detail),
        5 => (phaseDoc5Title, phaseDoc5Detail),
        6 => (phaseDoc6Title, phaseDoc6Detail),
        7 => (phaseDoc7Title, phaseDoc7Detail),
        8 => (phaseDoc8Title, phaseDoc8Detail),
        9 => (phaseDoc9Title, phaseDoc9Detail),
        _ => (d.title, d.detail),
      };

  // ── Settings words ───────────────────────────────────────────────────────

  String accentName(AccentTone a) => switch (a) {
        AccentTone.sunny => accentSunny,
        AccentTone.lime => accentLime,
        AccentTone.bubblegum => accentBubblegum,
        AccentTone.tangerine => accentTangerine,
        AccentTone.grape => accentGrape,
        AccentTone.sky => accentSky,
      };

  String unitName(LengthUnit u) => switch (u) {
        LengthUnit.centimetres => unitCentimetres,
        LengthUnit.inches => unitInches,
      };

  String unitSymbol(LengthUnit u) => switch (u) {
        LengthUnit.centimetres => unitCm,
        LengthUnit.inches => unitIn,
      };

  String engineName(EngineMode m) => switch (m) {
        EngineMode.onDevice => engineOnDevice,
        EngineMode.server => engineServer,
      };

  // ── Connection ───────────────────────────────────────────────────────────

  /// How a round trip feels: snappy, good, sluggish or slow.
  String pingWord(int ms) {
    if (ms < 150) return pingSnappy;
    if (ms < 400) return pingGood;
    if (ms < 1000) return pingSluggish;
    return pingSlow;
  }

  /// How long the server has been up, in short units: "40s", "2h 5m".
  String uptime(int? s) {
    if (s == null) return '?';
    if (s < 60) return uptimeSeconds(s);
    if (s < 3600) return uptimeMinutes(s ~/ 60);
    if (s < 86400) return uptimeHours(s ~/ 3600, (s % 3600) ~/ 60);
    return uptimeDays(s ~/ 86400, (s % 86400) ~/ 3600);
  }

  // ── Dates ────────────────────────────────────────────────────────────────

  /// "Just now", "5 min ago", "Yesterday", or a short date past a week.
  String relativeTime(DateTime t) {
    final Duration diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return justNow;
    if (diff.inMinutes < 60) return minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return hoursAgo(diff.inHours);
    if (diff.inDays == 1) return yesterday;
    if (diff.inDays < 7) return daysAgo(diff.inDays);
    return DateFormat(localeName == 'de' ? 'd.M.yy' : 'd/M/yy', localeName).format(t);
  }

  /// "Oct 16, 2026 at 3:05 PM", in the app's language.
  String longDate(DateTime t) =>
      dateAtTime(DateFormat.yMMMd(localeName).format(t), DateFormat.jm(localeName).format(t));

  /// "Oct 16, 2026".
  String shortDate(DateTime t) => DateFormat.yMMMd(localeName).format(t);
}
