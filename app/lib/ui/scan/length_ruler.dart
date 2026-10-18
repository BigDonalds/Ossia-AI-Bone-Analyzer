import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/settings_controller.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/primitives.dart';

/// A tape measure you flick sideways. Ticks every tenth of a unit, snaps to
/// the nearest tick when released, and clicks on every whole unit.
class LengthRuler extends StatefulWidget {
  const LengthRuler({
    super.key,
    required this.unit,
    required this.valueCm,
    required this.onChanged,
  });

  final LengthUnit unit;

  /// Current value in centimetres, or null while the user has not set one.
  final double? valueCm;
  final ValueChanged<double> onChanged;

  static const double maxCm = 120;

  @override
  State<LengthRuler> createState() => _LengthRulerState();
}

class _LengthRulerState extends State<LengthRuler> {
  static const double _spacing = 12;
  static const int _ticksPerUnit = 10;

  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: _offsetFor(widget.valueCm ?? _restCm),
  );
  bool _programmatic = false;
  bool _dragging = false;
  int _lastWhole = -1;

  /// Where the tape rests before the user touches it.
  double get _restCm => widget.unit == LengthUnit.inches ? 8 * 2.54 : 20;

  double get _maxUnits => widget.unit == LengthUnit.inches
      ? (LengthRuler.maxCm / 2.54).floorToDouble()
      : LengthRuler.maxCm;

  double _offsetFor(double cm) {
    final double units = widget.unit.from(cm).clamp(0, _maxUnits);
    return units * _ticksPerUnit * _spacing;
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(LengthRuler old) {
    super.didUpdateWidget(old);
    final bool unitChanged = old.unit != widget.unit;
    final bool externallySet =
        widget.valueCm != null &&
        !_dragging &&
        (old.valueCm == null || (old.valueCm! - widget.valueCm!).abs() > 0.05);
    if ((unitChanged || externallySet) && _scroll.hasClients) {
      _programmatic = true;
      _scroll.jumpTo(_offsetFor(widget.valueCm ?? _restCm));
      _programmatic = false;
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_programmatic || !_dragging && widget.valueCm == null) return;
    final double units = (_scroll.offset / _spacing / _ticksPerUnit).clamp(
      0.0,
      _maxUnits,
    );
    final int whole = units.floor();
    if (whole != _lastWhole) {
      if (_lastWhole != -1) Haptics.tap();
      _lastWhole = whole;
    }
    final double cm = widget.unit == LengthUnit.inches ? units * 2.54 : units;
    widget.onChanged(double.parse(cm.toStringAsFixed(2)));
  }

  bool _onNotification(ScrollNotification n) {
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _dragging = true;
    } else if (n is ScrollEndNotification) {
      final bool wasDragging = _dragging;
      _dragging = false;
      if (wasDragging || widget.valueCm != null) {
        final double snapped =
            (_scroll.offset / _spacing).roundToDouble() * _spacing;
        if ((snapped - _scroll.offset).abs() > 0.5) {
          Future<void>.microtask(() {
            if (!_scroll.hasClients) return;
            _dragging = true;
            _scroll
                .animateTo(
                  snapped,
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                )
                .whenComplete(() => _dragging = false);
          });
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color tape = c.stickers[0];

    // A tape measure reads left to right in every language. The painted
    // ticks assume it, and a right-to-left scroll would drag them the
    // wrong way under the finger.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double w = box.maxWidth;
          final double total = _maxUnits * _ticksPerUnit * _spacing;
          return SizedBox(
            height: 92,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: tape,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: c.ink, width: Chunky.border),
                      boxShadow: <BoxShadow>[
                        BoxShadow(color: c.shadow, offset: const Offset(3, 3)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: _onNotification,
                        child: CustomPaint(
                          foregroundPainter: _TickPainter(
                            scroll: _scroll,
                            spacing: _spacing,
                            ticksPerUnit: _ticksPerUnit,
                            maxUnits: _maxUnits,
                            ink: const Color(0xFF141414),
                            label: AppType.metric.copyWith(
                              color: const Color(0xFF141414),
                              fontSize: 14,
                            ),
                          ),
                          // Mouse and trackpad drags too, so the tape also
                          // works in the web preview and on desktop.
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: PointerDeviceKind.values.toSet(),
                              scrollbars: false,
                            ),
                            child: SingleChildScrollView(
                              controller: _scroll,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              child: SizedBox(width: total + w, height: 92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Centre needle. Stops above the numbers so the one it points
                // at stays readable.
                Positioned(
                  top: -8,
                  height: 58,
                  left: w / 2 - 12,
                  width: 24,
                  child: IgnorePointer(
                    child: CustomPaint(painter: _NeedlePainter(c.critical)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  _TickPainter({
    required this.scroll,
    required this.spacing,
    required this.ticksPerUnit,
    required this.maxUnits,
    required this.ink,
    required this.label,
  }) : super(repaint: scroll);

  final ScrollController scroll;
  final double spacing;
  final int ticksPerUnit;
  final double maxUnits;
  final Color ink;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    final double offset = scroll.hasClients
        ? scroll.offset
        : scroll.initialScrollOffset;
    final double centre = size.width / 2;
    final int last = (maxUnits * ticksPerUnit).round();
    final int first = math.max(0, ((offset - centre) / spacing).floor());
    final int end = math.min(last, ((offset + centre) / spacing).ceil());
    final Paint p = Paint()
      ..color = ink
      ..strokeCap = StrokeCap.round;

    for (int i = first; i <= end; i++) {
      final double x = centre + i * spacing - offset;
      final bool major = i % ticksPerUnit == 0;
      final bool half = i % (ticksPerUnit ~/ 2) == 0;
      final double len = major ? 34 : (half ? 22 : 12);
      p.strokeWidth = major ? 2.6 : 1.6;
      canvas.drawLine(Offset(x, 0), Offset(x, len), p);
      if (major) {
        final TextPainter tp = TextPainter(
          text: TextSpan(text: '${i ~/ ticksPerUnit}', style: label),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(x - tp.width / 2, size.height - tp.height - 12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TickPainter old) => false;
}

class _NeedlePainter extends CustomPainter {
  _NeedlePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const Color ink = Color(0xFF141414);
    final double cx = size.width / 2;
    final Path head = Path()
      ..moveTo(cx - 10, 0)
      ..lineTo(cx + 10, 0)
      ..lineTo(cx, 14)
      ..close();
    canvas.drawLine(
      Offset(cx, 8),
      Offset(cx, size.height - 3),
      Paint()
        ..color = ink
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx, 8),
      Offset(cx, size.height - 3),
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(head, Paint()..color = color);
    canvas.drawPath(
      head,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.color != color;
}

/// A cartoon bone that stretches with the measured length, with a dimension
/// arrow over it. Before a value is set it is a dashed ghost.
class StretchyBone extends StatelessWidget {
  const StretchyBone({super.key, required this.valueCm, required this.caption});

  final double? valueCm;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        // Roughly logarithmic, so a 3 cm phalanx and a 50 cm femur both read.
        final double t = valueCm == null
            ? 0.55
            : (math.log(1 + valueCm!.clamp(0, LengthRuler.maxCm)) /
                      math.log(1 + 60))
                  .clamp(0.0, 1.0);
        final double width = 70 + (box.maxWidth - 70) * t;
        return SizedBox(
          height: 96,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              AnimatedPositioned(
                duration: const Duration(milliseconds: 120),
                bottom: 0,
                width: width,
                height: 64,
                left: (box.maxWidth - width) / 2,
                child: CustomPaint(
                  painter: _StretchPainter(
                    ghost: valueCm == null,
                    ink: c.ink,
                    shadow: c.shadow,
                    arrow: c.textPrimary,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: Text(
                    caption,
                    key: ValueKey<bool>(valueCm == null),
                    style: AppType.caption.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StretchPainter extends CustomPainter {
  _StretchPainter({
    required this.ghost,
    required this.ink,
    required this.shadow,
    required this.arrow,
  });

  final bool ghost;
  final Color ink;
  final Color shadow;
  final Color arrow;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect body = Rect.fromLTWH(3, 18, size.width - 8, size.height - 22);
    final Path bone = cartoonBonePath(body, shaft: 0.42, knob: 0.25);

    // Dimension arrow above.
    final Paint a = Paint()
      ..color = arrow
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const double y = 6;
    canvas.drawLine(Offset(body.left, y), Offset(body.right, y), a);
    canvas.drawPath(
      Path()
        ..moveTo(body.left + 6, y - 5)
        ..lineTo(body.left, y)
        ..lineTo(body.left + 6, y + 5)
        ..moveTo(body.right - 6, y - 5)
        ..lineTo(body.right, y)
        ..lineTo(body.right - 6, y + 5),
      a,
    );

    if (ghost) {
      final Paint dash = Paint()
        ..color = ink.withValues(alpha: 0.45)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (final m in bone.computeMetrics()) {
        for (double d = 0; d < m.length; d += 13) {
          canvas.drawPath(m.extractPath(d, math.min(d + 7, m.length)), dash);
        }
      }
      return;
    }

    canvas.drawPath(bone.shift(const Offset(3, 3)), Paint()..color = shadow);
    canvas.drawPath(bone, Paint()..color = const Color(0xFFFFF8EA));
    canvas.drawPath(
      bone,
      Paint()
        ..color = const Color(0xFF141414)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    // Little face so the stretching looks like effort.
    final Offset cxy = body.center;
    final Paint f = Paint()..color = const Color(0xFF141414);
    canvas.drawCircle(cxy + const Offset(-8, -3), 2.6, f);
    canvas.drawCircle(cxy + const Offset(8, -3), 2.6, f);
    canvas.drawArc(
      Rect.fromCenter(center: cxy + const Offset(0, 3), width: 10, height: 7),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = const Color(0xFF141414)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StretchPainter old) =>
      old.ghost != ghost ||
      old.ink != ink ||
      old.shadow != shadow ||
      old.arrow != arrow;
}
