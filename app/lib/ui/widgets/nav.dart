import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../l10n/l10n.dart';
import '../language/language_picker.dart';
import 'primitives.dart';
import 'text_fit.dart';
import 'wide.dart';

/// A scroll view with a big chunky title that collapses into a solid bar as
/// content scrolls under it. The bar carries the language globe unless
/// [globe] is off. On a very wide screen the title and [slivers] keep within
/// [Wide.maxContent].
class LargeTitleScrollView extends StatelessWidget {
  const LargeTitleScrollView({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
    this.leading,
    this.subtitle,
    this.controller,
    this.globe = true,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Widget? leading;
  final bool globe;

  /// Optional line under the large title — a count, a status.
  final String? subtitle;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    // The large title area grows with the text, so a subtitle that wraps
    // (German counts) or a bigger font size is never cut off.
    final double inset = Wide.inset(context);
    final double width = MediaQuery.sizeOf(context).width - 2 * inset;
    final double room = width - 40;
    final bool large = TextFit.large(context);
    double largeArea = FittedTitle.heightIn(context, title, _LargeTitleHeader.titleStyle, room) + 18;
    if (subtitle != null) {
      largeArea += 4 +
          TextFit.height(context, subtitle!, _LargeTitleHeader.subtitleStyle,
              maxWidth: room, maxLines: large ? null : 2);
    }
    // The bar it collapses into grows too when the title wraps under large
    // text. Beside it: the side margins and the globe with its gap.
    final double barRoom = width - 36 - (globe ? 8 + 48 : 0);
    final double barHeight = large
        ? math.max(
            _LargeTitleHeader._barHeight,
            FittedTitle.heightIn(context, title, _LargeTitleHeader.barTitleStyle, barRoom) + 12,
          )
        : _LargeTitleHeader._barHeight;

    return CustomScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _LargeTitleHeader(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            leading: leading,
            globe: globe,
            colors: context.colors,
            topPadding: MediaQuery.paddingOf(context).top,
            largeArea: largeArea.ceilToDouble(),
            barHeight: barHeight.ceilToDouble(),
            inset: inset,
          ),
        ),
        for (final Widget sliver in slivers)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: inset),
            sliver: sliver,
          ),
      ],
    );
  }
}

