import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../data/reference_data.dart';

/// A cartoon drawing of one of the sixteen bone classes, on a sticker tile.
/// Stands in for an icon wherever a bone is listed.
class BoneSketch extends StatelessWidget {
  const BoneSketch({super.key, required this.entry, this.size = 50});

  final BoneEntry entry;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final int seed = entry.key.codeUnits.fold(0, (int a, int b) => a + b);
    return Transform.rotate(
      angle: (seed % 5 - 2) * 0.03,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: c.sticker(entry.region.index),
          borderRadius: BorderRadius.circular(size * 0.3),
          border: Border.all(color: c.ink, width: size > 60 ? 2.2 : 1.8),
          boxShadow: <BoxShadow>[
            BoxShadow(color: c.shadow, offset: Offset(size / 22, size / 22)),
          ],
        ),
        child: CustomPaint(painter: _SketchPainter(entry.key)),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  _SketchPainter(this.kind);

  final String kind;

  static const Color _ink = Color(0xFF141414);
  static const Color _bone = Color(0xFFFFF8EA);
  static const Color _blush = Color(0xFFFF9EC7);

  late Canvas _c;

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    // Draw in a 100 × 100 box inset from the tile edge.
    const double inset = 0.1;
    canvas.save();
    canvas.translate(size.width * inset, size.height * inset);
    canvas.scale(size.width * (1 - inset * 2) / 100);

