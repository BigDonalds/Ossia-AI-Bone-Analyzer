import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../widgets/bone_buddy.dart';

/// The silhouettes the camera can overlay. Each one is drawn to fill the same
/// guide box, so a small bone asks the user to come much closer than a femur —
/// the outline doubles as a distance cue.
enum GuideShape {
  /// Femur, humerus, tibia.
  longBone(distanceCm: 40, aspect: 0.42),

  /// Cranium, mandible.
  skull(distanceCm: 35, aspect: 0.84),

  /// Scapula, pelvis, rib.
  flat(distanceCm: 35, aspect: 0.82),

  /// Vertebra, fragment.
  small(distanceCm: 15, aspect: 1.0);

  const GuideShape({required this.distanceCm, required this.aspect});

  /// Rough camera-to-bone distance at which a typical specimen fills the box.
  final int distanceCm;

  /// Its name on the shape picker.
  String label(AppLocalizations l) => switch (this) {
        GuideShape.longBone => l.guideLongBone,
        GuideShape.skull => l.guideSkull,
        GuideShape.flat => l.guideFlat,
        GuideShape.small => l.guideSmall,
      };

  /// What the buddy says while this outline is up.
  String tip(AppLocalizations l) => switch (this) {
        GuideShape.longBone => l.guideLongBoneTip,
        GuideShape.skull => l.guideSkullTip,
        GuideShape.flat => l.guideFlatTip,
        GuideShape.small => l.guideSmallTip,
      };

  /// Width / height of the guide box.
  final double aspect;

  /// Silhouette fitted into [r].
  Path silhouette(Rect r) {
    switch (this) {
      case GuideShape.longBone:
        return _vertical(r, (Rect h) => cartoonBonePath(h, shaft: 0.36, knob: 0.26));
      case GuideShape.skull:
        return _skull(r);
      case GuideShape.flat:
        return _scapula(r);
      case GuideShape.small:
        return _vertebra(r);
    }
  }

  /// Inner details — eye sockets, ridges — drawn lighter than the outline.
  Path details(Rect r) {
    final double w = r.width;
    final double h = r.height;
    Offset p(double x, double y) => Offset(r.left + w * x, r.top + h * y);
    switch (this) {
      case GuideShape.longBone:
        return Path();
      case GuideShape.skull:
        return Path()
          ..addOval(Rect.fromCircle(center: p(0.32, 0.47), radius: w * 0.13))
          ..addOval(Rect.fromCircle(center: p(0.68, 0.47), radius: w * 0.13))
          ..moveTo(p(0.5, 0.6).dx, p(0.5, 0.6).dy)
          ..lineTo(p(0.44, 0.7).dx, p(0.44, 0.7).dy)
          ..lineTo(p(0.56, 0.7).dx, p(0.56, 0.7).dy)
          ..close()
          ..moveTo(p(0.36, 0.86).dx, p(0.36, 0.86).dy)
          ..lineTo(p(0.64, 0.86).dx, p(0.64, 0.86).dy);
      case GuideShape.flat:
        return Path()
          ..moveTo(p(0.2, 0.3).dx, p(0.2, 0.3).dy)
          ..quadraticBezierTo(
              p(0.55, 0.2).dx, p(0.55, 0.2).dy, p(0.86, 0.26).dx, p(0.86, 0.26).dy);
      case GuideShape.small:
        return Path()
          ..addOval(Rect.fromCircle(center: p(0.5, 0.45), radius: w * 0.07));
    }
  }

  /// Where the cartoon face sits, or null for shapes with their own features.
  Offset? faceAt(Rect r) {
    switch (this) {
      case GuideShape.longBone:
        return r.center;
      case GuideShape.skull:
        return null;
      case GuideShape.flat:
        return Offset(r.left + r.width * 0.46, r.top + r.height * 0.5);
      case GuideShape.small:
        return Offset(r.left + r.width * 0.5, r.top + r.height * 0.74);
    }
  }
}

Path _vertical(Rect r, Path Function(Rect) horizontal) {
  final Path h = horizontal(Rect.fromLTWH(0, 0, r.height, r.width));
  final Matrix4 m = Matrix4.identity()
    ..translateByDouble(r.right, r.top, 0, 1)
    ..rotateZ(math.pi / 2);
  return h.transform(m.storage);
}

