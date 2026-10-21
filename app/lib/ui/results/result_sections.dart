import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../data/models/analysis.dart';
import '../../data/reference_data.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../../l10n/report_text.dart';
import '../reference/bone_detail_screen.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/bone_sketch.dart';
import '../widgets/inset_group.dart';
import '../widgets/phone_icon.dart';
import '../widgets/primitives.dart';
import '../widgets/stat_icon.dart';
import '../widgets/text_fit.dart';

/// Confidence is colour-coded on one scale everywhere in the app.
Color confidenceTone(BuildContext context, double v) {
  final AppColors c = context.colors;
  if (v >= 0.75) return c.positive;
  if (v >= 0.5) return c.accent;
  if (v >= 0.3) return c.caution;
  return c.critical;
}

String confidenceWord(AppLocalizations l, double v) {
  if (v >= 0.85) return l.confStrong;
  if (v >= 0.7) return l.confGood;
  if (v >= 0.5) return l.confModerate;
  if (v >= 0.3) return l.confWeak;
  return l.confVeryWeak;
}

/// The verdict block that sits directly under the specimen photograph.
class VerdictBlock extends StatelessWidget {
  const VerdictBlock({super.key, required this.record});

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final AnalysisResult r = record.result;
    final double conf = r.overallConfidence;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              StatusPill(
                r.detection.present ? l.resultBoneDetected : l.resultNoBoneFound,
                color: r.detection.present ? c.positive : c.critical,
                filled: true,
                icon: r.detection.present
                    ? Icons.check_rounded
                    : Icons.question_mark_rounded,
              ),
              if (r.detection.present)
                StatusPill(
                  r.isHuman ? l.animalHuman : l.animalUnnamed,
                  color: c.sticker(r.isHuman ? 3 : 1),
                  filled: true,
                  icon: r.isHuman
                      ? Icons.accessibility_new_rounded
                      : Icons.pets_rounded,
                ),
              if (r.imageCount > 1)
                StatusPill(r.detection.present && (r.photosWithBone ?? r.imageCount) < r.imageCount
                    ? l.resultAnglesWithBone(r.photosWithBone!, r.imageCount)
                    : l.resultAngles(r.imageCount)),
              if (r.source != null)
                StatusPill(
                  l.sourceName(r.source!),
                  icon: r.source!.onDevice ? null : Icons.dns_rounded,
                  leading: r.source!.onDevice ? const PhoneIcon() : null,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            l.resultHeadline(r),
            style: AppType.title1.copyWith(color: c.textPrimary, fontSize: 32),
          ),
          if (r.detection.present) ...<Widget>[
            const SizedBox(height: 8),
            _Meanings(result: r),
          ],
          const SizedBox(height: 6),
          Text(
            <String>[
              if (r.detection.present) l.conditionName(r.part.label, r.completeness.label),
              l.longDate(record.createdAt),
            ].join(' · '),
            style: AppType.subhead.copyWith(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (r.alternativeKeys.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _CouldAlsoBe(alternatives: l.alternativesOf(r)),
          ],
          if (record.note != null &&
              record.note!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Transform.rotate(
              angle: -0.012,
              child: Chunk(
                width: double.infinity,
                color: c.stickers[0],
                radius: 6,
                shadow: 3,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                child: Text(
                  record.note!.trim(),
                  style: AppType.subhead.copyWith(
                    color: const Color(0xFF141414),
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          Chunk(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.resultHowSure,
                            style: AppType.footnote.copyWith(
                              color: c.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            percent(conf),
                            style: AppType.metricLarge.copyWith(
                              color: c.textPrimary,
                              fontSize: 48,
                            ),
                          ),
                          const SizedBox(height: 6),
                          StatusPill(
                            confidenceWord(l, conf),
                            color: confidenceTone(context, conf),
                            filled: true,
                          ),
                        ],
                      ),
                    ),
                    BoneBuddy(
                      size: 104,
                      tilt: 0.1,
                      mood: conf >= 0.7
                          ? BuddyMood.happy
                          : conf >= 0.5
                          ? BuddyMood.thinking
                          : BuddyMood.wow,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ConfidenceBar(
                  value: conf,
                  showValue: false,
                  color: confidenceTone(context, conf),
                  height: 12,
                ),
                if (r.detection.present) ...<Widget>[
                  const SizedBox(height: 14),
                  _ConfidenceSteps(result: r),
                ],
                const SizedBox(height: 10),
                Text(
                  r.detection.present ? l.resultHowSureSteps : l.resultHowSureNone,
                  style: AppType.caption.copyWith(
                    color: c.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The steps behind the overall score, each with its own chance; the weakest
/// one, which sets the score, is in bold.
class _ConfidenceSteps extends StatelessWidget {
  const _ConfidenceSteps({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final List<({String step, double chance})> steps = result.confidenceSteps;
    final double lowest = result.overallConfidence;
    // Ties go to the first step, so only one row is marked.
    final int weakest = steps.indexWhere(
      (({String step, double chance}) s) => s.chance == lowest,
    );

    return Column(
      children: <Widget>[
        for (final (int i, ({String step, double chance}) s) in steps.indexed)
          Padding(
            padding: EdgeInsets.only(bottom: i == steps.length - 1 ? 0 : 7),
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: confidenceTone(context, s.chance),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    switch (s.step) {
                      'detect' => l.resultStepBone,
                      'species' => l.resultHumanOrAnimal,
                      'bone' => l.resultWhichBone,
                      _ => l.resultWhichAnimal,
                    },
                    style: AppType.footnote.copyWith(
                      color: i == weakest ? c.textPrimary : c.textSecondary,
                      fontWeight: i == weakest ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  percent(s.chance),
                  style: AppType.footnote.copyWith(
                    color: i == weakest ? c.textPrimary : c.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Identification, condition, profile and measurement groups.
class ResultSections extends StatelessWidget {
  const ResultSections({super.key, required this.record});

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    final AnalysisResult r = record.result;
    final SettingsController settings = context.watch<SettingsController>();

    if (!r.detection.present) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: EmptyState(
          icon: Icons.search_off_rounded,
          mood: BuddyMood.sad,
          title: context.l10n.resultNoBoneTitle,
          message: context.l10n.resultNoBoneBody,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Reveal(
          delay: Motion.stagger,
          child: _IdentificationGroup(result: r, settings: settings),
        ),
        Reveal(
          delay: Motion.stagger * 2,
          child: _ConditionGroup(result: r),
        ),
        if (r.isHuman)
          Reveal(
            delay: Motion.stagger * 3,
            child: _ProfileGroup(result: r),
          )
        else
          Reveal(
            delay: Motion.stagger * 3,
            child: _TaxonGroup(result: r),
          ),
        if (r.length != null || record.measuredLengthCm != null)
          Reveal(
            delay: Motion.stagger * 4,
            child: _MeasurementGroup(
              estimate: r.length,
              measuredCm: record.measuredLengthCm ?? r.length?.userMeasuredCm,
              check: r.lengthCheck,
              unit: settings.unit,
            ),
          ),
        Reveal(
          delay: Motion.stagger * 5,
          child: _AtlasLink(result: r),
        ),
      ],
    );
  }
}

class _IdentificationGroup extends StatelessWidget {
  const _IdentificationGroup({required this.result, required this.settings});

  final AnalysisResult result;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;

    final List<Scored> candidates = settings.hideLowConfidence
        ? result.boneTypes
              .where(
                (Scored s) =>
                    s.confidence >= settings.confidenceFloor ||
                    s == result.topBone,
              )
              .toList()
        : result.boneTypes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GroupLabel(l.resultIdentification),
        InsetGroup(
          children: <Widget>[
            _MetricRow(
              leading: StatIcon(
                glyph: BoneGlyph.species,
                color: c.sticker(3),
              ),
              label: l.resultHumanOrAnimal,
              value: result.isHuman ? l.animalHuman : l.animalUnnamed,
              confidence: result.species.confidence,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l.resultWhichBone,
                          style: AppType.body.copyWith(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        candidates.length > 1
                            ? l.resultTopGuesses(candidates.length)
                            : l.resultOnlyGuess,
                        style: AppType.footnote.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...candidates.asMap().entries.map((MapEntry<int, Scored> e) {
                    final BoneEntry? bone = boneEntryFor(e.value.label);
                    final bool dim =
                        e.value.confidence < settings.confidenceFloor;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: e.key == candidates.length - 1 ? 0 : 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          bone != null
                              ? BoneSketch(entry: bone, size: 38)
                              : const StatIcon(glyph: BoneGlyph.bone),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ConfidenceBar(
                              label: l.boneName(e.value.label),
                              value: e.value.confidence,
                              color: e.key == 0
                                  ? confidenceTone(context, e.value.confidence)
                                  : c.textTertiary,
                              dimmed: dim,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            _MetricRow(
              leading: StatIcon(glyph: BoneGlyph.part, color: c.sticker(0)),
              label: l.resultWhichPart,
              value: l.partName(result.part.label),
              confidence: result.part.confidence,
            ),
            _MetricRow(
              leading: StatIcon(
                glyph: BoneGlyph.completeness,
                color: c.sticker(4),
              ),
              label: l.resultWholeOrBroken,
              value: l.completenessName(result.completeness.label),
              confidence: result.completeness.confidence,
            ),
          ],
        ),
      ],
    );
  }
}

class _ConditionGroup extends StatelessWidget {
  const _ConditionGroup({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final DamageProfile d = result.damage;
    final List<String> flagged = <String>[for (final String f in d.flagged) l.damageName(f)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GroupLabel(
          l.resultCondition,
          trailing: StatusPill(
            flagged.isEmpty ? l.resultNoMarks : flagged.join(' · '),
            color: flagged.isEmpty ? c.positive : c.caution,
            filled: true,
            icon: flagged.isEmpty
                ? Icons.check_rounded
                : Icons.priority_high_rounded,
            // All three marks can be wider than the screen in German.
            maxLines: 2,
          ),
        ),
        InsetGroup(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                children: d.traits.map((MapEntry<String, double> e) {
                  final bool hit = e.value >= DamageProfile.threshold;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: e.key == 'burn_signs' ? 0 : 15,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        StatIcon(
                          glyph: switch (e.key) {
                            'fracture' => BoneGlyph.fracture,
                            'cut_marks' => BoneGlyph.cutMarks,
                            _ => BoneGlyph.burn,
                          },
                          color: switch (e.key) {
                            'fracture' => c.sticker(3),
                            'cut_marks' => c.sticker(0),
                            _ => c.sticker(1),
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ConfidenceBar(
                            label: l.damageName(e.key),
                            value: e.value,
                            color: hit ? c.caution : c.textTertiary,
                            dimmed: !hit,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        GroupFooter(l.resultMarksFooter(percent(DamageProfile.threshold))),
      ],
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final BiologicalProfile p = result.biological;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GroupLabel(l.resultAgeSex),
        InsetGroup(
          children: <Widget>[
            _MetricRow(
              leading: StatIcon(icon: Icons.cake_rounded, color: c.sticker(0)),
              label: l.resultAgeGroup,
              value: l.ageName(p.ageGroup),
              confidence: p.ageConfidence,
            ),
            _MetricRow(
              leading: StatIcon(icon: Icons.wc_rounded, color: c.sticker(2)),
              label: l.resultSex,
              value: l.sexName(p.sex),
              confidence: p.sexConfidence,
            ),
          ],
        ),
        GroupFooter(l.resultAgeFooter),
      ],
    );
  }
}

class _TaxonGroup extends StatelessWidget {
  const _TaxonGroup({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final Scored a = result.animalSpecies;
    final bool known = a.label != 'none' && a.label != 'unknown';
    final String meaning = l.animalMeaningOf(a.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GroupLabel(l.resultWhichAnimal),
        InsetGroup(
          children: <Widget>[
            if (known)
              _MetricRow(
                leading: StatIcon(
                  icon: Icons.pets_rounded,
                  color: c.sticker(1),
                ),
                label: l.resultClosestMatch,
                value: l.animalName(a.label),
                subtitle: meaning.isEmpty ? null : _sentence(meaning),
                // Chance overall, not just among animals: a 93% bird on a
                // bone that is only 59% animal is a 55% bird.
                confidence: result.animalChance,
              )
            else
              InsetRow(
                leading: StatIcon(
                  icon: Icons.pets_rounded,
                  color: c.sticker(1),
                ),
                title: l.resultClosestMatch,
                value: l.resultUndetermined,
                subtitle: l.resultUndeterminedBody,
              ),
          ],
        ),
        GroupFooter(l.resultAnimalFooter),
      ],
    );
  }
}

class _MeasurementGroup extends StatelessWidget {
  const _MeasurementGroup({
    required this.estimate,
    required this.measuredCm,
    required this.check,
    required this.unit,
  });

  final LengthEstimate? estimate;
  final double? measuredCm;
  final LengthCheck? check;
  final LengthUnit unit;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final String u = l.unitSymbol(unit);
    final LengthEstimate? e = estimate;
    final double? m = measuredCm;
    // Reports saved before reference ranges carry the model's single length
    // estimate; treat a collapsed range as a point and allow some slack.
    final bool point = e != null && (e.maxCm - e.minCm).abs() < 0.5;
    final bool agrees =
        e != null &&
        m != null &&
        (point
            ? (m - e.minCm).abs() <= e.minCm * 0.15
            : m >= e.minCm && m <= e.maxCm);
    final bool typical = e != null && e.fromReference;

    // Why the measurement did or didn't move the identification.
    final LengthCheck? k = check;
    final bool changed = k != null && k.changed;
    final String? reason = m == null ? null : k?.reason;
    String? explanation = reason == null ? null : lengthNote(l, reason);
    final String? photoOnly = k != null && k.changed ? l.photoOnlyHeadline(k) : null;
    if (explanation != null && photoOnly != null) {
      explanation = '$explanation ${l.lenPhotoAlone(photoOnly)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GroupLabel(
          l.resultMeasurements,
          trailing: changed
              ? StatusPill(
                  l.resultLengthChanged,
                  color: c.caution,
                  filled: true,
                  icon: Icons.swap_horiz_rounded,
                )
              : null,
        ),
        InsetGroup(
          children: <Widget>[
            if (e != null)
              InsetRow(
                leading: StatIcon(
                  icon: e.fromReference
                      ? Icons.menu_book_rounded
                      : Icons.auto_awesome_rounded,
                  color: c.sticker(3),
                ),
                title: e.fromReference ? l.resultTypicalLength : l.resultAiEstimate,
                subtitle: e.referenceFor == null
                    ? null
                    : l.resultTypicalFor(referenceName(l, e.referenceFor!)),
                value: point
                    ? l.resultLengthAbout(fixed(unit.from(e.minCm), 1), u)
                    : l.resultLengthRange(
                        fixed(unit.from(e.minCm), 1),
                        fixed(unit.from(e.maxCm), 1),
                        u,
                      ),
              ),
            if (m != null)
              InsetRow(
                leading: StatIcon(
                  icon: Icons.straighten_rounded,
                  color: c.sticker(0),
                ),
                title: l.resultYourMeasurement,
                subtitle: e == null
                    ? null
                    : agrees
                    ? (typical ? l.resultInsideRange : l.resultInsideEstimate)
                    : (typical ? l.resultOutsideRange : l.resultOutsideEstimate),
                value: '${fixed(unit.from(m), 1)} $u',
                trailing: e == null
                    ? null
                    : Icon(
                        agrees
                            ? Icons.check_circle_rounded
                            : Icons.error_rounded,
                        size: 20,
                        color: agrees ? c.positive : c.caution,
                      ),
              ),
          ],
        ),
        if (explanation != null) GroupFooter(explanation),
      ],
    );
  }
}

class _AtlasLink extends StatelessWidget {
  const _AtlasLink({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final Scored? top = result.topBone;
    if (top == null) return const SizedBox.shrink();
    final BoneEntry? entry = boneEntryFor(top.label);
    if (entry == null) return const SizedBox.shrink();
    final AppLocalizations l = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GroupLabel(l.resultReference),
        InsetGroup(
          separatorIndent: 68,
          children: <Widget>[
            InsetRow(
              minHeight: 60,
              leading: BoneSketch(entry: entry),
              title: l.atlas(entry).name,
              subtitle: l.resultAtlasSubtitle(l.regionName(entry.region)),
              chevron: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BoneDetailScreen(entry: entry),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Sticker icon, label on the left, value on the right, confidence bar under.
class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.leading,
    required this.label,
    required this.value,
    required this.confidence,
    this.subtitle,
  });

  final Widget leading;
  final String label;
  final String value;
  final double confidence;

  /// A line under the label, e.g. what an animal group means.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 12),
          Expanded(child: _metric(c, context)),
        ],
      ),
    );
  }

  Widget _metric(AppColors c, BuildContext context) {
    final TextStyle labelStyle = AppType.body.copyWith(
      color: c.textPrimary,
      fontWeight: FontWeight.w600,
    );
    final TextStyle valueStyle = AppType.metric.copyWith(color: c.textPrimary);
    final Widget score = SizedBox(
      width: 46,
      child: Text(
        percent(confidence),
        textAlign: TextAlign.end,
        style: AppType.metric.copyWith(
          color: c.textPrimary,
          fontSize: 14,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            const double valueMax = 150;
            final double room = box.maxWidth - 8 - 46;
            final double valueWidth =
                TextFit.width(context, value, valueStyle).clamp(0.0, valueMax);
            // The value sits beside the label while both still fit without
            // a word broken in two; a long German or Arabic pair puts the
            // value under the label instead.
            final bool beside =
                TextFit.longestWord(context, label, labelStyle) + 8 + valueWidth <= room &&
                    TextFit.longestWord(context, value, valueStyle) <= valueMax;
            if (!beside) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(label, style: labelStyle),
                        const SizedBox(height: 2),
                        Text(value, style: valueStyle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  score,
                ],
              );
            }
            return Row(
              children: <Widget>[
                Expanded(child: Text(label, style: labelStyle)),
                const SizedBox(width: 8),
                // A long value wraps past this width rather than crowding
                // the label.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: valueMax),
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: valueStyle,
                  ),
                ),
                const SizedBox(width: 8),
                score,
              ],
            );
          },
        ),
        if (subtitle != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppType.footnote.copyWith(color: c.textSecondary, height: 1.35),
          ),
        ],
        const SizedBox(height: 9),
        ConfidenceBar(
          value: confidence,
          showValue: false,
          height: 6,
          color: confidenceTone(context, confidence),
        ),
      ],
    );
  }
}

String _sentence(String s) => '${s[0].toUpperCase()}${s.substring(1)}.';

/// What the scientific words in the headline mean, one line each:
/// "Femur: the thigh bone", "Cervid: the deer family: deer, elk...".
class _Meanings extends StatelessWidget {
  const _Meanings({required this.result});

  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final Scored? bone = result.topBone;
    final String? boneLine = bone == null ? null : l.boneMeaningOf(bone.label);
    final String? taxon = result.isHuman ? null : result.animalSpecies.label;
    final String animalLine = taxon == null ? '' : l.animalMeaningOf(taxon);
    final List<(String, String)> lines = <(String, String)>[
      if (bone != null && boneLine != null) (l.boneName(bone.label), boneLine),
      if (taxon != null && animalLine.isNotEmpty) (l.animalName(taxon), animalLine),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (final (String word, String meaning) in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$word: ',
                    style: AppType.subhead.copyWith(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: meaning),
                ],
              ),
              style: AppType.subhead.copyWith(color: c.textSecondary, height: 1.35),
            ),
          ),
      ],
    );
  }
}

/// The safeguard for a shaky answer: what else it could be, with the chance
/// of each, so a wrong headline never reads as certain.
class _CouldAlsoBe extends StatelessWidget {
  const _CouldAlsoBe({required this.alternatives});

  final List<(String, double)> alternatives;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Chunk(
      width: double.infinity,
      color: c.surfaceSunken,
      radius: 14,
      shadow: 3,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.help_outline_rounded, size: 17, color: c.textPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  context.l10n.resultCouldAlsoBe,
                  style: AppType.footnote.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final (String what, double chance) in alternatives)
                StatusPill('$what · ${percent(chance)}', color: c.caution, filled: true),
            ],
          ),
        ],
      ),
    );
  }
}

/// Standing caveat shown at the bottom of every report.
class ResultDisclaimer extends StatelessWidget {
  const ResultDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 15, color: c.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.resultDisclaimer,
              style: AppType.caption.copyWith(
                color: c.textTertiary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
