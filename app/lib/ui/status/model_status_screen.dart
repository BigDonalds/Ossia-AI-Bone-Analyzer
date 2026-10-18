import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/on_device/on_device_model.dart';
import '../../data/on_device/model_spec.dart';
import '../../data/server_monitor.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/engine_toggle.dart';
import '../widgets/inset_group.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import '../widgets/stat_icon.dart';
import 'link_pill.dart';

/// Is Ossia ready to analyze? Switches between analyzing on this phone and
/// online. On the phone it shows the built-in analyzer at work; online, a live
/// phone ↔ computer scene, a step-by-step check, the connection's speed and
/// history. Runs a full check whenever it opens online.
class ModelStatusScreen extends StatefulWidget {
  const ModelStatusScreen({super.key});

  @override
  State<ModelStatusScreen> createState() => _ModelStatusScreenState();
}

class _ModelStatusScreenState extends State<ModelStatusScreen> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ServerMonitor m = context.read<ServerMonitor>();
      if (m.state != LinkState.onDevice) m.fullCheck();
      context.read<OnDeviceModel>().describe();
    });
    // Keeps "checked 12 s ago" and the countdown ring moving.
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _editAddress() async {
    final SettingsController s = context.read<SettingsController>();
    final AppLocalizations l = context.l10n;
    final String? url = await promptForText(
      context,
      title: l.settingsOnlineAddress,
      message: l.settingsOnlineAddressBody,
      initial: s.serverUrl,
      placeholder: 'https://…',
      keyboard: TextInputType.url,
    );
    if (url == null || url.trim().isEmpty || !mounted) return;
    s.setServerUrl(url);
    await context.read<ServerMonitor>().fullCheck();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final ServerMonitor m = context.watch<ServerMonitor>();
    final SettingsController s = context.watch<SettingsController>();
    final OnDeviceModel local = context.watch<OnDeviceModel>();
    final bool onDevice = m.state == LinkState.onDevice;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: <Widget>[
          DetailBar(title: l.settingsStatus),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 18, 12, 130 + MediaQuery.paddingOf(context).bottom),
              children: <Widget>[
                Reveal(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (Widget child, Animation<double> a) =>
                        FadeTransition(
                      opacity: a,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1).animate(a),
                        child: child,
                      ),
                    ),
                    child: onDevice
                        ? _OnDeviceScene(key: const ValueKey<String>('phone'), status: local.status)
                        : _LinkScene(key: const ValueKey<String>('online'), monitor: m),
                  ),
                ),
                const SizedBox(height: 18),
                Reveal(
                  delay: const Duration(milliseconds: 40),
                  child: EngineToggle(
                    value: s.engine,
                    onChanged: (EngineMode v) {
                      s.setEngine(v);
                      if (v == EngineMode.server) m.fullCheck();
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Reveal(
                  delay: const Duration(milliseconds: 80),
                  child: _Headline(monitor: m),
                ),
                const SizedBox(height: 20),
                Reveal(
                  delay: const Duration(milliseconds: 120),
                  child: onDevice
                      ? _OnDeviceDetails(model: local)
                      : _Checklist(monitor: m),
                ),
                if (!onDevice) ...<Widget>[
                  const SizedBox(height: 18),
                  Reveal(
                    delay: const Duration(milliseconds: 180),
                    child: _StatsGrid(monitor: m),
                  ),
                  const SizedBox(height: 14),
                  Reveal(
                    delay: const Duration(milliseconds: 240),
                    child: _PingHistory(monitor: m),
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: m.fullCheckRunning ? l.statusChecking : l.statusCheckNow,
                    icon: Icons.wifi_tethering_rounded,
                    onTap: m.fullCheckRunning
                        ? null
                        : () {
                            Haptics.medium();
                            m.fullCheck();
                          },
                  ),
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: l.statusChangeAddress,
                    icon: Icons.link_rounded,
                    onTap: _editAddress,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Scene ─────────────────────────────────────────────────────────────────────

class _LinkScene extends StatefulWidget {
  const _LinkScene({super.key, required this.monitor});

  final ServerMonitor monitor;

  @override
  State<_LinkScene> createState() => _LinkSceneState();
}

class _LinkSceneState extends State<_LinkScene> with TickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  /// 0 → 1 outbound, 1 → 2 back home.
  late final AnimationController _packet = AnimationController(
    vsync: this,
    upperBound: 2,
    duration: const Duration(milliseconds: 650),
  );

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  late final AnimationController _bubble = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  StreamSubscription<PingEvent>? _sub;
  TickerFuture? _outbound;
  bool _packetVisible = false;
  double _burstAt = 0.5;
  int? _bubbleMs;

  @override
  void initState() {
    super.initState();
    _sub = widget.monitor.pings.listen(_onPing);
  }

  Future<void> _onPing(PingEvent e) async {
    if (!mounted) return;
    switch (e) {
      case PingSent():
        setState(() => _packetVisible = true);
        _packet.value = 0;
        _outbound = _packet.animateTo(1, duration: const Duration(milliseconds: 650), curve: Curves.easeInOut);
      case PingReturned(:final int ms):
        await _outbound;
        if (!mounted) return;
        await _packet.animateTo(2, duration: const Duration(milliseconds: 650), curve: Curves.easeInOut);
        if (!mounted) return;
        Haptics.tap();
        setState(() {
          _packetVisible = false;
          _bubbleMs = ms;
        });
        _bubble.forward(from: 0);
      case PingLost():
        _packet.stop();
        final double v = _packet.value;
        setState(() {
          _packetVisible = false;
          _burstAt = v > 1 ? 2 - v : v;
        });
        _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ambient.dispose();
    _packet.dispose();
    _burst.dispose();
    _bubble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final LinkState state = widget.monitor.state;

    final BuddyMood mood = switch (state) {
      LinkState.online => BuddyMood.happy,
      LinkState.offline => BuddyMood.sad,
      LinkState.onDevice => BuddyMood.happy,
      _ => BuddyMood.thinking,
    };

    return Chunk(
      color: c.accent,
      radius: 28,
      shadow: 6,
      clip: true,
      child: SizedBox(
        height: 224,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final double w = box.maxWidth;
            final Offset phoneAnchor = const Offset(98, 118);
            final Offset serverAnchor = Offset(w - 110, 118);
            final Offset ctrl = Offset(w / 2, 26);

            Offset along(double t) {
              final double u = 1 - t;
              return phoneAnchor * (u * u) + ctrl * (2 * u * t) + serverAnchor * (t * t);
            }

            return AnimatedBuilder(
              animation: Listenable.merge(<Listenable>[_ambient, _packet, _burst, _bubble]),
              builder: (BuildContext context, _) {
                final double v = _packet.value;
                final double t = v <= 1 ? v : 2 - v;
                final Offset packetAt = along(t);
                final Offset burstPos = along(_burstAt);
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    // Cable, packet, radar and sparks.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _CablePainter(
                          from: phoneAnchor,
                          ctrl: ctrl,
                          to: serverAnchor,
                          state: state,
                          phase: _ambient.value,
                          packet: _packetVisible ? packetAt : null,
                          packetBack: v > 1,
                          burst: _burst.isAnimating ? burstPos : null,
                          burstT: _burst.value,
                          ink: const Color(0xFF141414),
                          glow: Colors.white,
                          critical: c.critical,
                          positive: c.positive,
                        ),
                      ),
                    ),
                    // Phone.
                    Positioned(
                      left: 18,
                      top: 56,
                      child: Transform.rotate(
                        angle: -0.06 + math.sin(_ambient.value * 2 * math.pi) * 0.015,
                        child: _Phone(mood: mood),
                      ),
                    ),
                    // Server.
                    Positioned(
                      right: 20,
                      top: 50,
                      child: _Server(
                        state: state,
                        phase: _ambient.value,
                      ),
                    ),
                    // Broken link marker, floating in the gap above the
                    // dangling ends.
                    if (state == LinkState.offline)
                      Positioned(
                        left: (phoneAnchor.dx + serverAnchor.dx) / 2 - 17,
                        top: 52 + math.sin(_ambient.value * 2 * math.pi) * 4,
                        child: Transform.scale(
                          scale: 1 + 0.06 * math.sin(_ambient.value * 4 * math.pi),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c.critical,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF141414), width: 2.2),
                            ),
                            child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    // Latency bubble.
                    if (_bubbleMs != null && _bubble.isAnimating)
                      Positioned(
                        left: along(0.5).dx - 48,
                        top: along(0.5).dy - 4 - 22 * Curves.easeOut.transform(_bubble.value.clamp(0, 0.3) / 0.3),
                        width: 96,
                        child: Opacity(
                          opacity: _bubble.value < 0.75 ? 1 : (1 - (_bubble.value - 0.75) / 0.25),
                          child: Transform.scale(
                            scale: Curves.elasticOut.transform((_bubble.value / 0.35).clamp(0, 1)),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(10, 4, 10, 5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: const Color(0xFF141414), width: 2),
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(color: Color(0xFF141414), offset: Offset(2, 2)),
                                  ],
                                ),
                                child: Text(
                                  l.msShort(_bubbleMs!),
                                  style: AppType.metric.copyWith(
                                    color: const Color(0xFF141414),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Labels.
                    Positioned(
                      left: 18,
                      bottom: 12,
                      width: 74,
                      child: _NodeLabel(l.statusYou),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 12,
                      width: 88,
                      child: _NodeLabel(
                        state == LinkState.onDevice
                            ? l.statusNapping
                            : l.appName.toUpperCase(),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: AppType.button.copyWith(
          color: const Color(0xFF141414),
          fontSize: 12,
          letterSpacing: AppType.tracking(1.4),
        ),
      ),
    );
  }
}

class _Phone extends StatelessWidget {
  const _Phone({required this.mood});

  final BuddyMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 124,
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF141414), width: 2.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0xFF141414), offset: Offset(3, 3)),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE8F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF141414), width: 1.6),
        ),
        alignment: Alignment.center,
        child: BoneBuddy(size: 52, mood: mood, tilt: -0.2),
      ),
    );
  }
}

