import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// [wink] winks one eye now and then instead of blinking both.
enum BuddyMood { happy, wow, thinking, sad, wink }

/// The classic cartoon dog-bone outline, fitted to [r]: a shaft with a pair of
/// knobs at each end. [shaft] is the shaft thickness as a fraction of height.
Path cartoonBonePath(Rect r, {double shaft = 0.44, double knob = 0.25}) {
  final double h = r.height;
  final double k = h * knob;
  final double top = r.top + h * (0.5 - shaft / 2);
  final Path shaftPath = Path()
    ..addRRect(RRect.fromLTRBR(
      r.left + k,
      top,
      r.right - k,
      top + h * shaft,
      Radius.circular(h * 0.05),
    ));

  Path knobs = Path();
  for (final double x in <double>[r.left + k, r.right - k]) {
    for (final double y in <double>[r.top + k, r.bottom - k]) {
      knobs = Path.combine(
        PathOperation.union,
        knobs,
        Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: k)),
      );
    }
  }
  return Path.combine(PathOperation.union, shaftPath, knobs);
}

/// Ossia's mascot: a googly-eyed cartoon bone. Used wherever the app wants to
/// talk to the user rather than just show them data.
class BoneBuddy extends StatefulWidget {
  const BoneBuddy({
    super.key,
    this.size = 120,
    this.mood = BuddyMood.happy,
    this.animate = true,
    this.tilt = -0.08,
    this.look = Offset.zero,
  });

  /// Width; height is half of it.
  final double size;
  final BuddyMood mood;

  /// Gentle idle bob and wobble.
  final bool animate;
  final double tilt;

  /// Pupil direction, each axis -1..1. Positive x looks toward the end of
  /// the line (right in left-to-right languages), so a buddy looking at the
  /// text beside it still does when the layout mirrors.
  final Offset look;

  @override
  State<BoneBuddy> createState() => _BoneBuddyState();
}

