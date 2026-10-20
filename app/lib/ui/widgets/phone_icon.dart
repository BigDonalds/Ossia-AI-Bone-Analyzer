import 'package:flutter/material.dart';

/// A phone with a home button, drawn to sit where [Icons.smartphone_rounded]
/// would, so the small phones match the big one on the status screen. Size
/// and colour come from the surrounding [IconTheme] unless given.
class PhoneIcon extends StatelessWidget {
  const PhoneIcon({super.key, this.size, this.color});

  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final IconThemeData theme = IconTheme.of(context);
    final double side = size ?? theme.size ?? 24;
    // Centred like an Icon, so a tight box around it doesn't stretch it.
    return SizedBox.square(
      dimension: side,
      child: Center(
        child: CustomPaint(
          size: Size.square(side),
          painter: _PhonePainter(color ?? theme.color ?? const Color(0xFF141414)),
        ),
      ),
    );
  }
}

class _PhonePainter extends CustomPainter {
  const _PhonePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Laid out on the 24-unit grid Material icons use.
    canvas.scale(size.width / 24);
    final Path phone = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(RRect.fromLTRBR(5, 1, 19, 23, const Radius.circular(3)))
      ..addRRect(RRect.fromLTRBR(7, 3.6, 17, 18, const Radius.circular(1)))
      ..addOval(Rect.fromCircle(center: const Offset(12, 20.5), radius: 1.3));
    canvas.drawPath(phone, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PhonePainter old) => old.color != color;
}