class _Server extends StatelessWidget {
  const _Server({required this.state, required this.phase});

  final LinkState state;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color led = switch (state) {
      LinkState.online => c.positive,
      LinkState.offline => c.critical,
      LinkState.onDevice => const Color(0xFFB9B9C2),
      _ => c.sticker(3),
    };
    final bool asleep = state == LinkState.onDevice;

    Widget slot(int i) {
      // Each light blinks on its own beat.
      final double beat = (phase * (i + 2) + i * 0.37) % 1;
      final bool on = switch (state) {
        LinkState.online => beat < 0.7,
        LinkState.offline => phase < 0.5,
        LinkState.onDevice => false,
        _ => beat < 0.5,
      };
      return Container(
        height: 22,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2833),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF141414), width: 1.6),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: on ? led : led.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: (on && i.isEven) ? led : led.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
            const Spacer(),
            Container(
              width: 18,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: 88,
          height: 130,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3B3945),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF141414), width: 2.4),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0xFF141414), offset: Offset(3, 3)),
            ],
          ),
          child: Column(children: <Widget>[slot(0), slot(1), slot(2)]),
        ),
        if (asleep)
          Positioned(
            right: -6,
            top: -18 - 6 * math.sin(phase * 2 * math.pi),
            child: Text(
              'z z',
              style: AppType.title3.copyWith(color: const Color(0xFF141414)),
            ),
          ),
      ],
    );
  }
}

