/// Small text helpers shared across screens.
///
/// Pure Dart, so the command-line tools can use them too. Anything that needs
/// the translated words (dates, "2 min ago") lives in lib/l10n/labels.dart.
library;

/// The app's current language code ('en', 'de', 'ar'). Set by main.dart before
/// each build, so number formatting here matches the rest of the screen.
abstract final class AppLang {
  static String code = 'en';
}

String titleCase(String raw) => raw
    .replaceAll('_', ' ')
    .split(' ')
    .where((String w) => w.isNotEmpty)
    .map((String w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// A number with a fixed count of decimals, with German's decimal comma.
/// Digits stay Western in Arabic on purpose: lab sheets and rulers use them.
String fixed(double v, int decimals) {
  final String s = v.toStringAsFixed(decimals);
  return AppLang.code == 'de' ? s.replaceAll('.', ',') : s;
}

/// 0.45 -> "45%", or "45 %" in German (with a no-break space, as German
/// writes it).
String percent(double v, {int decimals = 0}) {
  final String n = fixed(v * 100, decimals);
  return AppLang.code == 'de' ? '$n %' : '$n%';
}
