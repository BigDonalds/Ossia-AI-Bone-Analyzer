import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import 'primitives.dart';

/// Where scans are analyzed: a chunky two-way switch whose thumb springs
/// across, with the chosen side's icon giving a little wiggle as it lands.
class EngineToggle extends StatelessWidget {
  const EngineToggle({super.key, required this.value, required this.onChanged});

  final EngineMode value;
  final ValueChanged<EngineMode> onChanged;

  static const double _height = 66;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final bool phone = value == EngineMode.onDevice;

    void pick(EngineMode m) {
      if (m == value) return;
      Haptics.medium();
      onChanged(m);
    }

    return Semantics(
      label: l.engineAnalyzeOn,
      value: l.engineName(value),
      child: Container(
        height: _height,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.ink, width: Chunky.border),
        ),
        child: Stack(
          children: <Widget>[
            // The thumb.
            AnimatedAlign(
              alignment: phone ? AlignmentDirectional.centerStart : AlignmentDirectional.centerEnd,
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutBack,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.accent,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: c.ink, width: Chunky.border),
                    boxShadow: <BoxShadow>[
                      BoxShadow(color: c.shadow, offset: const Offset(2.5, 2.5)),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (final EngineMode m in EngineMode.values)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => pick(m),
                      child: _Side(
                        mode: m,
                        selected: m == value,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Side extends StatelessWidget {
  const _Side({required this.mode, required this.selected});

  final EngineMode mode;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fg = selected ? c.onAccent : c.textSecondary;
    final bool phone = mode == EngineMode.onDevice;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        // Keyed on selection so the wiggle replays each time this side wins.
        TweenAnimationBuilder<double>(
          key: ValueKey<bool>(selected),
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: selected ? 620 : 1),
          builder: (BuildContext context, double t, Widget? child) {
            final double wiggle = selected ? math.sin(t * math.pi * 3) * (1 - t) * 0.35 : 0;
            final double pop = selected ? 1 + math.sin(t * math.pi) * 0.18 : 1;
            return Transform.rotate(
              angle: wiggle,
              child: Transform.scale(scale: pop, child: child),
            );
          },
          child: Icon(
            phone ? Icons.smartphone_rounded : Icons.cloud_rounded,
            size: 22,
            color: fg,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppType.headline.copyWith(color: fg, fontWeight: FontWeight.w800),
                child: Text(context.l10n.engineName(mode), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: AppType.caption.copyWith(
                  color: fg.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
                child: Text(
                  phone ? context.l10n.engineWorksOffline : context.l10n.engineUsesInternet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
