import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverScrollHeaderStretchConfiguration;

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../widgets/primitives.dart';
import '../widgets/specimen_image.dart';

/// Photograph header that parallaxes on scroll and hands off to a solid bar as
/// it collapses. The whole photo shows below the button bar, over a blurred
/// copy of itself, and pulling down at the top zooms it. Several angles swipe
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
                          ? _Photo(path: imagePaths.single, top: inset)
                          : _PhotoPager(paths: imagePaths, colors: colors, top: inset),
                    ),
                  ),
                  // Chunky ink rule where the photo meets the page.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(height: _rule, color: colors.ink),
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
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

const double _rule = Chunky.border + 0.8;

/// One photo, whole, between [top] and the ink rule, over a blurred and
/// darkened copy of itself that fills the rest of the header.
class _Photo extends StatelessWidget {
  const _Photo({required this.path, required this.top});

  final String path;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.clamp),
          child: SpecimenImage(path: path, fit: BoxFit.cover),
        ),
        const ColoredBox(color: Color(0x33000000)),
        Padding(
          padding: EdgeInsets.only(top: top, bottom: _rule),
          child: SpecimenImage(path: path, fit: BoxFit.contain),
        ),
      ],
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
              _Photo(path: paths[i], top: widget.top),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 18,
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
