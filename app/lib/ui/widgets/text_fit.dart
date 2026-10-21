import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Measures text the way a [Text] in [context] would draw it, so a layout can
/// make room for a long translation instead of squeezing it.
abstract final class TextFit {
  /// Width of [text] on a single line.
  static double width(BuildContext context, String text, TextStyle style) =>
      _measure(context, text, style, double.infinity, null, (TextPainter p) => p.maxIntrinsicWidth);

  /// Width of the widest part of [text] that cannot break across lines: the
  /// narrowest it can wrap to without splitting a word.
  static double longestWord(BuildContext context, String text, TextStyle style) =>
      _measure(context, text, style, double.infinity, null, (TextPainter p) => p.minIntrinsicWidth);

  /// Height of [text] wrapped to [maxWidth], over at most [maxLines] lines.
  static double height(
    BuildContext context,
    String text,
    TextStyle style, {
    required double maxWidth,
    int? maxLines,
  }) =>
      _measure(context, text, style, maxWidth, maxLines, (TextPainter p) => p.height);

  static double _measure(
    BuildContext context,
    String text,
    TextStyle style,
    double maxWidth,
    int? maxLines,
    double Function(TextPainter) read,
  ) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final double v = read(p);
    p.dispose();
    return v;
  }
}

/// One line of title text in a bar of fixed height. Under large system text it
/// shrinks back toward the normal size before it ends in "…", so a short title
/// ("Deine Sammlung") stays whole and only a long typed name is cut.
class FittedTitle extends StatelessWidget {
  const FittedTitle(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        TextScaler scaler = MediaQuery.textScalerOf(context);
        final double width = TextFit.width(context, text, style);
        if (width > box.maxWidth) {
          final double size = DefaultTextStyle.of(context).style.merge(style).fontSize ?? 14;
          final double scale = scaler.scale(size) / size;
          scaler = TextScaler.linear(
              math.max(math.min(scale, 1.0), scale * (box.maxWidth - 1) / width));
        }
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textScaler: scaler,
          style: style,
        );
      },
    );
  }
}
