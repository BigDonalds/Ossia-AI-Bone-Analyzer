import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../core/util/haptics.dart';
import 'bone_buddy.dart';
import 'text_fit.dart';

/// Outline weight and hard-shadow depth shared by every raised element.
abstract final class Chunky {
  static const double border = 2.2;
  static const double shadow = 4;
  static const double radius = 20;
}

/// Everything tappable in the app uses this: a small scale-down with a
/// selection tick under the finger.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) Haptics.tap();
              widget.onTap?.call();
            }
          : null,
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              Haptics.medium();
              widget.onLongPress!.call();
            },
      child: AnimatedScale(
        scale: _down && enabled ? widget.scale : 1.0,
        duration: Motion.micro,
        curve: Motion.standard,
        child: widget.child,
      ),
    );
  }
}

/// A sticker-style card: solid fill, thick ink outline, hard offset shadow.
///
/// When [onTap] is set the card physically presses into its shadow.
class Chunk extends StatefulWidget {
  const Chunk({
    super.key,
    required this.child,
    this.color,
    this.padding = EdgeInsets.zero,
    this.radius = Chunky.radius,
    this.shadow = Chunky.shadow,
    this.onTap,
    this.clip = true,
    this.width,
    this.height,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double shadow;
  final VoidCallback? onTap;
  final bool clip;
  final double? width;
  final double? height;

  @override
  State<Chunk> createState() => _ChunkState();
}

class _ChunkState extends State<Chunk> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool enabled = widget.onTap != null;
    final double depth = _down && enabled ? widget.shadow * 0.25 : widget.shadow;
    final double travel = widget.shadow - depth;
    final BorderRadius br = BorderRadius.circular(widget.radius);

    Widget inner = Padding(padding: widget.padding, child: widget.child);
    if (widget.clip) {
      inner = ClipRRect(
        borderRadius: BorderRadius.circular(
            (widget.radius - Chunky.border).clamp(0, double.infinity)),
        child: inner,
      );
    }

    final Widget box = AnimatedContainer(
      duration: Motion.micro,
      curve: Motion.standard,
      width: widget.width,
      height: widget.height,
      transform: Matrix4.translationValues(travel, travel, 0),
      decoration: BoxDecoration(
        color: widget.color ?? c.surface,
        borderRadius: br,
        border: Border.all(color: c.ink, width: Chunky.border),
        boxShadow: <BoxShadow>[
          BoxShadow(color: c.shadow, offset: Offset(depth, depth)),
        ],
      ),
      child: inner,
    );

    // Reserve the shadow's footprint so pressing never shifts the layout.
    final Widget padded = Padding(
      padding: EdgeInsets.only(right: widget.shadow, bottom: widget.shadow),
      child: box,
    );

    if (!enabled) return padded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: () {
        Haptics.tap();
        widget.onTap!();
      },
      child: padded,
    );
  }
}

/// Entrance animation used to bring content in on first paint. [delay] lets a
/// list stagger without every row carrying its own controller logic.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.slow,
  );

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CurvedAnimation curve =
        CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    return AnimatedBuilder(
      animation: curve,
      builder: (BuildContext context, Widget? child) => Opacity(
        opacity: _c.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curve.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Chunky label that sits above a group of rows.
class GroupLabel extends StatelessWidget {
  const GroupLabel(this.text, {super.key, this.trailing, this.top = 28});

  final String text;
  final Widget? trailing;

  /// Space above the label; less where it starts a column beside a card.
  final double top;

  @override
  Widget build(BuildContext context) {
    final Widget label = Text(
      text,
      style: AppType.groupHeader.copyWith(color: context.colors.textPrimary),
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top, 20, 10),
      // The trailing pill drops under the label when the two don't fit on one
      // line (German, large text).
      child: trailing == null
          ? label
          : SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[label, trailing!],
              ),
            ),
    );
  }
}

/// Explanatory paragraph under a group.
class GroupFooter extends StatelessWidget {
  const GroupFooter(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 24, 0),
      child: Text(
        text,
        style: AppType.footnote.copyWith(
          color: context.colors.textSecondary,
          height: 1.42,
        ),
      ),
    );
  }
}

/// A confidence readout: outlined chunky track, animated fill, percentage.
class ConfidenceBar extends StatelessWidget {
  const ConfidenceBar({
    super.key,
    required this.value,
    this.color,
    this.height = 10,
    this.showValue = true,
    this.label,
    this.dimmed = false,
  });

