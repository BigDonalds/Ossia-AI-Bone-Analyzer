import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme/typography.dart';
import '../widgets/bone_buddy.dart';

/// Bright colours that read on any camera picture, light theme or dark.
const List<Color> kNeon = <Color>[
  Color(0xFFFFE45C),
  Color(0xFF5CFFB0),
  Color(0xFFFF5CC8),
  Color(0xFF5CC8FF),
  Color(0xFFB4FF5C),
];

/// The "got it" green of the lock-on frame and the badge.
const Color kLockGreen = Color(0xFF4ADE80);

const Color _ink = Color(0xFF141414);

/// The guide frame's outline as one path, starting at the middle of the top
/// edge and running clockwise, so a trace along it grows evenly.
Path framePath(Rect box, double radius) {
  final Radius r = Radius.circular(radius);
  return Path()
    ..moveTo(box.center.dx, box.top)
    ..lineTo(box.right - radius, box.top)
    ..arcToPoint(Offset(box.right, box.top + radius), radius: r)
    ..lineTo(box.right, box.bottom - radius)
    ..arcToPoint(Offset(box.right - radius, box.bottom), radius: r)
    ..lineTo(box.left + radius, box.bottom)
    ..arcToPoint(Offset(box.left, box.bottom - radius), radius: r)
    ..lineTo(box.left, box.top + radius)
    ..arcToPoint(Offset(box.left + radius, box.top), radius: r)
    ..close();
}

/// Everything the auto snap draws on the guide frame: a scan line sweeping
/// the frame while it looks, green lock-on brackets once it sees a bone, and
/// a rainbow trace round the frame that fills while the phone is held still.
class AutoSnapPainter extends CustomPainter {
  AutoSnapPainter({
    required this.box,
    required this.scan,
    required this.sweep,
    required this.seen,
    required this.hold,
  });

  final Rect box;

  /// 0-1, looping: the scan line's trip down and back up.
  final double scan;

  /// 0-1, how much of the scan line to show.
  final double sweep;

  /// 0-1, how far the lock-on has come in.
  final double seen;

  /// 0-1, how much of the hold is done.
  final double hold;