class _BoneBuddyState extends State<BoneBuddy>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void didUpdateWidget(BoneBuddy old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_c.isAnimating) _c.repeat();
    if (!widget.animate && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          final double p = _c.value * 2 * math.pi;
          final double bob = widget.animate ? math.sin(p) * widget.size * 0.03 : 0;
          final double wobble = widget.animate ? math.sin(p * 2) * 0.035 : 0;
          // A quick blink once per loop.
          final bool blink = widget.animate && _c.value > 0.92 && _c.value < 0.96;
          final Offset look = widget.mood == BuddyMood.thinking
              ? Offset(math.sin(p) * 0.6, -0.7)
              : Directionality.of(context) == TextDirection.rtl
                  ? Offset(-widget.look.dx, widget.look.dy)
                  : widget.look;
          return Transform.translate(
            offset: Offset(0, bob),
            child: Transform.rotate(
              angle: widget.tilt + wobble,
              child: CustomPaint(
                size: Size(widget.size, widget.size * 0.5),
                painter: _BuddyPainter(
                  mood: widget.mood,
                  ink: const Color(0xFF141414),
                  shadow: c.shadow,
                  blink: blink,
                  look: look,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BuddyPainter extends CustomPainter {
  _BuddyPainter({
    required this.mood,
    required this.ink,
    required this.shadow,
    required this.blink,
    required this.look,
  });

  final BuddyMood mood;
  final Color ink;
  final Color shadow;
  final bool blink;
  final Offset look;

  static const Color _bone = Color(0xFFFFF8EA);
  static const Color _boneShade = Color(0xFFF0DFC2);
  static const Color _blush = Color(0xFFFF9EC7);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double stroke = math.max(2.0, w * 0.026);
    final Rect body = Rect.fromLTWH(stroke, stroke, w - stroke * 2, h - stroke * 2);
    final Path bone = cartoonBonePath(body);

    // Hard sticker shadow.
    canvas.drawPath(
      bone.shift(Offset(w * 0.025, w * 0.03)),
      Paint()..color = shadow,
    );
    canvas.drawPath(bone, Paint()..color = _bone);

    // Shading along the lower edge, clipped to the silhouette.
    canvas.save();
    canvas.clipPath(bone);
    canvas.drawPath(
      bone.shift(Offset(0, h * 0.13)),
      Paint()
        ..color = _boneShade
        ..blendMode = BlendMode.srcOver,
    );
    canvas.drawPath(bone.shift(Offset(0, -h * 0.02)), Paint()..color = _bone);
    canvas.restore();

    canvas.drawPath(
      bone,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final Offset centre = Offset(w / 2, h * 0.5);
    final double eyeR = h * 0.1;
    final double eyeDx = w * 0.075;
    final Offset le = centre + Offset(-eyeDx, -h * 0.06);
    final Offset re = centre + Offset(eyeDx, -h * 0.06);
    final Paint inkFill = Paint()..color = ink;
    final Paint inkLine = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 0.8
      ..strokeCap = StrokeCap.round;

    void eye(Offset o, {bool closed = false}) {
      if (closed) {
        canvas.drawArc(
          Rect.fromCircle(center: o, radius: eyeR * 0.8),
          math.pi * 0.15,
          math.pi * 0.7,
          false,
          inkLine,
        );
        return;
      }
      canvas.drawCircle(o, eyeR, Paint()..color = Colors.white);
      canvas.drawCircle(o, eyeR, inkLine..strokeWidth = stroke * 0.6);
      final double pr = eyeR * (mood == BuddyMood.wow ? 0.38 : 0.52);
      final Offset po = o + Offset(look.dx, look.dy) * (eyeR - pr - 0.5);
      canvas.drawCircle(po, pr, inkFill);
      canvas.drawCircle(po + Offset(-pr * 0.35, -pr * 0.35), pr * 0.28,
          Paint()..color = Colors.white);
      inkLine.strokeWidth = stroke * 0.8;
    }

    // A blink closes both eyes; a wink is a blink of one eye only.
    eye(le, closed: blink && mood != BuddyMood.wink);
    eye(re, closed: blink);

    // Cheeks.
    final Paint blush = Paint()..color = _blush.withValues(alpha: 0.75);
    for (final double s in <double>[-1, 1]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: centre + Offset(s * w * 0.14, h * 0.07),
          width: h * 0.13,
          height: h * 0.075,
        ),
        blush,
      );
    }

    final Offset m = centre + Offset(0, h * 0.11);
    final double mw = w * 0.05;
    switch (mood) {
      case BuddyMood.happy:
      case BuddyMood.wink:
        final Path smile = Path()
          ..moveTo(m.dx - mw, m.dy - h * 0.02)
          ..quadraticBezierTo(m.dx, m.dy + h * 0.09, m.dx + mw, m.dy - h * 0.02)
          ..close();
        canvas.drawPath(smile, inkFill);
        canvas.drawPath(smile, inkLine..strokeJoin = StrokeJoin.round);
      case BuddyMood.wow:
        canvas.drawOval(
          Rect.fromCenter(center: m + Offset(0, h * 0.01), width: mw * 0.9, height: h * 0.1),
          inkFill,
        );
      case BuddyMood.thinking:
        final Path squiggle = Path()..moveTo(m.dx - mw, m.dy);
        squiggle.cubicTo(m.dx - mw * 0.4, m.dy - h * 0.04, m.dx + mw * 0.1,
            m.dy + h * 0.04, m.dx + mw, m.dy - h * 0.01);
        canvas.drawPath(squiggle, inkLine);
      case BuddyMood.sad:
        final Path frown = Path()
          ..moveTo(m.dx - mw, m.dy + h * 0.04)
          ..quadraticBezierTo(m.dx, m.dy - h * 0.05, m.dx + mw, m.dy + h * 0.04);
        canvas.drawPath(frown, inkLine);
    }
  }

  @override
  bool shouldRepaint(_BuddyPainter old) =>
      old.mood != mood ||
      old.blink != blink ||
      old.look != look ||
      old.shadow != shadow;
}
