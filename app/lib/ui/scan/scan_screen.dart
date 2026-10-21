import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../data/history_store.dart';
import '../../data/models/analysis.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../language/language_picker.dart';
import '../library/record_detail_screen.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/primitives.dart';
import '../widgets/specimen_image.dart';
import '../widgets/text_fit.dart';
import '../status/link_pill.dart';
import 'camera_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final SettingsController settings = context.watch<SettingsController>();
    final HistoryStore history = context.watch<HistoryStore>();
    final List<AnalysisRecord> recent = history.records.take(8).toList();
    final double top = MediaQuery.paddingOf(context).top;
    final AppLocalizations l = context.l10n;
    // A title too long for one line (German, or a name the user gave) gets a
    // second on every card, and the row grows by that line so the photos
    // keep their size.
    final TextStyle titleStyle = _FindCard.titleStyle(c);
    final List<String> titles = <String>[for (final AnalysisRecord r in recent) l.recordTitle(r)];
    final int titleLines =
        titles.any((String t) => TextFit.width(context, t, titleStyle) > _FindCard.titleRoom)
            ? 2
            : 1;
    final double lineHeight = _FindCard.measureLine(context, titleStyle, titles);

    return Scaffold(
      backgroundColor: c.canvas,
      body: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: EdgeInsets.only(top: top + 10, bottom: 140),
        children: <Widget>[
          Reveal(child: _Header(settings: settings)),
          const SizedBox(height: 18),
          const Reveal(
            delay: Motion.stagger,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _HeroCard(),
            ),
          ),
          Reveal(
            delay: Motion.stagger * 2,
            child: GroupLabel(l.scanTipsHeader),
          ),
          Reveal(delay: Motion.stagger * 2, child: const _TipGrid()),
          Reveal(
            delay: Motion.stagger * 3,
            child: GroupLabel(
              l.scanRecentFinds,
              trailing: history.records.isEmpty
                  ? null
                  : StatusPill(l.scanSavedCount(history.records.length),
                      color: c.stickers[1], filled: true),
            ),
          ),
          Reveal(
            delay: Motion.stagger * 3,
            child: recent.isEmpty
                ? const _NoFinds()
                : SizedBox(
                    height: 214 + (titleLines - 1) * lineHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recent.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int i) => _FindCard(
                        record: recent[i],
                        index: i,
                        titleLines: titleLines,
                        lineHeight: lineHeight,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TextStyle markStyle = AppType.scaleFor('en').mega.copyWith(color: c.textPrimary);
    // The wordmark is a logo: same letters and the dot on its right in every
    // language.
    final Widget wordmark = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('ossia', style: markStyle),
          Container(
            margin: const EdgeInsets.only(left: 3, top: 14),
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              border: Border.all(color: c.ink, width: 2),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          // The status pill sits between the wordmark and the globe while its
          // longest label fits there, without its chevron if need be. With
          // large text or a long translation it takes its own line below.
          final double room = box.maxWidth -
              TextFit.width(context, 'ossia', markStyle) -
              14 -
              10 -
              8 -
              _globeWidth;
          final double label = LinkPill.widestLabel(context);
          final bool chevron = label + LinkPill.chrome(chevron: true) <= room;
          final bool beside = chevron || label + LinkPill.chrome(chevron: false) <= room;
          if (!beside) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    wordmark,
                    const Spacer(),
                    const GlobeButton(),
                  ],
                ),
                const SizedBox(height: 6),
                const LinkPill(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              wordmark,
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: LinkPill(chevron: chevron),
                ),
              ),
              const SizedBox(width: 8),
              const GlobeButton(),
            ],
          );
        },
      ),
    );
  }

  /// [GlobeButton]'s footprint: the button, its shadow and its badge.
  static const double _globeWidth = 44 + 3 + 5;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    return Chunk(
      color: c.accent,
      radius: 28,
      shadow: 6,
      clip: false,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  l.scanHeroTitle,
                  style: AppType.title1.copyWith(
                    color: c.onAccent,
                    fontSize: 31,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.scanHeroBody,
            style: AppType.subhead.copyWith(
              color: c.onAccent.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: EdgeInsetsDirectional.only(end: 4),
              child: BoneBuddy(size: 150, mood: BuddyMood.wink, tilt: 0.12),
            ),
          ),
          const SizedBox(height: 10),
          PrimaryButton(
            label: l.scanSnap,
            icon: Icons.camera_alt_rounded,
            tone: const Color(0xFF141414),
            height: 60,
            onTap: () => openBoneCamera(context),
          ),
          const SizedBox(height: 8),
          SecondaryButton(
            label: l.scanUpload,
            icon: Icons.photo_library_rounded,
            onTap: () => pickBoneFromLibrary(context),
          ),
        ],
      ),
    );
  }
}