  static const double _radius = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect frame = RRect.fromRectAndRadius(box, const Radius.circular(_radius));
    if (sweep > 0.01) _paintSweep(canvas, frame);
    if (seen > 0.01) _paintLock(canvas);
    if (hold > 0.001) _paintTrace(canvas);
  }

  void _paintSweep(Canvas canvas, RRect frame) {
    canvas.save();
    canvas.clipRRect(frame);
    // Down and back up, easing at both ends.
    final double leg = scan < 0.5 ? scan * 2 : 2 - scan * 2;
    final double y = box.top + box.height * Curves.easeInOutSine.transform(leg);
    final bool down = scan < 0.5;

    // Dot grid that lights up as the line passes.
    const double gap = 22;
    final Paint dot = Paint();
    for (double gy = box.top + gap / 2; gy < box.bottom; gy += gap) {
      final double near = 1 - ((gy - y).abs() / 46).clamp(0.0, 1.0);
      if (near <= 0) continue;
      dot.color = kNeon[3].withValues(alpha: near * 0.75 * sweep);
      for (double gx = box.left + gap / 2; gx < box.right; gx += gap) {
        canvas.drawCircle(Offset(gx, gy), 1.2 + near * 1.3, dot);
      }
    }

    // Glow trailing behind the line.
    const double tail = 90;
    final Rect glow = down
        ? Rect.fromLTRB(box.left, y - tail, box.right, y)
        : Rect.fromLTRB(box.left, y, box.right, y + tail);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, y),
          Offset(0, down ? y - tail : y + tail),
          <Color>[
            kNeon[3].withValues(alpha: 0.5 * sweep),
            kNeon[3].withValues(alpha: 0),
          ],
        ),
    );

    // The line itself: bright in the middle, fading to the sides.
    final Paint line = Paint()
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(
        Offset(box.left, y),
        Offset(box.right, y),
        <Color>[
          kNeon[3].withValues(alpha: 0),
          kNeon[3].withValues(alpha: sweep),
          Colors.white.withValues(alpha: sweep),
          kNeon[3].withValues(alpha: sweep),
          kNeon[3].withValues(alpha: 0),
        ],
        const <double>[0, 0.2, 0.5, 0.8, 1],
      );
    canvas.drawLine(Offset(box.left + 8, y), Offset(box.right - 8, y), line
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawLine(Offset(box.left + 8, y), Offset(box.right - 8, y), line
      ..strokeWidth = 3.5
      ..maskFilter = null);
    canvas.restore();
  }

  void _paintLock(Canvas canvas) {
    final double t = Curves.easeOutBack.transform(seen.clamp(0.0, 1.0));
    // Glow round the whole frame, breathing a little.
    final double breathe = 0.65 + 0.35 * math.sin(scan * math.pi * 4);
    final RRect frame = RRect.fromRectAndRadius(box, const Radius.circular(_radius));
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = kLockGreen.withValues(alpha: 0.45 * seen * breathe)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Brackets flying in from outside to sit just off the corners.
    final double off = 8 + 26 * (1 - t);
    final double arm = math.min(box.width, box.height) * 0.12;
    final Paint ink = Paint()
      ..color = _ink.withValues(alpha: seen.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 9;
    final Paint green = Paint()
      ..color = kLockGreen.withValues(alpha: seen.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 5;
    for (final (Offset o, double sx, double sy) in <(Offset, double, double)>[
      (box.topLeft, -1, -1),
      (box.topRight, 1, -1),
      (box.bottomLeft, -1, 1),
      (box.bottomRight, 1, 1),
    ]) {
      final Offset c = o + Offset(sx * off, sy * off);
      final Path p = Path()
        ..moveTo(c.dx - sx * arm, c.dy)
        ..lineTo(c.dx, c.dy)
        ..lineTo(c.dx, c.dy - sy * arm);
      canvas.drawPath(p, ink);
      canvas.drawPath(p, green);
    }
  }

  void _paintTrace(Canvas canvas) {
    final ui.PathMetric m = framePath(box, _radius).computeMetrics().first;
    final double len = m.length * hold.clamp(0.0, 1.0);
    final Path done = m.extractPath(0, len);
    // Rainbow that slowly turns, so the trace shimmers as it grows.
    final Shader rainbow = SweepGradient(
      colors: <Color>[...kNeon, kNeon.first],
      transform: GradientRotation(scan * math.pi * 2),
    ).createShader(box);

    canvas.drawPath(
      done,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..shader = rainbow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(
      done,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = _ink,
    );
    canvas.drawPath(
      done,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = rainbow,
    );

    // A spark riding the front of the trace.
    final ui.Tangent? head = m.getTangentForOffset(len);
    if (head != null) {
      canvas.drawCircle(
        head.position,
        11,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(head.position, 4.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(AutoSnapPainter old) =>
      old.box != box ||
      old.scan != scan ||
      old.sweep != sweep ||
      old.seen != seen ||
      old.hold != hold;
}

/// The ring round the shutter while the auto snap is on: a slowly turning
/// dashed ring while it waits, and a rainbow that fills with the hold.
class ShutterRingPainter extends CustomPainter {
  ShutterRingPainter({required this.spin, required this.hold, required this.armed});

  /// 0-1, looping.
  final double spin;

  /// 0-1, how much of the hold is done.
  final double hold;

  /// 0-1, how visible the waiting ring is.
  final double armed;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 4;

    if (armed > 0.01) {
      final Paint dash = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      const int n = 14;
      for (int i = 0; i < n; i++) {
        final double a = (i / n + spin) * math.pi * 2;
        dash.color = kNeon[i % kNeon.length].withValues(alpha: 0.9 * armed);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi * 2 / n * 0.45,
            false, dash);
      }
    }

    if (hold > 0.001) {
      final Rect ring = Rect.fromCircle(center: c, radius: r);
      final Shader rainbow = SweepGradient(
        colors: <Color>[...kNeon, kNeon.first],
        transform: GradientRotation(spin * math.pi * 2),
      ).createShader(ring);
      final double sweep = math.pi * 2 * hold.clamp(0.0, 1.0);
      canvas.drawArc(
        ring,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..shader = rainbow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawArc(
        ring,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..shader = rainbow,
      );
    }
  }

  @override
  bool shouldRepaint(ShutterRingPainter old) =>
      old.spin != spin || old.hold != hold || old.armed != armed;
}

enum _Bit { bone, star, dot }

/// One piece of the burst: where it flies, how it spins, what it is.
class SnapParticle {
  SnapParticle._(this.angle, this.reach, this.size, this.spin, this.color, this._bit, this.delay);

  final double angle;

  /// How far it flies, as a share of the screen's longer side.
  final double reach;
  final double size;
  final double spin;
  final Color color;
  final _Bit _bit;
  final double delay;
}

/// A fresh set of burst pieces; [seed] keeps one burst's pieces the same
/// from frame to frame.
List<SnapParticle> snapParticles(int seed, {int count = 34}) {
  final math.Random rnd = math.Random(seed);
  return <SnapParticle>[
    for (int i = 0; i < count; i++)
      SnapParticle._(
        (i / count) * math.pi * 2 + rnd.nextDouble() * 0.35,
        0.28 + rnd.nextDouble() * 0.34,
        i % 3 == 0 ? 24 + rnd.nextDouble() * 12 : 9 + rnd.nextDouble() * 10,
        (rnd.nextDouble() - 0.5) * 9,
        kNeon[rnd.nextInt(kNeon.length)],
        i % 3 == 0 ? _Bit.bone : (i.isEven ? _Bit.star : _Bit.dot),
        rnd.nextDouble() * 0.12,
      ),
  ];
}

/// The auto snap's moment: two shockwaves out of the frame, a colour flash,
/// and a spray of little bones, stars and dots.
class SnapBurstPainter extends CustomPainter {
  SnapBurstPainter({required this.t, required this.box, required this.pieces});

  /// 0-1 through the burst.
  final double t;
  final Rect box;
  final List<SnapParticle> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final Offset c = box.center;
    final double far = size.longestSide;

    // Colour flash out of the frame.
    final double flash = (1 - t / 0.35).clamp(0.0, 1.0);
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(c, far * 0.7, <Color>[
            Colors.white.withValues(alpha: 0.85 * flash),
            kNeon[0].withValues(alpha: 0.45 * flash),
            kNeon[2].withValues(alpha: 0),
          ], const <double>[0, 0.35, 1]),
      );
    }

    // Two shockwaves, the second a beat behind.
    for (final (double lag, Color colour) in <(double, Color)>[
      (0, Colors.white),
      (0.12, kNeon[2]),
    ]) {
      final double k = ((t - lag) / (1 - lag)).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final double e = Curves.easeOutCubic.transform(k);
      final double radius = box.shortestSide * 0.35 + far * 0.75 * e;
      canvas.drawCircle(
        c,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18 * (1 - k) + 1
          ..color = colour.withValues(alpha: (1 - k) * 0.9),
      );
    }

    // Pieces.
    for (final SnapParticle p in pieces) {
      final double k = ((t - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
      if (k <= 0) continue;
      final double e = Curves.easeOutCubic.transform(k);
      final Offset dir = Offset(math.cos(p.angle), math.sin(p.angle));
      final Offset at = c + dir * (far * p.reach * e) + Offset(0, 160 * k * k);
      final double grow = k < 0.12 ? k / 0.12 : 1 - math.pow((k - 0.12) / 0.88, 2).toDouble();
      final double s = p.size * grow;
      if (s <= 0.5) continue;
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(p.spin * k);
      switch (p._bit) {
        case _Bit.bone:
          final Path bone =
              cartoonBonePath(Rect.fromCenter(center: Offset.zero, width: s * 1.8, height: s * 0.8));
          canvas.drawPath(bone, Paint()..color = p.color);
          canvas.drawPath(
            bone,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..color = _ink,
          );
        case _Bit.star:
          final Path star = _sparkle(s * 0.6);
          canvas.drawPath(
            star,
            Paint()
              ..color = p.color
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
          canvas.drawPath(star, Paint()..color = Colors.white.withValues(alpha: 0.9));
        case _Bit.dot:
          canvas.drawCircle(Offset.zero, s * 0.35, Paint()..color = p.color);
      }
      canvas.restore();
    }
  }

  /// Four-pointed twinkle.
  static Path _sparkle(double r) {
    final double w = r * 0.28;
    return Path()
      ..moveTo(0, -r)
      ..quadraticBezierTo(w, -w, r, 0)
      ..quadraticBezierTo(w, w, 0, r)
      ..quadraticBezierTo(-w, w, -r, 0)
      ..quadraticBezierTo(-w, -w, 0, -r)
      ..close();
  }

  @override
  bool shouldRepaint(SnapBurstPainter old) => old.t != t || old.box != box;
}

/// The green sticker that pops onto the top of the frame when a bone is in
/// view.
class SpottedBadge extends StatelessWidget {
  const SpottedBadge({super.key, required this.show, required this.label});

  /// 0-1 from the lock-on animation.
  final Animation<double> show;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: show,
      builder: (BuildContext context, Widget? child) {
        final double v = show.value;
        if (v <= 0.01) return const SizedBox.shrink();
        return Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: -0.05 + 0.12 * (1 - v),
            child: Transform.scale(
              scale: 0.5 + 0.5 * Curves.elasticOut.transform(v.clamp(0.0, 1.0)),
              child: child,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(9, 5, 12, 6),
        decoration: BoxDecoration(
          color: kLockGreen,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: _ink, width: 2.5),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: _ink, offset: Offset(2.5, 2.5)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.auto_awesome_rounded, size: 16, color: _ink),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppType.button.copyWith(
                color: _ink,
                fontSize: 13,
                letterSpacing: AppType.tracking(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The big stamp in the middle of the burst.
class SnapStamp extends StatelessWidget {
  const SnapStamp({super.key, required this.t, required this.label});

  /// 0-1 through the burst.
  final double t;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    final double pop = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
    final double fade = t < 0.7 ? 1 : 1 - (t - 0.7) / 0.3;
    return Opacity(
      opacity: fade.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: -0.12,
        child: Transform.scale(
          scale: 0.3 + 0.7 * pop,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            decoration: BoxDecoration(
              color: kNeon[2],
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _ink, width: 3),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: _ink, offset: Offset(4, 4)),
              ],
            ),
            child: Text(
              label,
              style: AppType.button.copyWith(
                color: _ink,
                fontSize: 30,
                letterSpacing: AppType.tracking(1.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
