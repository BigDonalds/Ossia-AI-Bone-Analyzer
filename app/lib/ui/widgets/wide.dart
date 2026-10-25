import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// Tablet layout. The four tabs and the report spread over two columns on a
/// wide screen; every other page keeps to a phone-wide column in the middle,
/// where text reads best.
abstract final class Wide {
  /// Least width for the two-column layouts: an iPad mini held upright.
  static const double breakpoint = 720;

  /// Widest the content gets; past it the margins grow instead.
  static const double maxContent = 1200;

  static bool of(BuildContext context) => MediaQuery.sizeOf(context).width >= breakpoint;

  /// Margin on each side that keeps the content within [maxContent].
  static double inset(BuildContext context) =>
      math.max(0, (MediaQuery.sizeOf(context).width - maxContent) / 2);
}

/// A phone-wide column in the middle of the screen, [color] beside it.
class PhoneColumn extends StatelessWidget {
  const PhoneColumn({super.key, required this.child, this.color});

  static const double width = 680;

  final Widget child;

  /// The canvas when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double w = math.min(media.size.width, width);
    // The same widgets at every width, so turning a tablet keeps the page as
    // it was.
    return ColoredBox(
      color: color ?? context.colors.canvas,
      child: Center(
        child: SizedBox(
          width: w,
          height: double.infinity,
          child: MediaQuery(
            data: media.copyWith(size: Size(w, media.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Two columns of the same width, side by side.
class TwoColumns extends StatelessWidget {
  const TwoColumns({super.key, required this.start, required this.end});

  final List<Widget> start;
  final List<Widget> end;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: start),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: end),
        ),
      ],
    );
  }
}

/// A page that lays itself out for wide screens, so it isn't put in the
/// phone column.
class WidePageRoute<T> extends MaterialPageRoute<T> {
  WidePageRoute({required super.builder, super.settings});
}

/// The app's page slide, with every pushed page kept to the phone column
/// except a tab's own first page and a [WidePageRoute].
class ColumnPageTransitions extends PageTransitionsBuilder {
  const ColumnPageTransitions();

  static const CupertinoPageTransitionsBuilder _slide = CupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration => _slide.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _slide.reverseTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition => _slide.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool own = route.isFirst || route is WidePageRoute;
    return _slide.buildTransitions<T>(
      route,
      context,
      animation,
      secondaryAnimation,
      own ? child : PhoneColumn(child: child),
    );
  }
}
