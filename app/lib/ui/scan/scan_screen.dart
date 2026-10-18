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
                    height: 214,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: recent.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int i) =>
                          _FindCard(record: recent[i], index: i),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          // The wordmark is a logo: same letters and the dot on its right in
          // every language.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'ossia',
                  style: AppType.scaleFor('en').mega.copyWith(color: c.textPrimary),
                ),
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
          ),
          const SizedBox(width: 10),
          // Long status words shrink the pill, never push the globe off.
          const Expanded(
            child: Align(alignment: AlignmentDirectional.centerEnd, child: LinkPill()),
          ),
          const SizedBox(width: 8),
          const GlobeButton(),
        ],
      ),
    );
  }
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
    Widget row(int first) => Row(
          children: <Widget>[
            Expanded(child: _TipCard(index: first, tip: tips[first])),
            const SizedBox(width: 6),
            Expanded(child: _TipCard(index: first + 1, tip: tips[first + 1])),
          ],
        );

    // The cards' hard shadow reserves space on their right, so the right
    // padding is trimmed to keep the grid optically centred.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      child: Column(
        children: <Widget>[
          row(0),
          const SizedBox(height: 8),
          row(2),
        ],
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

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (Widget icon, String title, String body) = tip;
    return Transform.rotate(
      angle: index == 0 || index == 3 ? -0.015 : 0.015,
      child: Chunk(
        height: 150,
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
            // A title a little long for the card shrinks rather than losing
            // its end.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                title,
                maxLines: 1,
                style: AppType.headline.copyWith(
                  color: const Color(0xFF141414),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(
                color: const Color(0xFF141414).withValues(alpha: 0.75),
                height: 1.3,
              ),
            ),
          ],
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
  const _FindCard({required this.record, required this.index});

  final AnalysisRecord record;
  final int index;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AnalysisResult r = record.result;
    final bool flagged = r.damage.flagged.isNotEmpty;

    return Chunk(
      width: 158,
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
                Text(
                  context.l10n.recordTitle(record),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.headline.copyWith(
                    color: c.textPrimary,
                    fontSize: 14.5,
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
