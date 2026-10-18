import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import 'primitives.dart';

/// A chunky outlined card holding rows separated by thin rules.
class InsetGroup extends StatelessWidget {
  const InsetGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.separatorIndent = 16,
    this.color,
  });

  final List<Widget> children;
  final EdgeInsets margin;
  final double separatorIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i != children.length - 1) {
        rows.add(Hairline(indent: separatorIndent));
      }
    }

    // The shadow reserves space on the right, so trim the right margin to
    // keep the card optically centred.
    return Padding(
      padding: margin.copyWith(
        right: (margin.right - Chunky.shadow).clamp(0, double.infinity),
      ),
      child: Chunk(
        color: color,
        child: Column(children: rows),
      ),
    );
  }
}

/// One row inside an [InsetGroup].
class InsetRow extends StatelessWidget {
  const InsetRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.value,
    this.onTap,
    this.chevron = false,
    this.tint,
    this.minHeight = 54,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Grey detail text at the row's far end.
  final String? value;
  final VoidCallback? onTap;
  final bool chevron;

  /// Overrides the title colour — used for destructive rows.
  final Color? tint;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;

    return Pressable(
      onTap: onTap,
      scale: 0.985,
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 11, 14, 11),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) => Row(
            children: <Widget>[
              if (leading != null) ...<Widget>[
                IconTheme.merge(
                  data: IconThemeData(color: tint ?? c.textPrimary),
                  child: leading!,
                ),
                const SizedBox(width: 13),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppType.body.copyWith(
                        color: tint ?? c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppType.footnote.copyWith(
                          color: c.textSecondary,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(width: 12),
                // The value takes only the width it needs (up to 45% of the
                // row), so it sits flush against the trailing edge and short
                // values leave the title room to stay on one line.
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.45),
                  child: Text(
                    value!,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.callout.copyWith(
                      color: c.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 10),
                trailing!,
              ],
              if (chevron) ...<Widget>[
                const SizedBox(width: 8),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.fill,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Row with a trailing switch. The whole row is the hit target.
class InsetSwitchRow extends StatelessWidget {
  const InsetSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return InsetRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: () => onChanged(!value),
      trailing: ChunkySwitch(value: value),
    );
  }
}

/// An outlined pill toggle with a knob that slides and squashes.
class ChunkySwitch extends StatelessWidget {
  const ChunkySwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Widget body = AnimatedContainer(
      duration: Motion.base,
      curve: Curves.easeOutBack,
      width: 54,
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? c.accent : c.fill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.ink, width: 2),
      ),
      child: AnimatedAlign(
        duration: Motion.base,
        curve: Curves.easeOutBack,
        alignment: value ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
        child: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: value ? c.onAccent : c.surface,
            shape: BoxShape.circle,
            border: Border.all(color: c.ink, width: 2),
          ),
        ),
      ),
    );
    if (onChanged == null) return body;
    return GestureDetector(
      onTap: () {
        Haptics.tap();
        onChanged!(!value);
      },
      child: body,
    );
  }
}

/// Segmented control: an outlined track with a sliding accent sticker.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final List<T> keys = segments.keys.toList();
    final int index = keys.indexOf(value);

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.ink, width: 2),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double segmentWidth = constraints.maxWidth / keys.length;
          return Stack(
            children: <Widget>[
              AnimatedPositionedDirectional(
                duration: Motion.base,
                curve: Curves.easeOutBack,
                start: segmentWidth * index,
                top: 0,
                bottom: 0,
                width: segmentWidth,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.ink, width: 1.8),
                    ),
                  ),
                ),
              ),
              Row(
                children: keys.map((T k) {
                  final bool active = k == value;
                  return Expanded(
                    child: Pressable(
                      scale: 0.94,
                      onTap: () => onChanged(k),
                      child: Center(
                        child: Text(
                          segments[k]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.footnote.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: active ? c.onAccent : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}
