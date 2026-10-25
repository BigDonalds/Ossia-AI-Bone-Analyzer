import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverScrollHeaderStretchConfiguration;

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../widgets/primitives.dart';
import '../widgets/specimen_image.dart';
import '../widgets/text_fit.dart';

/// Photograph header that parallaxes on scroll and hands off to a solid bar as
/// it collapses. The whole photo shows below the button bar as a print with an
/// ink border, and pulling down at the top zooms it. Several angles swipe
/// sideways. The back button stays pinned to the top corner where reading
/// starts (top-right in Arabic) throughout.
class SpecimenHeader extends SliverPersistentHeaderDelegate {
  SpecimenHeader({
    required this.imagePaths,
    required this.title,
    required this.colors,
    required this.topPadding,
    required this.expandedHeight,
    this.onBack,
    this.actions,
    required this.backLabel,
  });

  final List<String> imagePaths;
  final String title;
  final AppColors colors;
  final double topPadding;
  final double expandedHeight;
  final VoidCallback? onBack;

  /// Built per frame so actions can react to the collapse progress `t`.
  final List<Widget> Function(double t)? actions;

  /// What a screen reader calls the back button.
  final String backLabel;

  static const double _bar = 60;

  /// How far down the photo starts: below the status bar and the buttons.
  static double photoTop(double topPadding) => topPadding + _bar;

  /// Page margin beside the print, air above it, and room below for its
  /// shadow, plus the page dots when there are several photos.
  static const double _side = 16;
  static const double _above = 4;
  static double _below(bool several) => several ? 34 : 14;

  /// How tall the photo part of the header is for a first photo of [aspect]
  /// (width over height): the whole print at full width, within limits that
  /// leave the answer in view below it. Phone photos are usually 3:4. On a
  /// wide screen (tablet on its side) the height limit wins.
  static double photoHeight(Size screen, double? aspect, {required bool several}) {
    final double tallest = screen.height * 0.52;
    final double shortest = (screen.width * 0.62).clamp(0.0, tallest).toDouble();
    return printHeight(screen.width, aspect, several: several).clamp(shortest, tallest).toDouble();
  }

  /// Height that shows the whole first print, with the air around it, across
  /// a column [width] wide.
  static double printHeight(double width, double? aspect, {required bool several}) {
    final double print = width - 2 * _side - Chunky.shadow;
    final double room = _above + _below(several) + Chunky.shadow;
    return print / (aspect ?? 0.75) + room;
  }

  @override
  double get minExtent => topPadding + _bar;

  @override
  double get maxExtent => expandedHeight;

  @override
  OverScrollHeaderStretchConfiguration get stretchConfiguration =>
      OverScrollHeaderStretchConfiguration();

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double range = (maxExtent - minExtent).clamp(1.0, double.infinity);
    final double t = (shrinkOffset / range).clamp(0.0, 1.0);
    final double solid = ((t - 0.55) / 0.35).clamp(0.0, 1.0);
    final double inset = photoTop(topPadding);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ClipRect(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              // Pulled down past the top: the header is taller than its full
              // size, and the photo grows from the top edge to fill it.
              final double zoom = box.maxHeight > maxExtent ? box.maxHeight / maxExtent : 1;
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    top: -shrinkOffset * 0.32,
                    left: 0,
                    right: 0,
                    height: maxExtent,
                    child: Transform.scale(
                      scale: zoom,
                      alignment: Alignment.topCenter,
                      child: imagePaths.length == 1
                          ? _Photo(path: imagePaths.single, top: inset, bottom: _below(false))
                          : _PhotoPager(paths: imagePaths, colors: colors, top: inset),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Solid bar taking over as the header collapses.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: minExtent,
          child: IgnorePointer(
            child: Opacity(
              opacity: solid,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.canvas,
                  border: Border(
                    bottom: BorderSide(color: colors.ink, width: Chunky.border),
                  ),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: topPadding,
          left: 0,
          right: 0,
          height: _bar,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 14),
              RoundButton(
                icon: Icons.arrow_back_rounded,
                size: 42,
                tooltip: backLabel,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: solid,
                  child: FittedTitle(
                    title,
                    style: AppType.title3.copyWith(color: colors.textPrimary),
                  ),
                ),
              ),
              if (actions != null) ...actions!(t),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(SpecimenHeader old) =>
      !listEquals(old.imagePaths, imagePaths) ||
      old.title != title ||
      old.backLabel != backLabel ||
      old.colors != colors ||
      old.topPadding != topPadding ||
      old.expandedHeight != expandedHeight;
}

/// The photos as prints on the page rather than in a header, [height] tall:
/// the top of a tablet report's first column.
class SpecimenPrints extends StatelessWidget {
  const SpecimenPrints({super.key, required this.paths, required this.height});

  final List<String> paths;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: paths.length == 1
          ? _Photo(path: paths.single, top: 0, bottom: SpecimenHeader._below(false))
          : _PhotoPager(paths: paths, colors: context.colors, top: 0),
    );
  }
}

