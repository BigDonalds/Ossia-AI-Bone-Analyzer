import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import 'bone_buddy.dart';

/// Cartoon icons for the categories on a report. Each one always looks the
/// same, whatever the result, so the picture itself says what the row is
/// about.
enum BoneGlyph {
  /// A plain bone, for elements with no Atlas drawing.
  bone,

  /// Human figure next to a paw print.
  species,

  /// Bone with one end highlighted and an arrow pointing at it.
  part,

  /// Half a bone, with the missing half drawn as a dashed outline.
  completeness,

  /// Cracked bone with "ouch" lines.
  fracture,

  /// Bone with slash marks across it.
  cutMarks,

  /// Bone with a flame over it.
  burn,
}

/// Small sticker tile in front of a result row: either a Material [icon] or a
/// cartoon [glyph].
class StatIcon extends StatelessWidget {
  const StatIcon({
    super.key,
    this.icon,
    this.glyph,
    this.color,
    this.size = 38,
  }) : assert(icon != null || glyph != null);

  final IconData? icon;
  final BoneGlyph? glyph;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? c.sticker(0),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: c.ink, width: 1.8),
        boxShadow: <BoxShadow>[
          BoxShadow(color: c.shadow, offset: const Offset(2, 2)),
        ],
      ),
      child: glyph != null
          ? CustomPaint(painter: _GlyphPainter(glyph!))
          : Icon(icon, size: size * 0.56, color: const Color(0xFF141414)),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.glyph);

  final BoneGlyph glyph;

  static const Color _ink = Color(0xFF141414);
  static const Color _bone = Color(0xFFFFF8EA);
  static const Color _hot = Color(0xFFFF5FA8);

  Paint _stroke(double width) => Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100);
    // Pull the drawing in from the tile's outline.
    canvas.translate(50, 50);
    canvas.scale(0.84);
    canvas.translate(-50, -50);

    final Path bone = cartoonBonePath(
      glyph == BoneGlyph.burn
          ? const Rect.fromLTRB(12, 50, 88, 86)
          : const Rect.fromLTRB(10, 32, 90, 70),
      shaft: 0.46,
      knob: 0.26,
    );

    switch (glyph) {
      case BoneGlyph.bone:
        _fill(canvas, bone);
        _eyes(canvas, const Offset(50, 51));

      case BoneGlyph.species:
        _species(canvas);

      case BoneGlyph.part:
        canvas.drawPath(bone, Paint()..color = _bone);
        canvas.save();
        canvas.clipPath(bone);
        canvas.drawRect(const Rect.fromLTRB(60, 0, 100, 100),
            Paint()..color = _hot.withValues(alpha: 0.9));
        canvas.restore();
        canvas.drawPath(bone, _stroke(6));
        canvas.drawPath(
          Path()
            ..moveTo(78, 28)
            ..lineTo(70, 14)
            ..lineTo(86, 14)
            ..close(),
          Paint()..color = _ink,
        );

      case BoneGlyph.completeness:
        // Solid left half, dashed ghost where the rest should be.
        final Path clip = Path()
          ..moveTo(0, 0)
          ..lineTo(50, 0)
          ..lineTo(46, 42)
          ..lineTo(55, 50)
          ..lineTo(45, 58)
          ..lineTo(50, 100)
          ..lineTo(0, 100)
          ..close();
        final Path ghost = Path.combine(
          PathOperation.difference,
          bone,
          clip,
        );
        final Paint dash = _stroke(4.5);
        for (final metric in ghost.computeMetrics()) {
          for (double d = 0; d < metric.length; d += 11) {
            canvas.drawPath(
                metric.extractPath(d, math.min(d + 6, metric.length)), dash);
          }
        }
        _fill(canvas, Path.combine(PathOperation.intersect, bone, clip));

      case BoneGlyph.fracture:
        _fill(canvas, bone);
        canvas.drawPath(
          Path()
            ..moveTo(47, 30)
            ..lineTo(54, 42)
            ..lineTo(45, 51)
            ..lineTo(55, 60)
            ..lineTo(49, 72),
          _stroke(5),
        );
        final Paint pop = _stroke(4);
        canvas.drawLine(const Offset(60, 20), const Offset(66, 10), pop);
        canvas.drawLine(const Offset(40, 20), const Offset(34, 10), pop);
        canvas.drawLine(const Offset(50, 18), const Offset(50, 7), pop);

      case BoneGlyph.cutMarks:
        _fill(canvas, bone);
        final Paint slash = Paint()
          ..color = _hot
          ..strokeWidth = 5.5
          ..strokeCap = StrokeCap.round;
        for (final double x in <double>[36, 50, 64]) {
          canvas.drawLine(Offset(x - 5, 59), Offset(x + 5, 41), slash);
        }

      case BoneGlyph.burn:
        _fill(canvas, bone);
        final Paint char = Paint()..color = const Color(0xFF3B3945);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(38, 70), width: 12, height: 7), char);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(62, 66), width: 9, height: 6), char);
        final Path flame = Path()
          ..moveTo(50, 50)
          ..cubicTo(30, 48, 32, 30, 42, 20)
          ..cubicTo(42, 30, 48, 30, 50, 8)
          ..cubicTo(60, 20, 70, 32, 62, 44)
          ..cubicTo(60, 48, 56, 50, 50, 50)
          ..close();
        canvas.drawPath(flame, Paint()..color = const Color(0xFFFF8A3D));
        canvas.drawPath(
          Path()
            ..moveTo(50, 48)
            ..cubicTo(42, 46, 42, 36, 48, 30)
            ..cubicTo(50, 36, 56, 38, 56, 44)
            ..cubicTo(55, 47, 53, 48, 50, 48)
            ..close(),
          Paint()..color = const Color(0xFFFFE45C),
        );
        canvas.drawPath(flame, _stroke(4.5));
    }
    canvas.restore();
  }

  /// A little person on the left, a paw print on the right.
  void _species(Canvas canvas) {
    final Paint ink = Paint()..color = _ink;
    final Paint white = Paint()..color = Colors.white;
    final Paint line = _stroke(4.5);

    // Person.
    final Path head = Path()
      ..addOval(Rect.fromCircle(center: const Offset(28, 28), radius: 10));
    final Path body = Path()
      ..addRRect(RRect.fromLTRBR(14, 42, 42, 84, const Radius.circular(12)));
    for (final Path p in <Path>[body, head]) {
      canvas.drawPath(p, white);
      canvas.drawPath(p, line);
    }

    // Paw.
    canvas.drawOval(Rect.fromCenter(center: const Offset(72, 68), width: 26, height: 22), ink);
    for (final Offset toe in const <Offset>[
      Offset(56, 50),
      Offset(66, 40),
      Offset(79, 40),
      Offset(89, 50),
    ]) {
      canvas.drawOval(Rect.fromCenter(center: toe, width: 10, height: 12), ink);
    }
  }

  void _fill(Canvas canvas, Path p) {
    canvas.drawPath(p, Paint()..color = _bone);
    canvas.drawPath(p, _stroke(6));
  }

  void _eyes(Canvas canvas, Offset c) {
    final Paint ink = Paint()..color = _ink;
    canvas.drawCircle(c + const Offset(-7, -2), 3.8, ink);
    canvas.drawCircle(c + const Offset(7, -2), 3.8, ink);
    canvas.drawArc(
      Rect.fromCenter(center: c + const Offset(0, 3), width: 10, height: 7),
      0.2,
      math.pi - 0.4,
      false,
      _stroke(3),
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.glyph != glyph;
}
