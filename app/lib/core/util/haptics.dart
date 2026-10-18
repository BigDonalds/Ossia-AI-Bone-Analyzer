import 'package:flutter/services.dart';

/// Every meaningful touch gets feedback; nothing else does. Gated by the
/// user's Settings toggle.
abstract final class Haptics {
  static bool enabled = true;

  static void tap() {
    if (enabled) HapticFeedback.selectionClick();
  }

  static void light() {
    if (enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (enabled) HapticFeedback.mediumImpact();
  }

  static void success() {
    if (enabled) HapticFeedback.mediumImpact();
  }
}
