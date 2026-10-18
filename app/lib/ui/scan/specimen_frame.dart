import 'dart:math';

import 'package:flutter/material.dart';

/// Corner brackets, a faint measuring grid and a centre crosshair — the
/// viewfinder language of a lab instrument rather than a camera app.
class SpecimenFrame extends StatelessWidget {
  const SpecimenFrame({
    super.key,
    required this.accent,
    required this.grid,
    this.child,
    this.sweep,
  });

  final Color accent;
  final Color grid;
  final Widget? child;

  /// 0–1 position of the scanning line, or null for a static frame.
  final double? sweep;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FramePainter(accent: accent, grid: grid, sweep: sweep),
      child: child,
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter({required this.accent, required this.grid, this.sweep});

  final Color accent;
  final Color grid;
  final double? sweep;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Offset.zero & size;

    // Measuring grid — quarters only, so it reads as calibration not chrome.
    final Paint gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 0.5;
    for (int i = 1; i < 4; i++) {
      final double dx = size.width * i / 4;
      final double dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    // Centre crosshair.
    final Paint cross = Paint()
      ..color = grid
      ..strokeWidth = 1;
    final Offset c = r.center;
    canvas.drawLine(c - const Offset(7, 0), c + const Offset(7, 0), cross);
    canvas.drawLine(c - const Offset(0, 7), c + const Offset(0, 7), cross);

    // Corner brackets.
    final double arm = min(size.width, size.height) * 0.11;
    final Paint bracket = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    void corner(Offset o, double sx, double sy) {
      final Path p = Path()
        ..moveTo(o.dx + sx * arm, o.dy)
        ..lineTo(o.dx, o.dy)
        ..lineTo(o.dx, o.dy + sy * arm);
      canvas.drawPath(p, bracket);
    }

    corner(r.topLeft, 1, 1);
    corner(r.topRight, -1, 1);
    corner(r.bottomLeft, 1, -1);
    corner(r.bottomRight, -1, -1);

    if (sweep != null) {
      final double y = size.height * sweep!;
      final Rect band = Rect.fromLTWH(0, y - 46, size.width, 46);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              accent.withValues(alpha: 0.0),
              accent.withValues(alpha: 0.16),
            ],
          ).createShader(band),
      );
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..color = accent
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.sweep != sweep || old.accent != accent || old.grid != grid;
}