    switch (kind) {
      case 'skull':
        _skull(withJaw: true);
      case 'cranium':
        _skull(withJaw: false);
      case 'mandible':
        _mandible();
      case 'femur':
        _tilted(_femur);
      case 'humerus':
        _tilted(_humerus);
      case 'tibia':
        _tilted(_tibia);
      case 'radius':
        _tilted(_radius);
      case 'ulna':
        _tilted(_ulna);
      case 'scapula':
        _scapula();
      case 'os_coxa':
        _osCoxa();
      case 'rib_1_2':
        _rib(const Offset(26, 74), const Offset(14, 26), const Offset(64, 12),
            const Offset(80, 42), 21, faceScale: 0.9);
      case 'typical_rib':
        _rib(const Offset(16, 82), const Offset(6, 22), const Offset(64, 4),
            const Offset(88, 36), 17, faceScale: 0.78);
      case 'rib_11_12':
        _rib(const Offset(14, 70), const Offset(34, 40), const Offset(62, 34),
            const Offset(88, 46), 17, faceScale: 0.78);
      case 'cervical_vertebrae':
        _cervical();
      case 'thoracic_vertebrae':
        _thoracic();
      case 'lumbar_vertebrae':
        _lumbar();
      default:
        _tilted(_femur);
    }
    canvas.restore();
  }

  // ── Drawing helpers ─────────────────────────────────────────────────────

  void _body(Path p) {
    _c.drawPath(p, Paint()..color = _bone);
    _c.drawPath(
      p,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _line(Path p, [double width = 4]) {
    _c.drawPath(
      p,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _dot(double x, double y, double r) =>
      _c.drawCircle(Offset(x, y), r, Paint()..color = _ink);

  /// A small "•‿•" face. Cheeks only where the bone is wide enough to hold
  /// them; on a slim shaft they would float off the edge.
  void _face(double cx, double cy, {double scale = 1, bool cheeks = true}) {
    final double s = scale;
    _dot(cx - 6 * s, cy, 3.6 * s);
    _dot(cx + 6 * s, cy, 3.6 * s);
    if (cheeks) {
      final Paint blush = Paint()..color = _blush.withValues(alpha: 0.8);
      _c.drawOval(
          Rect.fromCenter(center: Offset(cx - 12 * s, cy + 5 * s), width: 6 * s, height: 3.6 * s),
          blush);
      _c.drawOval(
          Rect.fromCenter(center: Offset(cx + 12 * s, cy + 5 * s), width: 6 * s, height: 3.6 * s),
          blush);
    }
    _line(
      Path()
        ..moveTo(cx - 4 * s, cy + 5 * s)
        ..quadraticBezierTo(cx, cy + 10 * s, cx + 4 * s, cy + 5 * s),
      3.2 * s,
    );
  }

  Path _circle(double x, double y, double r) =>
      Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  Path _rrect(double l, double t, double r, double b, double rad) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(rad)));

  Path _poly(List<Offset> pts) => Path()..addPolygon(pts, true);

  Path _union(List<Path> parts) => parts.reduce(
      (Path a, Path b) => Path.combine(PathOperation.union, a, b));

  Path _minus(Path a, Path b) => Path.combine(PathOperation.difference, a, b);

  /// Long bones are drawn upright, then leaned for a bit of attitude.
  void _tilted(void Function() draw) {
    _c.save();
    _c.translate(50, 50);
    _c.rotate(-math.pi / 5.2);
    _c.translate(-50, -50);
    draw();
    _c.restore();
  }

  // ── Long bones ──────────────────────────────────────────────────────────

  void _femur() {
    _body(_union(<Path>[
      _rrect(38, 20, 62, 82, 6),
      _circle(31, 13, 13),
      _poly(const <Offset>[Offset(26, 10), Offset(60, 22), Offset(60, 38), Offset(34, 24)]),
      _circle(62, 22, 9),
      _rrect(32, 74, 68, 88, 6),
      _circle(39, 88, 9),
      _circle(61, 88, 9),
    ]));
    _line(Path()
      ..moveTo(50, 86)
      ..lineTo(50, 96), 3.5);
    _face(50, 50, cheeks: false);
  }

  void _humerus() {
    _body(_union(<Path>[
      _rrect(39, 22, 61, 80, 6),
      _circle(45, 15, 14),
      _circle(62, 21, 8),
      _poly(const <Offset>[Offset(39, 72), Offset(61, 72), Offset(70, 86), Offset(30, 86)]),
      _circle(37, 88, 8),
      _circle(63, 88, 8),
    ]));
    _face(50, 48, cheeks: false);
  }

  void _tibia() {
    _body(_union(<Path>[
      _rrect(26, 5, 74, 23, 8),
      _poly(const <Offset>[Offset(28, 20), Offset(72, 20), Offset(62, 36), Offset(38, 36)]),
      _rrect(39, 30, 61, 84, 6),
      _rrect(35, 80, 65, 93, 6),
      _circle(36, 92, 6),
    ]));
    _face(50, 52, cheeks: false);
  }

  void _radius() {
    _body(_union(<Path>[
      _rrect(35, 5, 65, 17, 6),
      _rrect(41, 14, 59, 80, 5),
      _poly(const <Offset>[Offset(41, 72), Offset(59, 72), Offset(71, 88), Offset(31, 88)]),
      _rrect(31, 84, 71, 95, 6),
    ]));
    _face(50, 46, scale: 0.85, cheeks: false);
  }

  void _ulna() {
    final Path top = _minus(
      _union(<Path>[_circle(48, 16, 14), _rrect(35, 10, 61, 32, 7)]),
      _circle(63, 22, 8.5),
    );
    _body(_union(<Path>[
      top,
      _rrect(40, 24, 58, 86, 6),
      _circle(49, 88, 8),
    ]));
    _face(49, 54, scale: 0.85, cheeks: false);
  }

  // ── Heads ───────────────────────────────────────────────────────────────

  void _skull({required bool withJaw}) {
    final Path head = withJaw
        ? _union(<Path>[_circle(50, 42, 34), _rrect(30, 56, 70, 94, 14)])
        : _union(<Path>[_circle(50, 44, 36), _rrect(32, 60, 68, 80, 8)]);
    _body(head);

    final double eyeY = withJaw ? 46 : 48;
    for (final double x in <double>[37, 63]) {
      _c.drawOval(
        Rect.fromCenter(center: Offset(x, eyeY), width: 19, height: 21),
        Paint()..color = _ink,
      );
      // Googly eyes rattling around in the sockets.
      _c.drawCircle(Offset(x, eyeY + 1), 6.5, Paint()..color = Colors.white);
      _dot(x + 2.5, eyeY + 3, 3.4);
    }
    _c.drawPath(
      _poly(<Offset>[
        Offset(46, eyeY + 14),
        Offset(54, eyeY + 14),
        Offset(50, eyeY + 21),
      ]),
      Paint()..color = _ink,
    );

    if (withJaw) {
      _line(Path()
        ..moveTo(36, 82)
        ..lineTo(64, 82));
      for (final double x in <double>[43, 50, 57]) {
        _line(Path()
          ..moveTo(x, 77)
          ..lineTo(x, 87), 3);
      }
    } else {
      // Upper teeth only, dangling where the jaw should be.
      for (final double x in <double>[38, 46, 54, 62]) {
        _c.drawRRect(
          RRect.fromLTRBR(x - 3.2, 78, x + 3.2, 88, const Radius.circular(2)),
          Paint()..color = _bone,
        );
        _c.drawRRect(
          RRect.fromLTRBR(x - 3.2, 78, x + 3.2, 88, const Radius.circular(2)),
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
      }
    }
  }

  void _mandible() {
    final Path arch = Path()
      ..moveTo(18, 22)
      ..cubicTo(14, 96, 86, 96, 82, 22);
    // Thick outlined U: ink stroke, then bone stroke on top.
    _c.drawPath(
      arch,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round,
    );
    _c.drawPath(
      arch,
      Paint()
        ..color = _bone
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round,
    );
    // Teeth along the inside of the arch.
    final Path inner = Path()
      ..moveTo(30, 38)
      ..cubicTo(28, 80, 72, 80, 70, 38);
    for (final metric in inner.computeMetrics()) {
      for (double d = 4; d < metric.length; d += 11) {
        final Tangent? t = metric.getTangentForOffset(d);
        if (t == null) continue;
        _c.drawCircle(t.position, 4, Paint()..color = Colors.white);
        _c.drawCircle(
          t.position,
          4,
          Paint()
            ..color = _ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
    }
    _face(50, 50, scale: 0.75);
  }

  // ── Flat bones ──────────────────────────────────────────────────────────

  void _scapula() {
    _body(Path()
      ..moveTo(20, 14)
      ..lineTo(84, 18)
      ..quadraticBezierTo(92, 22, 86, 32)
      ..lineTo(46, 90)
      ..quadraticBezierTo(38, 97, 33, 88)
      ..lineTo(12, 24)
      ..quadraticBezierTo(11, 14, 20, 14)
      ..close());
    _line(Path()
      ..moveTo(18, 34)
      ..quadraticBezierTo(50, 26, 88, 30), 4.5);
    _dot(88, 30, 4.5);
    _face(46, 50, scale: 0.85);
  }

  void _osCoxa() {
    final Path outline = Path()
      ..moveTo(20, 44)
      ..cubicTo(10, 14, 60, -2, 86, 18)
      ..cubicTo(94, 28, 80, 44, 68, 52)
      ..lineTo(76, 76)
      ..cubicTo(80, 94, 58, 100, 46, 92)
      ..lineTo(28, 78)
      ..cubicTo(20, 70, 24, 58, 20, 44)
      ..close();
    final Path hole = Path()
      ..addOval(Rect.fromCenter(center: const Offset(56, 78), width: 16, height: 14));
    _body(_minus(outline, hole));
    _c.drawCircle(const Offset(46, 58), 8,
        Paint()..color = const Color(0xFFF0DFC2));
    _c.drawCircle(
      const Offset(46, 58),
      8,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    _face(52, 26, scale: 0.8);
  }

  // ── Ribs ────────────────────────────────────────────────────────────────

  void _rib(Offset a, Offset b, Offset c, Offset d, double width,
      {required double faceScale}) {
    final Path p = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(b.dx, b.dy, c.dx, c.dy, d.dx, d.dy);
    _c.drawPath(
      p,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 11
        ..strokeCap = StrokeCap.round,
    );
    _c.drawPath(
      p,
      Paint()
        ..color = _bone
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    // Rib head knob at the spine end.
    _body(_circle(a.dx, a.dy, width * 0.62 + 1));

    // Face sits on the curve, turned to follow it but never upside down.
    final PathMetric metric = p.computeMetrics().first;
    final Tangent? mid = metric.getTangentForOffset(metric.length * 0.55);
    if (mid == null) return;
    double turn = math.atan2(mid.vector.dy, mid.vector.dx);
    if (turn > math.pi / 2) turn -= math.pi;
    if (turn < -math.pi / 2) turn += math.pi;
    _c.save();
    _c.translate(mid.position.dx, mid.position.dy);
    _c.rotate(turn);
    _face(0, -3 * faceScale, scale: faceScale, cheeks: false);
    _c.restore();
  }

  // ── Vertebrae (seen from above) ─────────────────────────────────────────

  void _cervical() {
    final Path shape = _union(<Path>[
      _rrect(30, 58, 70, 86, 12),
      _poly(const <Offset>[Offset(28, 60), Offset(72, 60), Offset(62, 26), Offset(38, 26)]),
      _circle(17, 54, 11),
      _circle(83, 54, 11),
      _circle(43, 20, 7),
      _circle(57, 20, 7),
    ]);
    final Path holes = _union(<Path>[
      _circle(17, 54, 4),
      _circle(83, 54, 4),
      Path()..addOval(Rect.fromCenter(center: const Offset(50, 46), width: 18, height: 14)),
    ]);
    _body(_minus(shape, holes));
    _face(50, 71, scale: 0.8);
  }

  void _thoracic() {
    final Path shape = _union(<Path>[
      _circle(50, 72, 20),
      _poly(const <Offset>[Offset(34, 58), Offset(66, 58), Offset(58, 36), Offset(42, 36)]),
      _rrect(45, 4, 55, 44, 5),
      _poly(const <Offset>[Offset(40, 44), Offset(12, 30), Offset(8, 38), Offset(40, 54)]),
      _poly(const <Offset>[Offset(60, 44), Offset(88, 30), Offset(92, 38), Offset(60, 54)]),
    ]);
    _body(_minus(shape, _circle(50, 48, 6)));
    _face(50, 72, scale: 0.8);
  }

  void _lumbar() {
    final Path shape = _union(<Path>[
      Path()..addOval(Rect.fromCenter(center: const Offset(50, 72), width: 56, height: 36)),
      _poly(const <Offset>[Offset(32, 58), Offset(68, 58), Offset(60, 34), Offset(40, 34)]),
      _rrect(40, 8, 60, 38, 6),
      _rrect(8, 38, 92, 50, 6),
    ]);
    final Path hole = Path()
      ..moveTo(42, 52)
      ..lineTo(58, 52)
      ..lineTo(50, 40)
      ..close();
    _body(_minus(shape, hole));
    _face(50, 72, scale: 0.9);
  }

  @override
  bool shouldRepaint(_SketchPainter old) => old.kind != kind;
}