Path _skull(Rect r) {
  final double w = r.width;
  final double h = r.height;
  final Path cranium = Path()
    ..addOval(Rect.fromLTWH(r.left, r.top, w, h * 0.78));
  final Path jaw = Path()
    ..addRRect(RRect.fromLTRBR(
      r.left + w * 0.24,
      r.top + h * 0.6,
      r.right - w * 0.24,
      r.bottom,
      Radius.circular(w * 0.12),
    ));
  return Path.combine(PathOperation.union, cranium, jaw);
}

Path _scapula(Rect r) {
  final double w = r.width;
  final double h = r.height;
  Offset p(double x, double y) => Offset(r.left + w * x, r.top + h * y);
  return Path()
    ..moveTo(p(0.1, 0.12).dx, p(0.1, 0.12).dy)
    ..quadraticBezierTo(p(0.5, 0.0).dx, p(0.5, 0.0).dy, p(0.94, 0.1).dx, p(0.94, 0.1).dy)
    ..quadraticBezierTo(p(1.0, 0.2).dx, p(1.0, 0.2).dy, p(0.9, 0.3).dx, p(0.9, 0.3).dy)
    ..quadraticBezierTo(p(0.66, 0.62).dx, p(0.66, 0.62).dy, p(0.54, 0.95).dx, p(0.54, 0.95).dy)
    ..quadraticBezierTo(p(0.46, 1.02).dx, p(0.46, 1.02).dy, p(0.4, 0.93).dx, p(0.4, 0.93).dy)
    ..quadraticBezierTo(p(0.2, 0.56).dx, p(0.2, 0.56).dy, p(0.04, 0.24).dx, p(0.04, 0.24).dy)
    ..quadraticBezierTo(p(0.02, 0.14).dx, p(0.02, 0.14).dy, p(0.1, 0.12).dx, p(0.1, 0.12).dy)
    ..close();
}

Path _vertebra(Rect r) {
  final double w = r.width;
  final double h = r.height;
  Path rr(double l, double t, double rt, double b, double rad) => Path()
    ..addRRect(RRect.fromLTRBR(r.left + w * l, r.top + h * t, r.left + w * rt,
        r.top + h * b, Radius.circular(w * rad)));

  Path shape = Path()
    ..addOval(Rect.fromCircle(
        center: Offset(r.left + w * 0.5, r.top + h * 0.72), radius: w * 0.26));
  for (final Path part in <Path>[
    rr(0.02, 0.36, 0.98, 0.52, 0.08), // transverse processes
    rr(0.42, 0.02, 0.58, 0.46, 0.08), // spinous process
    rr(0.26, 0.3, 0.74, 0.6, 0.16), // arch
  ]) {
    shape = Path.combine(PathOperation.union, shape, part);
  }
  return shape;
}

/// Dims everything outside the guide box, then draws the dashed silhouette,
/// corner brackets and a length arrow along the box's long axis.
class BoneGuidePainter extends CustomPainter {
  BoneGuidePainter({
    required this.shape,
    required this.box,
    required this.phase,
    required this.accent,
    required this.pop,
  });

  final GuideShape shape;
  final Rect box;

  /// 0–1 marching-ants offset.
  final double phase;
  final Color accent;

  /// 0–1 bounce when the shape changes.
  final double pop;

  static const Color _ink = Color(0xFF141414);

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frame = RRect.fromRectAndRadius(box, const Radius.circular(28));