class _TipGrid extends StatelessWidget {
  const _TipGrid();

  static const Color _ink = Color(0xFF141414);

  static const List<Widget> _icons = <Widget>[
    _BoneOnSheetIcon(),
    Icon(Icons.wb_sunny_rounded, size: 18, color: _ink),
    Icon(Icons.straighten_rounded, size: 18, color: _ink),
    Icon(Icons.threesixty_rounded, size: 18, color: _ink),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final List<(Widget, String, String)> tips = <(Widget, String, String)>[
      (_icons[0], l.tipBackgroundTitle, l.tipBackgroundBody),
      (_icons[1], l.tipLightTitle, l.tipLightBody),
      (_icons[2], l.tipLengthTitle, l.tipLengthBody),
      (_icons[3], l.tipAnglesTitle, l.tipAnglesBody),
    ];
    // Both cards in a row take the taller one's height, so a long German tip
    // grows its pair together.
    Widget row(int first) => IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(child: _TipCard(index: first, tip: tips[first])),
              const SizedBox(width: 6),
              Expanded(child: _TipCard(index: first + 1, tip: tips[first + 1])),
            ],
          ),
        );

    // The cards' hard shadow reserves space on their right, so the right
    // padding is trimmed to keep the grid optically centred.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          // One card under another when a word of a tip is too long for half
          // the width (large text), rather than splitting it.
          final double room = (box.maxWidth - 6) / 2 - 26 - Chunky.border * 2 - Chunky.shadow;
          final bool narrow = tips.any(((Widget, String, String) t) =>
              TextFit.longestWord(context, t.$2, _TipCard.titleStyle) > room ||
              TextFit.longestWord(context, t.$3, _TipCard.bodyStyle) > room);
          return Column(
            children: narrow
                ? <Widget>[
                    for (int i = 0; i < tips.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 8),
                      IntrinsicHeight(child: _TipCard(index: i, tip: tips[i])),
                    ],
                  ]
                : <Widget>[
                    row(0),
                    const SizedBox(height: 8),
                    row(2),
                  ],
          );
        },
      ),
    );
  }
}

/// A bone lying on a blank sheet — the "plain background" tip, drawn.
class _BoneOnSheetIcon extends StatelessWidget {
  const _BoneOnSheetIcon();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size.square(22), painter: _BoneOnSheetPainter());
}

class _BoneOnSheetPainter extends CustomPainter {
  const _BoneOnSheetPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const Color ink = Color(0xFF141414);
    final double u = size.width / 22;
    canvas.save();
    canvas.scale(u);