class _CablePainter extends CustomPainter {
  _CablePainter({
    required this.from,
    required this.ctrl,
    required this.to,
    required this.state,
    required this.phase,
    required this.packet,
    required this.packetBack,
    required this.burst,
    required this.burstT,
    required this.ink,
    required this.glow,
    required this.critical,
    required this.positive,
  });

  final Offset from;
  final Offset ctrl;
  final Offset to;
  final LinkState state;
  final double phase;
  final Offset? packet;
  final bool packetBack;
  final Offset? burst;
  final double burstT;
  final Color ink;
  final Color glow;
  final Color critical;
  final Color positive;

  @override
  void paint(Canvas canvas, Size size) {
    final Path cable = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, to.dx, to.dy);

    // Radar rings around the server while it's answering.
    if (state == LinkState.online || state == LinkState.checking || state == LinkState.unknown) {
      final Offset centre = to + const Offset(44, -2);
      for (int i = 0; i < 2; i++) {
        final double t = (phase + i * 0.5) % 1;
        canvas.drawCircle(
          centre,
          40 + 50 * t,
          Paint()
            ..color = ink.withValues(alpha: 0.35 * (1 - t))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }
    }

    final bool faded = state == LinkState.onDevice;
    final Paint base = Paint()
      ..color = ink.withValues(alpha: faded ? 0.3 : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final Paint inner = Paint()
      ..color = Colors.white.withValues(alpha: faded ? 0.4 : 1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final metric = cable.computeMetrics().first;
    final double len = metric.length;

    if (state == LinkState.offline) {
      _unplugged(canvas, base, inner);
    } else {
      canvas.drawPath(cable, base);
      // Marching light along the cable.
      const double dash = 10;
      const double gapLen = 10;
      final double offset = (faded ? 0 : phase) * (dash + gapLen) * 2;
      for (double d = -dash - gapLen + offset % (dash + gapLen); d < len; d += dash + gapLen) {
        final double a = math.max(0, d);
        final double b = math.min(len, d + dash);
        if (b > a) canvas.drawPath(metric.extractPath(a, b), inner);
      }
    }

    // The ping itself: a glowing little bone.
    if (packet != null) {
      final Offset p = packet!;
      canvas.drawCircle(p, 17, Paint()..color = glow.withValues(alpha: 0.55));
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(packetBack ? math.pi + 0.3 : -0.3);
      final Path bone = cartoonBonePath(const Rect.fromLTWH(-13, -6.5, 26, 13), shaft: 0.46, knob: 0.26);
      canvas.drawPath(bone, Paint()..color = const Color(0xFFFFF8EA));
      canvas.drawPath(
        bone,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2,
      );
      canvas.restore();
    }

    // A lost ping goes poof.
    if (burst != null) {
      final Offset b = burst!;
      final double t = Curves.easeOut.transform(burstT);
      final Paint puff = Paint()
        ..color = ink.withValues(alpha: 1 - t)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < 8; i++) {
        final double a = i * math.pi / 4;
        final Offset dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(b + dir * (6 + 10 * t), b + dir * (12 + 18 * t), puff);
      }
    }
  }

  /// Offline: the cable has come apart. Each half hangs from its end with a
  /// lazy sway, a plug on the phone's side and a socket on the server's, with
  /// the odd spark jumping off the loose ends.
  void _unplugged(Canvas canvas, Paint base, Paint inner) {
    final double mid = (from.dx + to.dx) / 2;
    final double a = phase * 2 * math.pi;

    // Loose ends sway a little, out of step with each other.
    final Offset leftEnd = Offset(mid - 30 + math.sin(a) * 5, 158 + math.cos(a) * 2);
    final Offset rightEnd = Offset(mid + 30 + math.sin(a + 1.9) * 5, 162 + math.cos(a + 1.9) * 2);

    // Each half leaves its node heading inwards, rises a touch, then bends
    // over and hangs down — a smooth droop rather than a fold.
    final Path left = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx + 44, from.dy - 22, leftEnd.dx + 4, leftEnd.dy - 70, leftEnd.dx, leftEnd.dy);
    final Path right = Path()
      ..moveTo(to.dx, to.dy)
      ..cubicTo(to.dx - 44, to.dy - 22, rightEnd.dx - 4, rightEnd.dy - 70, rightEnd.dx, rightEnd.dy);

    final Paint dim = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = inner.strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final (Path p, bool plug) in <(Path, bool)>[(left, true), (right, false)]) {
      canvas.drawPath(p, base);
      canvas.drawPath(p, dim);
      final PathMetric m = p.computeMetrics().first;
      final Tangent? end = m.getTangentForOffset(m.length);
      if (end == null) continue;
      final double angle = math.atan2(end.vector.dy, end.vector.dx);

      canvas.save();
      canvas.translate(end.position.dx, end.position.dy);
      canvas.rotate(angle);
      if (plug) {
        _plug(canvas);
      } else {
        _socket(canvas);
      }
      canvas.restore();

      // A spark every so often, left and right taking turns.
      final double beat = (phase * 2 + (plug ? 0 : 0.5)) % 1;
      if (beat < 0.16) {
        final Offset tip = end.position + Offset(math.cos(angle), math.sin(angle)) * (plug ? 26 : 20);
        _spark(canvas, tip, beat / 0.16, flip: !plug);
      }
    }
  }

  void _plug(Canvas canvas) {
    final Paint outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    final RRect body = RRect.fromLTRBR(-2, -8, 15, 8, const Radius.circular(4));
    canvas.drawRRect(body, Paint()..color = Colors.white);
    canvas.drawRRect(body, outline);
    final Paint metal = Paint()..color = ink;
    canvas.drawRRect(RRect.fromLTRBR(15, -5.5, 23, -2, const Radius.circular(1.2)), metal);
    canvas.drawRRect(RRect.fromLTRBR(15, 2, 23, 5.5, const Radius.circular(1.2)), metal);
  }

  void _socket(Canvas canvas) {
    final Paint outline = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round;
    final RRect body = RRect.fromLTRBR(-2, -9, 16, 9, const Radius.circular(5));
    canvas.drawRRect(body, Paint()..color = Colors.white);
    canvas.drawRRect(body, outline);
    final Paint hole = Paint()..color = ink;
    canvas.drawRRect(RRect.fromLTRBR(9, -5.5, 14, -2.5, const Radius.circular(1)), hole);
    canvas.drawRRect(RRect.fromLTRBR(9, 2.5, 14, 5.5, const Radius.circular(1)), hole);
  }

  /// A little yellow lightning bolt that pops and fades.
  void _spark(Canvas canvas, Offset at, double t, {required bool flip}) {
    final double s = 0.6 + 0.6 * math.sin(t * math.pi);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(flip ? -s : s, s);
    canvas.rotate(-0.4);
    final Path bolt = Path()
      ..moveTo(-2, -11)
      ..lineTo(5, -11)
      ..lineTo(1, -2)
      ..lineTo(6, -2)
      ..lineTo(-4, 11)
      ..lineTo(-1, 1)
      ..lineTo(-6, 1)
      ..close();
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFE45C));
    canvas.drawPath(
      bolt,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CablePainter old) => true;
}