/// One photo, whole, as a print with an ink border and a hard shadow: the
/// largest of its shape that fits between [top] and [bottom], centred on the
/// page.
class _Photo extends StatefulWidget {
  const _Photo({required this.path, required this.top, required this.bottom});

  final String path;
  final double top;
  final double bottom;

  @override
  State<_Photo> createState() => _PhotoState();
}

class _PhotoState extends State<_Photo> {
  static const double _radius = 16;

  /// Width over height, once the photo has loaded.
  double? _aspect;
  String? _measured;
  VoidCallback _stopMeasuring = () {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measure();
  }

  @override
  void didUpdateWidget(_Photo old) {
    super.didUpdateWidget(old);
    _measure();
  }

  @override
  void dispose() {
    _stopMeasuring();
    super.dispose();
  }

  void _measure() {
    if (widget.path == _measured) return;
    _measured = widget.path;
    _stopMeasuring();
    _stopMeasuring = SpecimenImage.measure(context, widget.path, (double aspect) {
      if (mounted && aspect != _aspect) setState(() => _aspect = aspect);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double aspect = _aspect ?? 0.75;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          SpecimenHeader._side, widget.top + SpecimenHeader._above, SpecimenHeader._side, widget.bottom),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double width = math.max(
              0,
              math.min(box.maxWidth - Chunky.shadow,
                  (box.maxHeight - Chunky.shadow) * aspect));
          return Center(
            child: Container(
              width: width,
              height: width / aspect,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: c.ink, width: Chunky.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(color: c.shadow, offset: const Offset(Chunky.shadow, Chunky.shadow)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius - Chunky.border),
                child: SpecimenImage(path: widget.path, fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Swipeable photos with page dots.
class _PhotoPager extends StatefulWidget {
  const _PhotoPager({required this.paths, required this.colors, required this.top});

  final List<String> paths;
  final AppColors colors;
  final double top;

  @override
  State<_PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<_PhotoPager> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final List<String> paths = widget.paths;
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        PageView.builder(
          itemCount: paths.length,
          onPageChanged: (int i) => setState(() => _page = i),
          itemBuilder: (BuildContext context, int i) =>
              _Photo(path: paths[i], top: widget.top, bottom: SpecimenHeader._below(true)),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (int i = 0; i < paths.length; i++)
                  AnimatedContainer(
                    duration: Motion.quick,
                    curve: Motion.standard,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 22 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _page ? widget.colors.accent : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFF141414), width: 1.6),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Round icon action for the header bar.
class HeaderAction extends StatelessWidget {
  const HeaderAction({
    super.key,
    required this.icon,
    required this.onTap,
    required this.t,
    required this.colors,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double t;
  final AppColors colors;

  /// What a screen reader says for the button.
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return RoundButton(icon: icon, size: 42, tooltip: tooltip, onTap: onTap);
  }
}