  final double value;
  final Color? color;
  final double height;
  final bool showValue;
  final String? label;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color fill = (color ?? c.accent).withValues(alpha: dimmed ? 0.45 : 1.0);
    final double track = height < 8 ? 1.4 : 1.8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (label != null || showValue)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              children: <Widget>[
                if (label != null)
                  Expanded(
                    child: Text(
                      label!,
                      style: AppType.callout.copyWith(
                        color: dimmed ? c.textTertiary : c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const Spacer(),
                if (showValue)
                  Text(
                    percent(value),
                    style: AppType.metric.copyWith(
                      fontSize: 15,
                      color: dimmed ? c.textTertiary : c.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        Container(
          height: height + track * 2,
          decoration: BoxDecoration(
            color: c.fill,
            borderRadius: BorderRadius.circular(height),
            border: Border.all(
              color: dimmed ? c.ink.withValues(alpha: 0.35) : c.ink,
              width: track,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (BuildContext context, double v, _) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: v,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: fill,
                      border: v > 0.01 && v < 0.99
                          ? BorderDirectional(
                              end: BorderSide(color: c.ink, width: track))
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Small sticker used for statuses and counts.
class StatusPill extends StatelessWidget {
  const StatusPill(
    this.text, {
    super.key,
    this.color,
    this.filled = false,
    this.icon,
    this.leading,
    this.maxLines = 1,
  });

  final String text;
  final Color? color;
  final bool filled;
  final IconData? icon;

  /// Drawn in place of [icon], at the icon's size and colour.
  final Widget? leading;

  /// Lines the label may take before it ends in "…".
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color tone = color ?? c.textSecondary;
    // A filled pill is a solid sticker with ink type; an unfilled one is a
    // quiet outline.
    final Color bg = filled ? tone : Colors.transparent;
    final Color fg = filled ? _inkOn(tone) : c.textPrimary;
    return Container(
      padding: EdgeInsetsDirectional.fromSTEB(
          icon == null && leading == null ? 10 : 7, 4, 10, 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.ink, width: 1.6),
      ),
      // One rich text rather than a row: it sizes to the label where the
      // width is open, and wraps or ends in "…" where it is not (a long German
      // region name beside a sketch) instead of running past the pill.
      child: Text.rich(
        TextSpan(
          children: <InlineSpan>[
            if (leading != null || icon != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: IconTheme(
                    data: IconThemeData(size: 13, color: fg),
                    child: leading ?? Icon(icon),
                  ),
                ),
              ),
            TextSpan(text: text),
          ],
        ),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: AppType.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

/// Black or white, whichever reads on [bg].
Color _inkOn(Color bg) =>
    bg.computeLuminance() > 0.35 ? const Color(0xFF141414) : Colors.white;

/// Divider between rows, inset from the left.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: Container(height: 1.5, color: context.colors.separator),
    );
  }
}

/// Centred placeholder for empty lists, fronted by the mascot.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    required this.message,
    this.action,
    this.mood = BuddyMood.thinking,
  });

  final IconData? icon;
  final String title;
  final String message;
  final Widget? action;
  final BuddyMood mood;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            BoneBuddy(size: 130, mood: mood),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppType.title2.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppType.subhead.copyWith(
                color: c.textSecondary,
                height: 1.42,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Filled accent button — the single primary action on a screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.tone,
    this.expand = true,
    this.height = 58,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? tone;
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color bg = tone ?? c.accent;
    final Color fg = _inkOn(bg);
    final bool enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Chunk(
        onTap: onTap,
        color: bg,
        radius: 18,
        width: expand ? double.infinity : null,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: expand ? 16 : 24),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 21, color: fg),
              const SizedBox(width: 9),
            ],
            // A label too long for the button (German likes long words)
            // shrinks a little rather than losing its end.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppType.button.copyWith(color: fg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Surface-coloured outlined action.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.onTap,
    this.destructive = false,
    this.height = 58,
  });

  final String label;
  final IconData? icon;

  /// Drawn in place of [icon], at the icon's size and colour.
  final Widget? leading;
  final VoidCallback? onTap;
  final bool destructive;
  final double height;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Color tone = destructive ? c.critical : c.textPrimary;
    return Opacity(
      opacity: onTap != null ? 1 : 0.55,
      child: Chunk(
        onTap: onTap,
        radius: 18,
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (leading != null || icon != null) ...<Widget>[
              IconTheme(
                data: IconThemeData(size: 21, color: tone),
                child: leading ?? Icon(icon),
              ),
              const SizedBox(width: 9),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppType.button.copyWith(color: tone),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A secondary and a primary button side by side, sharing the width by
/// [secondaryFlex] to [primaryFlex]. When either label would have to shrink
/// to fit its share (German and Arabic labels run long), they stack instead,
/// the primary on top, as on the report page.
class ButtonPair extends StatelessWidget {
  const ButtonPair({
    super.key,
    required this.secondary,
    required this.primary,
    this.secondaryFlex = 1,
    this.primaryFlex = 1,
  });

  final SecondaryButton secondary;
  final PrimaryButton primary;
  final int secondaryFlex;
  final int primaryFlex;

  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double share =
            (box.maxWidth - _gap) / (secondaryFlex + primaryFlex);
        // Room for the label inside a button [width] wide: less the outline,
        // the shadow, the side padding and an icon with its gap. A label may
        // shrink a touch, as it does on a single button, but no more.
        bool fits(String label, bool icon, double width, double pad) {
          final double room = width -
              Chunky.shadow -
              Chunky.border * 2 -
              pad * 2 -
              (icon ? 30 : 0);
          return TextFit.width(context, label, AppType.button) * 0.92 <= room;
        }

        final bool side = fits(
              secondary.label,
              secondary.icon != null || secondary.leading != null,
              share * secondaryFlex,
              12,
            ) &&
            fits(primary.label, primary.icon != null, share * primaryFlex, 16);
        if (!side) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              primary,
              const SizedBox(height: 10),
              secondary,
            ],
          );
        }
        return Row(
          children: <Widget>[
            Expanded(flex: secondaryFlex, child: secondary),
            const SizedBox(width: _gap),
            Expanded(flex: primaryFlex, child: primary),
          ],
        );
      },
    );
  }
}