// ── Headline ─────────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  const _Headline({required this.monitor});

  final ServerMonitor monitor;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final ServerMonitor m = monitor;
    final (Color tone, String chip) = linkLook(context, m);

    final OnDeviceModel local = context.watch<OnDeviceModel>();
    final (String title, String body) = switch (m.state) {
      LinkState.online => (
          l.statusConnected,
          l.statusConnectedBody('${m.latencyMs ?? '?'}')
        ),
      LinkState.offline => (
          l.linkCantConnect,
          l.statusOfflineBody(m.error?.call(l) ?? l.statusNoAnswer)
        ),
      LinkState.onDevice when local.status == OnDeviceStatus.failed => (
          l.statusFailedTitle,
          l.statusFailedBody
        ),
      LinkState.onDevice => (l.statusOnPhoneTitle, l.statusOnPhoneBody),
      _ => (l.linkConnecting, l.statusConnectingBody),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              StatusPill(chip, color: tone, filled: true),
              const Spacer(),
              if (m.lastChecked != null)
                Text(
                  _checked(l, m.lastChecked!),
                  style: AppType.caption.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              title,
              key: ValueKey<String>(title),
              style: AppType.title1.copyWith(color: c.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: AppType.subhead.copyWith(color: c.textSecondary, height: 1.42),
          ),
        ],
      ),
    );
  }
}

