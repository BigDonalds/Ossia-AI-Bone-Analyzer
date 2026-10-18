import 'package:flutter/animation.dart';

/// Shared timings. Everything animates on the same handful of curves so the
/// app moves like one object rather than a pile of independent widgets.
abstract final class Motion {
  /// Standard iOS ease — fast out, gentle settle.
  static const Curve standard = Cubic(0.32, 0.72, 0.0, 1.0);
  static const Curve emphasized = Cubic(0.2, 0.9, 0.1, 1.0);
  static const Curve exit = Curves.easeInCubic;

  static const Duration micro = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 220);
  static const Duration base = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 520);

  /// Stagger step for lists that reveal on entry.
  static const Duration stagger = Duration(milliseconds: 55);
}