    // The sheet, laid slightly askew.
    canvas.save();
    canvas.translate(11, 11);
    canvas.rotate(-0.12);
    canvas.translate(-11, -11);
    final RRect sheet =
        RRect.fromLTRBR(1.5, 4, 20.5, 18, const Radius.circular(2.5));
    canvas.drawRRect(sheet, Paint()..color = const Color(0xFFF1F1F4));
    canvas.drawRRect(
      sheet,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    canvas.restore();

    // The bone resting on it.
    canvas.save();
    canvas.translate(11, 11);
    canvas.rotate(-0.35);
    canvas.translate(-11, -11);
    canvas.drawPath(
      cartoonBonePath(const Rect.fromLTRB(4.5, 8, 17.5, 14.2),
          shaft: 0.46, knob: 0.26),
      Paint()..color = ink,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoneOnSheetPainter old) => false;
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.index, required this.tip});

  final int index;
  final (Widget, String, String) tip;

  static TextStyle get titleStyle => AppType.headline.copyWith(
        color: const Color(0xFF141414),
        fontWeight: FontWeight.w800,
      );

  static TextStyle get bodyStyle => AppType.caption.copyWith(
        color: const Color(0xFF141414).withValues(alpha: 0.75),
        height: 1.3,
      );

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (Widget icon, String title, String body) = tip;
    return Transform.rotate(
      angle: index == 0 || index == 3 ? -0.015 : 0.015,
      child: ConstrainedBox(
        // 150 tall at least, plus the shadow; taller when the words need it.
        constraints: const BoxConstraints(minHeight: 150 + Chunky.shadow),
        child: Chunk(
          color: c.sticker(index),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF141414), width: 1.8),
                ),
                child: Center(child: icon),
              ),
              const Spacer(),
              const SizedBox(height: 8),
              Text(title, style: titleStyle),
              const SizedBox(height: 2),
              Text(body, style: bodyStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFinds extends StatelessWidget {
  const _NoFinds();

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      child: Chunk(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 14, 16, 14),
        child: Row(
          children: <Widget>[
            const BoneBuddy(size: 76, mood: BuddyMood.sad, animate: false),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.scanNoFinds,
                    style: AppType.headline.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.scanNoFindsBody,
                    style: AppType.footnote.copyWith(color: c.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FindCard extends StatelessWidget {
  const _FindCard({
    required this.record,
    required this.index,
    required this.titleLines,
    required this.lineHeight,
  });

  final AnalysisRecord record;
  final int index;

  /// Lines kept for the title: the same on every card in the row.
  final int titleLines;

  /// Height of one title line, also the same on every card.
  final double lineHeight;

  static const double _width = 158;

  /// The title's width: the card less its outline and padding.
  static const double titleRoom = _width - Chunky.border * 2 - 20;

  static TextStyle titleStyle(AppColors c) =>
      AppType.headline.copyWith(color: c.textPrimary, fontSize: 14.5);

  /// The tallest line among [titles], at least that of "Ag": Arabic sits a
  /// little taller than Latin type.
  static double measureLine(BuildContext context, TextStyle style, List<String> titles) =>
      <String>['Ag', ...titles]
          .map((String t) => TextFit.height(context, t, style, maxWidth: double.infinity, maxLines: 1))
          .reduce(math.max);

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AnalysisResult r = record.result;
    final bool flagged = r.damage.flagged.isNotEmpty;

    final TextStyle title = titleStyle(c);
    return Chunk(
      width: _width,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RecordDetailScreen(recordId: record.id),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SpecimenImage(path: record.imagePath, fit: BoxFit.cover),
                PositionedDirectional(
                  top: 8,
                  start: 8,
                  child: StatusPill(
                    percent(r.overallConfidence),
                    color: c.sticker(index),
                    filled: true,
                  ),
                ),
                if (flagged)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c.caution,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF141414), width: 1.6),
                      ),
                      child: const Icon(Icons.priority_high_rounded,
                          size: 16, color: Color(0xFF141414)),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.ink, width: Chunky.border)),
            ),
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: titleLines * lineHeight,
                  child: Text(
                    context.l10n.recordTitle(record),
                    maxLines: titleLines,
                    overflow: TextOverflow.ellipsis,
                    style: title,
                  ),
                ),
                Text(
                  context.l10n.relativeTime(record.createdAt),
                  style: AppType.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
