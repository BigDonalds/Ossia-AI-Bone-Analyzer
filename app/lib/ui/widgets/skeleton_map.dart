import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../data/skeleton_geometry.dart';
import '../../l10n/l10n.dart';
import 'primitives.dart';

/// A whole skeleton from the front and from the back with one atlas bone lit
/// in the accent colour, so a bone page shows where the bone sits in the body.
///
/// The bones land one after another from top to bottom (the two sides of a
/// pair together), then a ring pings once around each lit area. Tapping plays
/// it again. The skeleton keeps the same colours in light and dark mode, like
/// the bone sketches.
class SkeletonMap extends StatefulWidget {
  const SkeletonMap({
    super.key,
    required this.bone,
    required this.label,
    this.delay = Duration.zero,
  });

  /// Atlas key, e.g. `femur`.
  final String bone;

  /// What a screen reader says for the two figures.
  final String label;

  /// Wait before the bones light, so they land after the page has slid in.
  final Duration delay;

  @override
  State<SkeletonMap> createState() => _SkeletonMapState();
}

class _SkeletonMapState extends State<SkeletonMap>
    with SingleTickerProviderStateMixin {
  late _Plan _plan = _Plan(widget.bone);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _plan.total),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void didUpdateWidget(SkeletonMap old) {
    super.didUpdateWidget(old);
    if (old.bone != widget.bone) {
      _plan = _Plan(widget.bone);
      _c.duration = Duration(milliseconds: _plan.total);
      _replay();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _replay() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final bool anyHidden = _plan.lit.any((String b) =>
        skeletonFront.hidden.contains(b) || skeletonBack.hidden.contains(b));

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        const double gap = 18;
        const double maxHeight = 372;
        final double aspect = skeletonViewBox[2] / skeletonViewBox[3];
        final double height =
            math.min(maxHeight, (box.maxWidth - gap) / 2 / aspect);
        final Size size = Size(height * aspect, height);

        Widget figure(SkeletonView view, String caption) => Column(
              children: <Widget>[
                CustomPaint(
                  size: size,
                  painter: _SkeletonPainter(
                    view: view,
                    plan: _plan,
                    t: _c,
                    accent: c.accent,
                    ringInk: c.ink,
                  ),
                ),
                const SizedBox(height: 10),
                ExcludeSemantics(child: StatusPill(caption)),
              ],
            );

        return Column(
          children: <Widget>[
            const SizedBox(height: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _replay,
              child: Semantics(
                image: true,
                label: widget.label,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    figure(skeletonFront, l.atlasMapFront),
                    const SizedBox(width: gap),
                    figure(skeletonBack, l.atlasMapBack),
                  ],
                ),
              ),
            ),
            if (anyHidden) ...<Widget>[
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: CustomPaint(
                      size: const Size(26, 8),
                      painter: _DashSample(c.accent),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.atlasMapHidden,
                      style: AppType.footnote
                          .copyWith(color: c.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// When each part lights, worked out once per atlas page. Times are in
/// milliseconds from the start of the animation.
class _Plan {
  factory _Plan(String key) {
    final Set<String> lit = (skeletonHighlight[key] ?? const <String>[]).toSet();
    // Top to bottom by where each bone starts; a left and right pair share a
    // slot so both sides land together.
    final Map<String, double> top = <String, double>{};
    for (final SkeletonPart p in skeletonFront.parts) {
      if (!lit.contains(p.bone)) continue;
      final String b = _base(p.bone);
      top[b] = math.min(top[b] ?? double.infinity, p.box[1]);
    }
    final List<String> order = top.keys.toList()
      ..sort((String a, String b) => top[a]!.compareTo(top[b]!));
    final double step =
        order.length > 1 ? math.min(55, 380 / (order.length - 1)) : 0;
    final Map<String, int> start = <String, int>{
      for (int i = 0; i < order.length; i++)
        order[i]: (_lead + i * step).round(),
    };
    final int landed =
        (_lead + math.max(0, order.length - 1) * step).round() + _light;
    return _Plan._(lit, start, landed, <String, List<Rect>>{
      'front': _rings(skeletonFront, lit),
      'back': _rings(skeletonBack, lit),
    });
  }

  _Plan._(this.lit, this._start, this.landed, this.rings);

  /// Lets the section's own entrance get going before anything lights.
  static const int _lead = 450;
  static const int _light = 520;
  static const int pop = 560;
  static const int shade = 340;
  static const int ghost = 420;
  static const int ring = 900;

  /// The ring starts a little before the last bone settles.
  static const int ringEarly = 140;

  final Set<String> lit;
  final Map<String, int> _start;
  final int landed;
  final Map<String, List<Rect>> rings;

  int get total => landed - ringEarly + ring;

  int lightTime() => _light;

  /// When [bone] starts lighting, or null when it stays plain.
  int? startOf(String bone) => lit.contains(bone) ? _start[_base(bone)] : null;

  static String _base(String bone) =>
      bone.endsWith('_l') || bone.endsWith('_r')
          ? bone.substring(0, bone.length - 2)
          : bone;

  /// One ring per area: lit parts closer than a small gap share one, so the
  /// ribs get one ring and the two arms one each.
  static List<Rect> _rings(SkeletonView view, Set<String> lit) {
    final Map<String, Rect> boxes = <String, Rect>{};
    for (final SkeletonPart p in view.parts) {
      if (!lit.contains(p.bone)) continue;
      final Rect r = Rect.fromLTRB(p.box[0], p.box[1], p.box[2], p.box[3]);
      boxes[p.bone] = boxes[p.bone]?.expandToInclude(r) ?? r;
    }
    final List<Rect> list = boxes.values.toList();
    bool merged = true;
    while (merged) {
      merged = false;
      search:
      for (int i = 0; i < list.length; i++) {
        for (int j = i + 1; j < list.length; j++) {
          final Rect a = list[i], b = list[j];
          final double gx = math.max(0, math.max(b.left - a.right, a.left - b.right));
          final double gy = math.max(0, math.max(b.top - a.bottom, a.top - b.bottom));
          if (gx < 14 && gy < 14) {
            list[i] = a.expandToInclude(b);
            list.removeAt(j);
            merged = true;
            break search;
          }
        }
      }
    }
    return list;
  }
}

/// The parsed paths of one part, kept for as long as the part (they are
/// constants, so for the life of the app).
class _Paths {
  _Paths(SkeletonPart p)
      : shapes = p.shapes.map(_parse).toList(),
        holes = p.holes.map(_parse).toList(),
        lines = p.lines.map(_parse).toList(),
        centre = Offset((p.box[0] + p.box[2]) / 2, (p.box[1] + p.box[3]) / 2);

  final List<Path> shapes;
  final List<Path> holes;
  final List<Path> lines;
  final Offset centre;

  late final Path dashed = _dash(shapes.first, 2.4, 2);

  static final Expando<_Paths> _cache = Expando<_Paths>();

  static _Paths of(SkeletonPart p) => _cache[p] ??= _Paths(p);

  /// Reads the absolute M/L/C/Q/Z paths that tool/make_skeleton.py writes.
  static Path _parse(String d) {
    final List<String> t = d.split(' ');
    final Path path = Path();
    int i = 0;
    double n() => double.parse(t[i++]);
    while (i < t.length) {
      switch (t[i++]) {
        case 'M':
          path.moveTo(n(), n());
        case 'L':
          path.lineTo(n(), n());
        case 'C':
          path.cubicTo(n(), n(), n(), n(), n(), n());
        case 'Q':
          path.quadraticBezierTo(n(), n(), n(), n());
        case 'Z':
          path.close();
      }
    }
    return path;
  }

  static Path _dash(Path source, double on, double off) {
    final Path out = Path();
    for (final PathMetric m in source.computeMetrics()) {
      for (double d = 0; d < m.length; d += on + off) {
        out.addPath(m.extractPath(d, math.min(d + on, m.length)), Offset.zero);
      }
    }
    return out;
  }
}

class _SkeletonPainter extends CustomPainter {
  _SkeletonPainter({
    required this.view,
    required this.plan,
    required this.t,
    required this.accent,
    required this.ringInk,
  }) : super(repaint: t);

  final SkeletonView view;
  final _Plan plan;
  final Animation<double> t;
  final Color accent;

  /// Under the accent ring; follows the theme's ink so it shows on dark.
  final Color ringInk;

  // Fixed in both themes, like the bone sketches.
  static const Color _ink = Color(0xFF141414);
  static const Color _bone = Color(0xFFFFF8EA);
  static const Color _line = Color(0xFFD6C8CF);
  static const Color _hole = Color(0xFFCDBCC5);

  /// Progress of a step that starts at [from] and lasts [length] ms.
  static double _span(double now, int from, int length) =>
      ((now - from) / length).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.height / skeletonViewBox[3];
    canvas.save();
    canvas.scale(scale);
    canvas.translate(-skeletonViewBox[0], -skeletonViewBox[1]);

    final double now = t.value * plan.total;
    final Paint fill = Paint();
    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    for (final SkeletonPart part in view.parts) {
      final _Paths p = _Paths.of(part);
      final int? start = plan.startOf(part.bone);
      if (start == null) {
        _bonePaths(canvas, p, fill, stroke, 0);
        continue;
      }
      final double lit =
          Motion.emphasized.transform(_span(now, start, plan.lightTime()));
      final double shade =
          Motion.standard.transform(_span(now, start, _Plan.shade));

      // A quick swell as the colour lands: up for the first third, then back.
      final double popT = _span(now, start, _Plan.pop);
      final double swell = popT < 0.38
          ? Motion.emphasized.transform(popT / 0.38)
          : 1 - Motion.emphasized.transform((popT - 0.38) / 0.62);
      final double s = 1 + 0.06 * swell;

      canvas.save();
      canvas.translate(p.centre.dx, p.centre.dy);
      canvas.scale(s);
      canvas.translate(-p.centre.dx, -p.centre.dy);
      if (shade > 0) {
        final Color sh = _ink.withValues(alpha: shade);
        canvas.save();
        canvas.translate(1.6 * lit, 1.6 * lit);
        for (final Path path in p.shapes) {
          canvas.drawPath(path, fill..color = sh);
          canvas.drawPath(path, stroke
            ..color = sh
            ..strokeWidth = 2.1);
        }
        canvas.restore();
      }
      _bonePaths(canvas, p, fill, stroke, lit);
      canvas.restore();
    }

    // Dashed outlines over lit bones that are mostly covered from this side.
    final double ghost =
        Motion.standard.transform(_span(now, plan.landed, _Plan.ghost));
    if (ghost > 0) {
      for (final SkeletonPart part in view.parts) {
        if (!view.hidden.contains(part.bone) || !plan.lit.contains(part.bone)) {
          continue;
        }
        final Path dashed = _Paths.of(part).dashed;
        canvas.drawPath(dashed, stroke
          ..color = _ink.withValues(alpha: ghost)
          ..strokeWidth = 1.9);
        canvas.drawPath(dashed, stroke
          ..color = accent.withValues(alpha: ghost)
          ..strokeWidth = 0.85);
      }
    }

    // One ring pings outwards around each lit area and fades.
    final double ringT =
        _span(now, plan.landed - _Plan.ringEarly, _Plan.ring);
    if (ringT > 0 && ringT < 1) {
      final double alpha = ringT < 0.18
          ? Motion.standard.transform(ringT / 0.18)
          : 1 - Motion.standard.transform((ringT - 0.18) / 0.82);
      final double grow = 0.88 + 0.28 * Motion.standard.transform(ringT);
      for (final Rect r in plan.rings[view == skeletonBack ? 'back' : 'front']!) {
        final Rect ring = Rect.fromCenter(
          center: r.center,
          width: (r.width / 2 + 7 + r.width * 0.04) * 2 * grow,
          height: (r.height / 2 + 7 + r.height * 0.03) * 2 * grow,
        );
        canvas.drawOval(ring, stroke
          ..color = ringInk.withValues(alpha: alpha)
          ..strokeWidth = 4.4 * grow);
        canvas.drawOval(ring, stroke
          ..color = accent.withValues(alpha: alpha)
          ..strokeWidth = 2.4 * grow);
      }
    }
    canvas.restore();
  }

  /// Outline under the fill so only its outer half shows, then the solid
  /// holes and the detail lines. [lit] runs from plain (0) to lit (1).
  void _bonePaths(Canvas canvas, _Paths p, Paint fill, Paint stroke, double lit) {
    final Color edge = Color.lerp(_line, _ink, lit)!;
    stroke
      ..color = edge
      ..strokeWidth = 1.5 + 0.6 * lit;
    for (final Path path in p.shapes) {
      canvas.drawPath(path, stroke);
    }
    fill.color = Color.lerp(_bone, accent, lit)!;
    for (final Path path in p.shapes) {
      canvas.drawPath(path, fill);
    }
    fill.color = Color.lerp(_hole, _ink, lit)!;
    for (final Path path in p.holes) {
      canvas.drawPath(path, fill);
    }
    stroke
      ..color = edge
      ..strokeWidth = 0.7;
    for (final Path path in p.lines) {
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(_SkeletonPainter old) =>
      old.view != view ||
      old.plan != plan ||
      old.accent != accent ||
      old.ringInk != ringInk;
}

/// The short dashed line in the legend under the figures.
class _DashSample extends CustomPainter {
  _DashSample(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final double y = size.height / 2;
    for (double x = 2; x < size.width - 2; x += 7.8) {
      final Offset a = Offset(x, y);
      final Offset b = Offset(math.min(x + 4.4, size.width - 2), y);
      canvas.drawLine(a, b, p
        ..color = const Color(0xFF141414)
        ..strokeWidth = 3.6);
      canvas.drawLine(a, b, p
        ..color = accent
        ..strokeWidth = 1.8);
    }
  }

  @override
  bool shouldRepaint(_DashSample old) => old.accent != accent;
}