/// "checked just now", "checked 12s ago", "checked 5 min ago".
String _checked(AppLocalizations l, DateTime t) {
  final int s = DateTime.now().difference(t).inSeconds;
  final String when = s < 5
      ? l.justNow
      : s < 60
          ? l.secondsAgo(s)
          : l.relativeTime(t);
  // It sits mid-sentence, so "Just now" becomes "just now".
  return l.statusChecked(when[0].toLowerCase() + when.substring(1));
}

// ── Checklist ────────────────────────────────────────────────────────────────

class _Checklist extends StatelessWidget {
  const _Checklist({required this.monitor});

  final ServerMonitor monitor;

  static const Map<String, IconData> _icons = <String, IconData>{
    'address': Icons.link_rounded,
    'reach': Icons.wifi_tethering_rounded,
    'server': Icons.dns_rounded,
    'model': Icons.psychology_rounded,
    'ping': Icons.speed_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    return InsetGroup(
      margin: EdgeInsets.zero,
      separatorIndent: 66,
      children: <Widget>[
        for (final (int i, CheckStep step) in monitor.steps.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
            child: Row(
              children: <Widget>[
                StatIcon(icon: _icons[step.id]!, color: c.sticker(i)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        step.title(l),
                        style: AppType.body.copyWith(
                          color: step.status == StepStatus.skipped
                              ? c.textTertiary
                              : c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: AlignmentDirectional.topStart,
                        child: step.detail == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  step.detail!(l),
                                  style: AppType.footnote.copyWith(
                                    color: step.status == StepStatus.failed
                                        ? c.critical
                                        : c.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _StepBadge(status: step.status),
              ],
            ),
          ),
      ],
    );
  }
}

class _StepBadge extends StatefulWidget {
  const _StepBadge({required this.status});

  final StepStatus status;

  @override
  State<_StepBadge> createState() => _StepBadgeState();
}

class _StepBadgeState extends State<_StepBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    const Color ink = Color(0xFF141414);

    Widget sticker(Color fill, IconData icon, Color fg) => Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: ink, width: 2),
          ),
          child: Icon(icon, size: 18, color: fg),
        );

    final Widget child = switch (widget.status) {
      StepStatus.pending => Container(
          key: const ValueKey<String>('pending'),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: c.separator, width: 2.5),
          ),
        ),
      StepStatus.running => RotationTransition(
          key: const ValueKey<String>('running'),
          turns: _spin,
          child: const SizedBox(
            width: 30,
            height: 30,
            child: CustomPaint(painter: _SpinBonePainter()),
          ),
        ),
      StepStatus.passed => KeyedSubtree(
          key: const ValueKey<String>('passed'),
          child: sticker(c.positive, Icons.check_rounded, Colors.white),
        ),
      StepStatus.failed => KeyedSubtree(
          key: const ValueKey<String>('failed'),
          child: sticker(c.critical, Icons.close_rounded, Colors.white),
        ),
      StepStatus.skipped => KeyedSubtree(
          key: const ValueKey<String>('skipped'),
          child: sticker(c.fill, Icons.remove_rounded, c.textTertiary),
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.elasticOut,
      transitionBuilder: (Widget w, Animation<double> a) =>
          ScaleTransition(scale: a, child: w),
      child: child,
    );
  }
}