    // Scrim with a hole where the bone goes.
    final Path scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frame);
    canvas.drawPath(scrim, Paint()..color = Colors.black.withValues(alpha: 0.42));

    // Chunky corner brackets.
    final double arm = math.min(box.width, box.height) * 0.16;
    for (final (Offset o, double sx, double sy) in <(Offset, double, double)>[
      (box.topLeft, 1, 1),
      (box.topRight, -1, 1),
      (box.bottomLeft, 1, -1),
      (box.bottomRight, -1, -1),
    ]) {
      const double rad = 28;
      final Path p = Path()
        ..moveTo(o.dx + sx * (rad + arm * 0.6), o.dy)
        ..lineTo(o.dx + sx * rad, o.dy)
        ..arcToPoint(Offset(o.dx, o.dy + sy * rad),
            radius: const Radius.circular(rad), clockwise: sx * sy < 0)
        ..lineTo(o.dx, o.dy + sy * (rad + arm * 0.6));
      canvas.drawPath(
        p,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 10,
      );
      canvas.drawPath(
        p,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6,
      );
    }

    // Silhouette, scaled with a little pop when it changes.
    final double inset = math.min(box.width, box.height) * 0.12;
    Rect inner = box.deflate(inset);
    final double s = 0.9 + 0.1 * Curves.elasticOut.transform(pop.clamp(0, 1));
    inner = Rect.fromCenter(
        center: inner.center, width: inner.width * s, height: inner.height * s);

    final Path outline = shape.silhouette(inner);
    canvas.drawPath(outline, Paint()..color = Colors.white.withValues(alpha: 0.1));
    _dashed(canvas, outline, 16, 9, 4.5, Colors.white, shadow: true);
    _dashed(canvas, shape.details(inner), 9, 7, 3, Colors.white.withValues(alpha: 0.85),
        shadow: true);

    final Offset? face = shape.faceAt(inner);
    if (face != null) _face(canvas, face, math.min(inner.width, inner.height));

    _lengthArrow(canvas, box);
  }

  void _dashed(Canvas canvas, Path path, double dash, double gap, double width,
      Color color, {bool shadow = false}) {
    final Paint shadowPaint = Paint()
      ..color = _ink.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + 3
      ..strokeCap = StrokeCap.round;
    final Paint line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final double period = dash + gap;
    for (final ui.PathMetric m in path.computeMetrics()) {
      double d = -period + (phase * period);
      while (d < m.length) {
        final double start = math.max(0, d);
        final double end = math.min(m.length, d + dash);
        if (end > start) {
          final Path seg = m.extractPath(start, end);
          if (shadow) canvas.drawPath(seg, shadowPaint);
          canvas.drawPath(seg, line);
        }
        d += period;
      }
    }
  }

  void _face(Canvas canvas, Offset c, double scale) {
    final double eye = scale * 0.05;
    final Paint white = Paint()..color = Colors.white.withValues(alpha: 0.9);
    final Paint ink = Paint()..color = _ink.withValues(alpha: 0.85);
    for (final double sx in <double>[-1, 1]) {
      final Offset e = c + Offset(sx * scale * 0.12, -scale * 0.05);
      canvas.drawCircle(e, eye, white);
      canvas.drawCircle(e + Offset(0, eye * 0.2), eye * 0.5, ink);
    }
    final Path smile = Path()
      ..moveTo(c.dx - scale * 0.07, c.dy + scale * 0.06)
      ..quadraticBezierTo(c.dx, c.dy + scale * 0.14, c.dx + scale * 0.07, c.dy + scale * 0.06);
    canvas.drawPath(
      smile,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Double-headed arrow just outside the box along its longer side.
  void _lengthArrow(Canvas canvas, Rect b) {
    final bool tall = b.height >= b.width;
    final Paint p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final Paint sh = Paint()
      ..color = _ink.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const double head = 8;

    final Path path = Path();
    if (tall) {
      final double x = b.right + 16;
      final double t = b.top + 34;
      final double btm = b.bottom - 34;
      path
        ..moveTo(x, t)
        ..lineTo(x, btm)
        ..moveTo(x - head, t + head)
        ..lineTo(x, t)
        ..lineTo(x + head, t + head)
        ..moveTo(x - head, btm - head)
        ..lineTo(x, btm)
        ..lineTo(x + head, btm - head);
    } else {
      final double y = b.top - 16;
      final double l = b.left + 34;
      final double r = b.right - 34;
      path
        ..moveTo(l, y)
        ..lineTo(r, y)
        ..moveTo(l + head, y - head)
        ..lineTo(l, y)
        ..lineTo(l + head, y + head)
        ..moveTo(r - head, y - head)
        ..lineTo(r, y)
        ..lineTo(r - head, y + head);
    }
    canvas.drawPath(path, sh);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(BoneGuidePainter old) =>
      old.shape != shape ||
      old.box != box ||
      old.phase != phase ||
      old.accent != accent ||
      old.pop != pop;
}

/// Tiny filled silhouette for the shape picker chips.
class GuideGlyph extends StatelessWidget {
  const GuideGlyph({super.key, required this.shape, required this.color, this.size = 22});

  final GuideShape shape;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GlyphPainter(shape, color),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.shape, this.color);

  final GuideShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final double a = shape.aspect;
    final double h = size.height;
    final double w = math.min(size.width, h * a);
    final Rect r = Rect.fromCenter(
        center: size.center(Offset.zero), width: w, height: w / a);
    canvas.drawPath(shape.silhouette(r), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.shape != shape || old.color != color;
}