/// Round outlined icon button — back, close, flash and friends.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 44,
    this.color,
    this.iconColor,
    this.shadow = 3,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? color;
  final Color? iconColor;
  final double shadow;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final Widget button = Chunk(
      onTap: onTap,
      color: color ?? c.surface,
      radius: size / 2,
      shadow: shadow,
      width: size,
      height: size,
      child: Center(
        child: Icon(icon, size: size * 0.46, color: iconColor ?? c.textPrimary),
      ),
    );
    return tooltip == null
        ? button
        : Semantics(label: tooltip, button: true, child: button);
  }
}

/// A speech bubble for the mascot's lines, with its tail at the start of the
/// line (left in left-to-right languages), where the mascot sits.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.child,
    this.color,
    this.tailAtStart = true,
  });

  final Widget child;
  final Color? color;
  final bool tailAtStart;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool tailOnLeft = tailAtStart == (Directionality.of(context) == TextDirection.ltr);
    return CustomPaint(
      painter: _BubblePainter(
        fill: color ?? c.surface,
        ink: c.ink,
        shadow: c.shadow,
        tailOnLeft: tailOnLeft,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            tailOnLeft ? 26 : 16, 12, tailOnLeft ? 16 : 26, 14),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({
    required this.fill,
    required this.ink,
    required this.shadow,
    required this.tailOnLeft,
  });

  final Color fill;
  final Color ink;
  final Color shadow;
  final bool tailOnLeft;

  @override
  void paint(Canvas canvas, Size size) {
    const double tail = 10;
    final Rect body = Rect.fromLTWH(
        tailOnLeft ? tail : 0, 0, size.width - tail - 3, size.height - 3);
    final Path p = Path()
      ..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(18)));
    final double ty = body.center.dy;
    final Path t = Path();
    if (tailOnLeft) {
      t
        ..moveTo(body.left + 2, ty - 9)
        ..lineTo(0, ty + 4)
        ..lineTo(body.left + 2, ty + 7)
        ..close();
    } else {
      t
        ..moveTo(body.right - 2, ty - 9)
        ..lineTo(size.width - 3, ty + 4)
        ..lineTo(body.right - 2, ty + 7)
        ..close();
    }
    final Path shape = Path.combine(PathOperation.union, p, t);
    canvas.drawPath(shape.shift(const Offset(3, 3)), Paint()..color = shadow);
    canvas.drawPath(shape, Paint()..color = fill);
    canvas.drawPath(
      shape,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = Chunky.border
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.fill != fill || old.ink != ink || old.shadow != shadow || old.tailOnLeft != tailOnLeft;
}