class _SpinBonePainter extends CustomPainter {
  const _SpinBonePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Rect r = Rect.fromCenter(
        center: size.center(Offset.zero), width: size.width * 0.9, height: size.width * 0.45);
    final Path bone = cartoonBonePath(r, shaft: 0.46, knob: 0.26);
    canvas.drawPath(bone, Paint()..color = const Color(0xFFFFF8EA));
    canvas.drawPath(
      bone,
      Paint()
        ..color = const Color(0xFF141414)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpinBonePainter old) => false;
}

// ── Stats & history ──────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.monitor});

  final ServerMonitor monitor;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final ServerMonitor m = monitor;
    final bool live = m.state == LinkState.online;

    return Row(
      children: <Widget>[
        _StatTile(
          index: 0,
          icon: Icons.speed_rounded,
          label: l.checkSpeed,
          value: live && m.latencyMs != null
              ? l.checkPing(m.latencyMs!, l.pingWord(m.latencyMs!))
              : '--',
        ),
        const SizedBox(width: 6),
        _StatTile(
          index: 1,
          icon: Icons.timer_rounded,
          label: l.statusRunningFor,
          value: live ? l.uptime(m.uptimeSeconds) : '--',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.index,
    required this.icon,
    required this.label,
    required this.value,
  });

  final int index;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Expanded(
      child: Chunk(
        color: c.surface,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                StatIcon(icon: icon, color: c.sticker(index), size: 30),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: AppType.caption.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Fixed height, so a long value shrunk to fit doesn't make its
            // tile shorter than the one beside it.
            SizedBox(
              height: 30,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppType.title2.copyWith(color: c.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PingHistory extends StatelessWidget {
  const _PingHistory({required this.monitor});

  final ServerMonitor monitor;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final List<int?> h = monitor.history;
    final DateTime? next = monitor.nextCheck;
    final int left = next == null ? 0 : math.max(0, next.difference(DateTime.now()).inSeconds);
    final double progress = next == null
        ? 0
        : 1 - left / ServerMonitor.interval.inSeconds;

    Color toneFor(int? ms) {
      if (ms == null) return c.critical;
      if (ms < 150) return c.positive;
      if (ms < 400) return c.accent;
      if (ms < 1000) return c.caution;
      return c.critical;
    }

    return Chunk(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.statusHistory,
                  style: AppType.headline.copyWith(color: c.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 3,
                  color: c.textPrimary,
                  backgroundColor: c.fill,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                next == null ? l.statusAutoPaused : l.statusNextIn(left),
                style: AppType.caption.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: h.isEmpty
                ? Center(
                    child: Text(
                      l.statusNoChecks,
                      style: AppType.footnote.copyWith(color: c.textTertiary),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      for (int i = 0; i < ServerMonitor.historyLength; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _bar(
                              i - (ServerMonitor.historyLength - h.length) < 0
                                  ? const _Empty()
                                  : h[i - (ServerMonitor.historyLength - h.length)],
                              toneFor,
                              c,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            l.statusHistoryFooter(ServerMonitor.interval.inSeconds),
            style: AppType.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _bar(Object? entry, Color Function(int?) toneFor, AppColors c) {
    if (entry is _Empty) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    final int? ms = entry as int?;
    final double height = ms == null ? 64 : 10 + 54 * (math.min(ms, 1000) / 1000);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: height),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double v, _) => Container(
        height: v.clamp(0, 64),
        decoration: BoxDecoration(
          color: toneFor(ms),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: c.ink, width: 1.4),
        ),
        child: ms == null && v > 20
            ? const Icon(Icons.close_rounded, size: 10, color: Colors.white)
            : null,
      ),
    );
  }
}

class _Empty {
  const _Empty();
}

// ── On this phone ───────────────────────────────────────────────────────────

/// The phone doing the work by itself: it bobs at the centre with a pulse
/// spreading from it, while three badges (offline, private, quick) circle it,
/// passing behind on the far side of their orbit.
class _OnDeviceScene extends StatefulWidget {
  const _OnDeviceScene({super.key, required this.status});

  final OnDeviceStatus status;

  @override
  State<_OnDeviceScene> createState() => _OnDeviceSceneState();
}

class _OnDeviceSceneState extends State<_OnDeviceScene> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  )..repeat();

  static const List<IconData> _badges = <IconData>[
    Icons.wifi_off_rounded,
    Icons.lock_rounded,
    Icons.bolt_rounded,
  ];

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final BuddyMood mood = switch (widget.status) {
      OnDeviceStatus.ready => BuddyMood.happy,
      OnDeviceStatus.loading => BuddyMood.thinking,
      OnDeviceStatus.failed => BuddyMood.sad,
      OnDeviceStatus.idle => BuddyMood.wink,
    };

    return Chunk(
      color: c.accent,
      radius: 28,
      shadow: 6,
      clip: true,
      child: SizedBox(
        height: 224,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final Offset centre = Offset(box.maxWidth / 2, 104);
            return AnimatedBuilder(
              animation: _t,
              builder: (BuildContext context, _) {
                final double v = _t.value;
                Widget badge(int i) {
                  final double a = (v + i / _badges.length) * 2 * math.pi;
                  final double depth = (math.sin(a) + 1) / 2; // 0 far, 1 near
                  final double size = 30 + 8 * depth;
                  return Positioned(
                    left: centre.dx + math.cos(a) * (box.maxWidth * 0.34) - size / 2,
                    top: centre.dy + math.sin(a) * 52 - size / 2,
                    child: Opacity(
                      opacity: 0.55 + 0.45 * depth,
                      child: Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF141414), width: 2),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(color: Color(0xFF141414), offset: Offset(2, 2)),
                          ],
                        ),
                        child: Icon(_badges[i], size: size * 0.5, color: const Color(0xFF141414)),
                      ),
                    ),
                  );
                }

                final List<int> behind = <int>[
                  for (int i = 0; i < _badges.length; i++)
                    if (math.sin((v + i / _badges.length) * 2 * math.pi) < 0) i,
                ];
                final List<int> front = <int>[
                  for (int i = 0; i < _badges.length; i++)
                    if (!behind.contains(i)) i,
                ];
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    // Pulse rings spreading from the phone.
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PulsePainter(
                          centre: centre,
                          phase: v * 3 % 1,
                          working: widget.status != OnDeviceStatus.failed,
                        ),
                      ),
                    ),
                    for (final int i in behind) badge(i),
                    Positioned(
                      left: centre.dx - 37,
                      top: centre.dy - 66 + math.sin(v * 4 * math.pi) * 4,
                      child: Transform.rotate(
                        angle: math.sin(v * 2 * math.pi) * 0.05,
                        child: _Phone(mood: mood),
                      ),
                    ),
                    for (final int i in front) badge(i),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: _NodeLabel(l.statusAllOnPhone),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({required this.centre, required this.phase, required this.working});

  final Offset centre;
  final double phase;
  final bool working;

  @override
  void paint(Canvas canvas, Size size) {
    if (!working) return;
    for (int k = 0; k < 2; k++) {
      final double t = (phase + k * 0.5) % 1;
      canvas.drawCircle(
        centre,
        50 + 110 * t,
        Paint()
          ..color = const Color(0xFF141414).withValues(alpha: 0.28 * (1 - t))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.phase != phase || old.working != working;
}

/// Plain facts about analyzing on the phone, and a way to get it ready.
class _OnDeviceDetails extends StatelessWidget {
  const _OnDeviceDetails({required this.model});

  final OnDeviceModel model;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final OnDeviceStatus status = model.status;
    final ModelSpec? spec = model.spec;
    final DateTime? version = spec == null ? null : DateTime.tryParse(spec.exported);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InsetGroup(
          margin: const EdgeInsets.only(right: 4),
          children: <Widget>[
            InsetRow(
              leading: StatIcon(icon: Icons.power_settings_new_rounded, color: c.sticker(0), size: 32),
              title: l.statusRow,
              subtitle: status == OnDeviceStatus.idle ? l.statusWakesUp : null,
              value: switch (status) {
                OnDeviceStatus.idle => l.statusSleeping,
                OnDeviceStatus.loading => l.statusGettingReady,
                OnDeviceStatus.ready => l.checkReady,
                OnDeviceStatus.failed => l.statusCouldntStart,
              },
            ),
            InsetRow(
              leading: StatIcon(icon: Icons.wifi_off_rounded, color: c.sticker(1), size: 32),
              title: l.statusInternetNeeded,
              value: l.statusNo,
            ),
            InsetRow(
              leading: StatIcon(icon: Icons.lock_rounded, color: c.sticker(2), size: 32),
              title: l.statusPhotosSent,
              value: l.statusNever,
            ),
            if (version != null)
              InsetRow(
                leading: StatIcon(icon: Icons.update_rounded, color: c.sticker(3), size: 32),
                title: l.settingsVersion,
                value: l.shortDate(version),
              ),
          ],
        ),
        if (status != OnDeviceStatus.ready) ...<Widget>[
          const SizedBox(height: 18),
          PrimaryButton(
            label: switch (status) {
              OnDeviceStatus.loading => l.statusGettingReady,
              OnDeviceStatus.failed => l.tryAgain,
              _ => l.statusGetReady,
            },
            icon: Icons.bolt_rounded,
            onTap: status == OnDeviceStatus.loading
                ? null
                : () {
                    Haptics.medium();
                    model.ensureLoaded().catchError((Object _) {});
                  },
          ),
        ],
      ],
    );
  }
}
