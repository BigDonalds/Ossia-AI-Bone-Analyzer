import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../data/on_device/on_device_model.dart';
import '../../data/server_monitor.dart';
import '../../l10n/l10n.dart';
import '../widgets/primitives.dart';
import '../widgets/text_fit.dart';
import 'model_status_screen.dart';

/// Colour and short label for a link state, shared by the pill, the settings
/// row and the status page.
(Color, String) linkLook(BuildContext context, ServerMonitor m) {
  final AppColors c = context.colors;
  final AppLocalizations l = context.l10n;
  return switch (m.state) {
    LinkState.onDevice =>
      context.watch<OnDeviceModel>().status == OnDeviceStatus.failed
          ? (c.critical, l.linkNotReady)
          : (c.positive, l.linkOnPhone),
    LinkState.unknown || LinkState.checking => (c.sticker(3), l.linkConnecting),
    LinkState.online => (
        c.positive,
        m.latencyMs == null ? l.linkOnline : l.linkOnlineMs(m.latencyMs!)
      ),
    LinkState.offline => (c.critical, l.linkCantConnect),
  };
}

void openModelStatus(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ModelStatusScreen()),
    );

/// A status dot that breathes while the model is live or being checked.
class LinkDot extends StatefulWidget {
  const LinkDot({super.key, this.size = 10});

  final double size;

  @override
  State<LinkDot> createState() => _LinkDotState();
}

class _LinkDotState extends State<LinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ServerMonitor m = context.watch<ServerMonitor>();
    final AppColors c = context.colors;
    final (Color tone, _) = linkLook(context, m);
    final bool alive = m.state == LinkState.online ||
        m.state == LinkState.checking ||
        m.state == LinkState.unknown;
    final double s = widget.size;

    return SizedBox(
      width: s * 2,
      height: s * 2,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (BuildContext context, _) {
          final double t = _pulse.value;
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (alive)
                Container(
                  width: s + s * 1.1 * t,
                  height: s + s * 1.1 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: 0.45 * (1 - t)),
                  ),
                ),
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.ink, width: 1.5),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The tappable status pill in the Home header.
class LinkPill extends StatelessWidget {
  const LinkPill({super.key, this.chevron = true});

  /// Left off where the header is too narrow for it and the label both.
  final bool chevron;

  static TextStyle _style(AppColors c) =>
      AppType.caption.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700);

  /// The pill's width less its label: padding, outline, dot and, if shown,
  /// the chevron.
  static double chrome({required bool chevron}) => 3 + 11 + 1.8 * 2 + 18 + 2 + (chevron ? 4 + 16 : 0);

  /// The widest label the pill can show in the current mode, so the header
  /// can keep one layout while the status changes.
  static double widestLabel(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final List<String> labels = context.watch<ServerMonitor>().state == LinkState.onDevice
        ? <String>[l.linkOnPhone, l.linkNotReady]
        : <String>[l.linkConnecting, l.linkOnlineMs(888), l.linkCantConnect];
    double widest = 0;
    for (final String label in labels) {
      final double w = TextFit.width(context, label, _style(context.colors));
      if (w > widest) widest = w;
    }
    return widest;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final ServerMonitor m = context.watch<ServerMonitor>();
    final (_, String label) = linkLook(context, m);

    return Pressable(
      onTap: () => openModelStatus(context),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(3, 2, 11, 3),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: c.ink, width: 1.8),
          boxShadow: <BoxShadow>[
            BoxShadow(color: c.shadow, offset: const Offset(2, 2)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const LinkDot(size: 9),
            const SizedBox(width: 2),
            Flexible(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  label,
                  key: ValueKey<String>(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _style(c),
                ),
              ),
            ),
            if (chevron) ...<Widget>[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 16, color: c.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}
