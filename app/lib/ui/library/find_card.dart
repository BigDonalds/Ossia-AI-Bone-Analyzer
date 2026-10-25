import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../data/models/analysis.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../widgets/primitives.dart';
import '../widgets/specimen_image.dart';
import '../widgets/text_fit.dart';
import '../widgets/wide.dart';
import 'record_detail_screen.dart';

/// A saved find: its photo, its score and its name. A fixed [width] in a row
/// that scrolls sideways; null fills a grid cell.
class FindCard extends StatelessWidget {
  const FindCard({
    super.key,
    required this.record,
    required this.index,
    required this.titleLines,
    required this.lineHeight,
    this.width = rowWidth,
  });

  final AnalysisRecord record;
  final int index;

  /// Lines kept for the title: the same on every card in the row.
  final int titleLines;

  /// Height of one title line, also the same on every card.
  final double lineHeight;

  final double? width;

  /// A card's width in a row.
  static const double rowWidth = 158;

  /// Columns in a grid [room] wide: cards about 190 wide, 8 apart.
  static int columnsIn(double room) => math.max(2, ((room + 8) / (190 + 8)).round());

  /// A card's width when [columns] of them share [room].
  static double widthIn(double room, int columns) =>
      (room - (columns - 1) * 8) / columns - Chunky.shadow;

  /// The title's width on a card [width] wide: less its outline and padding.
  static double titleRoom(double width) => width - Chunky.border * 2 - 20;

  /// Lines kept for [titles] on cards [width] wide: two when any needs them.
  static int linesFor(BuildContext context, List<String> titles, TextStyle style, double width) =>
      titles.any((String t) => TextFit.width(context, t, style) > titleRoom(width)) ? 2 : 1;

  /// A card's height, its shadow included, when it is [width] wide: the photo
  /// stays about square and the info strip below it keeps its size.
  static double height(double width, int titleLines, double lineHeight) =>
      width + 56 + (titleLines - 1) * lineHeight;

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
      width: width,
      onTap: () => Navigator.of(context).push(
        WidePageRoute<void>(
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