class _LargeTitleHeader extends SliverPersistentHeaderDelegate {
  _LargeTitleHeader({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.leading,
    required this.globe,
    required this.colors,
    required this.topPadding,
    required this.largeArea,
    required this.barHeight,
    required this.inset,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool globe;
  final AppColors colors;
  final double topPadding;

  /// Height of the large title and subtitle, measured by the scroll view.
  final double largeArea;

  /// Height of the collapsed bar, measured by the scroll view.
  final double barHeight;

  /// Extra margin on each side, on a very wide screen.
  final double inset;

  static const double _barHeight = 52;

  static TextStyle get titleStyle => AppType.largeTitle;
  static TextStyle get barTitleStyle => AppType.title3;
  static TextStyle get subtitleStyle =>
      AppType.subhead.copyWith(fontWeight: FontWeight.w600);

  @override
  double get minExtent => topPadding + barHeight;

  @override
  double get maxExtent => topPadding + barHeight + largeArea;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double t = (shrinkOffset / largeArea).clamp(0.0, 1.0);
    final double largeOpacity = (1 - t * 1.6).clamp(0.0, 1.0);
    final double smallOpacity = ((t - 0.6) / 0.4).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Color.lerp(colors.canvas.withValues(alpha: 0), colors.canvas, t),
        border: Border(
          bottom: BorderSide(
            color: colors.ink.withValues(alpha: smallOpacity),
            width: Chunky.border,
          ),
        ),
      ),
      child: Stack(
        children: <Widget>[
          // Collapsed bar: title at the start, actions pinned to the top row.
          Positioned(
            top: topPadding,
            left: inset,
            right: inset,
            height: barHeight,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 12),
                if (leading != null) ...<Widget>[
                  leading!,
                  const SizedBox(width: 8),
                ] else
                  const SizedBox(width: 8),
                Expanded(
                  child: Opacity(
                    opacity: smallOpacity,
                    child: FittedTitle(
                      title,
                      style: barTitleStyle.copyWith(color: colors.textPrimary),
                    ),
                  ),
                ),
                ?trailing,
                if (globe) ...<Widget>[
                  const SizedBox(width: 8),
                  const GlobeButton(size: 40),
                ],
                const SizedBox(width: 16),
              ],
            ),
          ),
          // Expanded title, faded away as the header shrinks.
          Positioned(
            left: 20 + inset,
            right: 20 + inset,
            bottom: 10,
            child: IgnorePointer(
              child: Opacity(
                opacity: largeOpacity,
                child: Transform.translate(
                  offset: Offset(0, 8 * t),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      FittedTitle(
                        title,
                        style: titleStyle.copyWith(color: colors.textPrimary),
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          maxLines: TextFit.large(context) ? null : 2,
                          overflow: TextFit.large(context) ? null : TextOverflow.ellipsis,
                          style: subtitleStyle.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_LargeTitleHeader old) =>
      old.title != title ||
      old.subtitle != subtitle ||
      old.trailing != trailing ||
      old.leading != leading ||
      old.globe != globe ||
      old.colors != colors ||
      old.topPadding != topPadding ||
      old.largeArea != largeArea ||
      old.barHeight != barHeight ||
      old.inset != inset;
}

/// Back button and title for pushed screens.
///
/// The back button is pinned to the start edge and the title is inset past it,
/// so the two can never overlap however long the title is.
class DetailBar extends StatelessWidget implements PreferredSizeWidget {
  const DetailBar({
    super.key,
    this.title,
    this.trailing,
    this.transparent = false,
    this.backLabel,
  });

  final String? title;
  final Widget? trailing;

  /// What a screen reader calls the back button; "Back" when null.
  final String? backLabel;

  /// Used over photography, where a solid bar would fight the image.
  final bool transparent;

  static const double _height = 60;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double top = MediaQuery.paddingOf(context).top;
    final bool large = TextFit.large(context);

    return Container(
      width: double.infinity,
      // Under large text a title that wraps makes the bar taller.
      height: large ? null : top + _height,
      constraints: large ? BoxConstraints(minHeight: top + _height) : null,
      padding: EdgeInsets.only(top: top),
      decoration: BoxDecoration(
        color: transparent ? Colors.transparent : c.canvas,
        border: transparent
            ? null
            : Border(bottom: BorderSide(color: c.ink, width: Chunky.border)),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 14),
          RoundButton(
            icon: Icons.arrow_back_rounded,
            size: 42,
            tooltip: backLabel ?? context.l10n.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: title == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.symmetric(vertical: large ? 6 : 0),
                    child: FittedTitle(
                      title!,
                      style: AppType.title3.copyWith(color: c.textPrimary),
                    ),
                  ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            trailing!,
          ],
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class TabDestination {
  const TabDestination(this.icon, this.activeIcon, this.label);
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating sticker tab bar. The active tab grows into an accent pill with its
/// label; the rest stay as icons.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.destinations,
    required this.index,
    required this.onChanged,
  });

  final List<TabDestination> destinations;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double bottom = MediaQuery.paddingOf(context).bottom;
    // No wider than [_maxWidth] on a tablet, in the middle.
    final double side = math.max(14, (MediaQuery.sizeOf(context).width - _maxWidth) / 2);

    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, bottom > 0 ? bottom : 12),
      child: Chunk(
        radius: 26,
        color: c.surface,
        clip: false,
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            // The active tab takes twice an icon tab's share, or more when its
            // label needs it ("Einstellungen"), as long as the icons keep
            // [_iconRoom] each.
            final int others = destinations.length - 1;
            final double share = box.maxWidth * 6 / (6 + 3 * others);
            // The bar is one row at a fixed height, so its label is capped.
            final TextScaler scaler = TextFit.tiny(context);
            final double needed =
                TextFit.width(context, destinations[index].label, _labelStyle, scaler: scaler) +
                    24 + 6 + 8 * 2 + 2 * 2 + 1;
            final double activeWidth = others == 0
                ? box.maxWidth
                : needed.clamp(share, (box.maxWidth - others * _iconRoom).clamp(share, box.maxWidth));
            final double iconWidth = others == 0 ? 0 : (box.maxWidth - activeWidth) / others;
            return Row(
              children: List<Widget>.generate(destinations.length, (int i) {
                final TabDestination d = destinations[i];
                final bool active = i == index;
                return SizedBox(
                  width: active ? activeWidth : iconWidth,
                  // Icon-only tabs still need their name read out.
                  child: Semantics(
                    button: true,
                    selected: active,
                    label: d.label,
                    excludeSemantics: true,
                    onTap: () => onChanged(i),
                    child: Pressable(
                      scale: 0.9,
                      onTap: () => onChanged(i),
                      child: AnimatedContainer(
                        duration: Motion.base,
                        curve: Curves.easeOutBack,
                        height: 50,
                        // Keeps a long label off the pill's outline.
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: active ? c.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? c.ink : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              active ? d.activeIcon : d.icon,
                              size: 24,
                              color: active ? c.onAccent : c.textSecondary,
                            ),
                            if (active) ...<Widget>[
                              const SizedBox(width: 6),
                              // Only shrinks when even the widest share is too
                              // narrow (very large system text), rather than
                              // losing its last letters.
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    d.label,
                                    maxLines: 1,
                                    softWrap: false,
                                    textScaler: scaler,
                                    style: _labelStyle.copyWith(color: c.onAccent),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  /// Least width an icon-only tab keeps when the active label needs room.
  static const double _iconRoom = 48;

  static const double _maxWidth = 520;

  static TextStyle get _labelStyle => AppType.button.copyWith(fontSize: 14.5);
}
