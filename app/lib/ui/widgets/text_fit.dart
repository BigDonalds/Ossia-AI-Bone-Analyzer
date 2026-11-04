import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Measures text the way a [Text] in [context] would draw it, so a layout can
/// make room for a long translation instead of squeezing it.
abstract final class TextFit {
  /// The text size the layouts hold as they are drawn. Above it they make
  /// room ([large]), and tiny labels with truly no room stay here ([tiny]).
  static const double cap = 1.35;

  /// The phone's text size as a multiple of normal.
  static double scale(BuildContext context) => MediaQuery.textScalerOf(context).scale(100) / 100;

  /// True above [cap]: fixed sizes give way to the words.
  static bool large(BuildContext context) => scale(context) > cap;

  /// The phone's text size held to [cap].
  static TextScaler tiny(BuildContext context) =>
      MediaQuery.textScalerOf(context).clamp(maxScaleFactor: cap);

  /// What to draw a heading in, in a line [room] wide: the phone's text size,
  /// unless a single word of [text] is wider than the whole line. That word
  /// can't wrap, so the heading comes down just enough to fit it, never below
  /// normal size, instead of breaking the word in two.
  static TextScaler heading(BuildContext context, String text, TextStyle style, double room) {
    final TextScaler phone = MediaQuery.textScalerOf(context);
    if (!large(context)) return phone;
    final double word = longestWord(context, text, style);
    if (word <= room) return phone;
    return TextScaler.linear(math.max(1.0, scale(context) * (room - 1) / word));
  }

  /// Width of [text] on a single line.
  static double width(BuildContext context, String text, TextStyle style, {TextScaler? scaler}) =>
      _measure(context, text, style, double.infinity, null, scaler, (TextPainter p) => p.maxIntrinsicWidth);

  /// Width of the widest part of [text] that cannot break across lines: the
  /// narrowest it can wrap to without splitting a word.
  static double longestWord(BuildContext context, String text, TextStyle style, {TextScaler? scaler}) =>
      _measure(context, text, style, double.infinity, null, scaler, (TextPainter p) => p.minIntrinsicWidth);

  /// Height of [text] wrapped to [maxWidth], over at most [maxLines] lines.
  static double height(
    BuildContext context,
    String text,
    TextStyle style, {
    required double maxWidth,
    int? maxLines,
    TextScaler? scaler,
  }) =>
      _measure(context, text, style, maxWidth, maxLines, scaler, (TextPainter p) => p.height);

  static double _measure(
    BuildContext context,
    String text,
    TextStyle style,
    double maxWidth,
    int? maxLines,
    TextScaler? scaler,
    double Function(TextPainter) read,
  ) {
    final TextPainter p = TextPainter(
      text: TextSpan(text: text, style: DefaultTextStyle.of(context).style.merge(style)),
      textDirection: Directionality.of(context),
      textScaler: scaler ?? MediaQuery.textScalerOf(context),
      locale: Localizations.maybeLocaleOf(context),
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final double v = read(p);
    p.dispose();
    return v;
  }
}

/// A title in a bar or at the top of a page. It keeps to one line, shrinking
/// back toward the normal size under a raised text size before it ends in "…",
/// so a short title ("Deine Sammlung") stays whole and only a long typed name
/// is cut. Under [TextFit.large] text it wraps instead, and the bar grows
/// ([heightIn]).
class FittedTitle extends StatelessWidget {
  const FittedTitle(this.text, {super.key, required this.style});

  final String text;
  final TextStyle style;

  /// Height of the title in a bar [room] wide, for bars that make room for it.
  static double heightIn(BuildContext context, String text, TextStyle style, double room) =>
      TextFit.large(context)
          ? TextFit.height(
              context,
              text,
              style,
              maxWidth: room,
              scaler: TextFit.heading(context, text, style, room),
            )
          : TextFit.height(context, text, style, maxWidth: room, maxLines: 1);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        if (TextFit.large(context)) {
          return Text(
            text,
            textScaler: TextFit.heading(context, text, style, box.maxWidth),
            style: style,
          );
        }
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

/// A big heading in running content. Wraps like any text, and under large text
/// only comes down from the phone's text size for a word too wide for the line
/// ([TextFit.heading]).
class HeadingText extends StatelessWidget {
  const HeadingText(this.text, {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    if (!TextFit.large(context)) return Text(text, textAlign: textAlign, style: style);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) => Text(
        text,
        textAlign: textAlign,
        textScaler: TextFit.heading(context, text, style, box.maxWidth),
        style: style,
      ),
    );
  }
}
