import 'package:flutter/material.dart';

/// Accent tones the user can pick in Settings.
///
/// Loud on purpose: the accent is a fill that sits under ink-black text and a
/// thick outline, so it can be far more saturated than a tint would allow.
enum AccentTone {
  sunny('Sunny', Color(0xFFFFD23F), Color(0xFFFFD23F)),
  lime('Lime', Color(0xFFC6F432), Color(0xFFC6F432)),
  bubblegum('Bubblegum', Color(0xFFFF8AD8), Color(0xFFFF8AD8)),
  tangerine('Tangerine', Color(0xFFFF9F43), Color(0xFFFFA24D)),
  grape('Grape', Color(0xFFB69CFF), Color(0xFFB69CFF)),
  sky('Sky', Color(0xFF6FD3FF), Color(0xFF6FD3FF));

  const AccentTone(this.label, this.light, this.dark);

  final String label;
  final Color light;
  final Color dark;

  Color resolve(Brightness b) => b == Brightness.dark ? dark : light;
}

/// Every colour the UI uses, resolved for one brightness.
///
/// Exposed as a [ThemeExtension] so widgets read `context.colors.ink` instead
/// of reaching for hard-coded hexes.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.accent,
    required this.onAccent,
    required this.canvas,
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceElevated,
    required this.ink,
    required this.shadow,
    required this.separator,
    required this.separatorOpaque,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.fill,
    required this.barTint,
    required this.positive,
    required this.caution,
    required this.critical,
    required this.scrim,
    required this.stickers,
  });

  final Color accent;

  /// Text and icons placed on an [accent] fill. Always ink-dark: every accent
  /// is light enough to carry black type in both themes.
  final Color onAccent;
  final Color canvas;
  final Color surface;
  final Color surfaceSunken;
  final Color surfaceElevated;

  /// The thick outline around cards, buttons and stickers.
  final Color ink;

  /// Hard, unblurred offset shadow under raised elements.
  final Color shadow;
  final Color separator;
  final Color separatorOpaque;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// Tinted fill for chips, tracks, inactive controls.
  final Color fill;

  /// Base for navigation / tab bars.
  final Color barTint;

  final Color positive;
  final Color caution;
  final Color critical;
  final Color scrim;

  /// Pastel sticker fills, cycled for tiles and tags so a list does not read
  /// as one flat colour.
  final List<Color> stickers;

  Color sticker(int i) => stickers[i.abs() % stickers.length];

  factory AppColors.light(Color accent) => AppColors(
        accent: accent,
        onAccent: const Color(0xFF141414),
        canvas: const Color(0xFFFFE8F2),
        surface: const Color(0xFFFFFFFF),
        surfaceSunken: const Color(0xFFF7D3E4),
        surfaceElevated: const Color(0xFFFFFFFF),
        ink: const Color(0xFF141414),
        shadow: const Color(0xFF141414),
        separator: const Color(0x26141414),
        separatorOpaque: const Color(0xFFF0CFDF),
        textPrimary: const Color(0xFF141414),
        textSecondary: const Color(0xFF5C4B55),
        textTertiary: const Color(0xFF97838E),
        fill: const Color(0x14141414),
        barTint: const Color(0xFFFFFFFF),
        positive: const Color(0xFF12A150),
        caution: const Color(0xFFE08A00),
        critical: const Color(0xFFE5484D),
        scrim: const Color(0x66000000),
        stickers: const <Color>[
          Color(0xFFFFE45C),
          Color(0xFFB5F2D6),
          Color(0xFFFFC4EA),
          Color(0xFFBDE3FF),
          Color(0xFFD9F99D),
        ],
      );

  factory AppColors.dark(Color accent) => AppColors(
        accent: accent,
        onAccent: const Color(0xFF141414),
        canvas: const Color(0xFF13121A),
        surface: const Color(0xFF211F2B),
        surfaceSunken: const Color(0xFF0C0B12),
        surfaceElevated: const Color(0xFF2A2836),
        ink: const Color(0xFFF2F0FA),
        shadow: const Color(0xFF000000),
        separator: const Color(0x29FFFFFF),
        separatorOpaque: const Color(0xFF37344A),
        textPrimary: const Color(0xFFF5F3FF),
        textSecondary: const Color(0xFFB7B3C9),
        textTertiary: const Color(0xFF7E7A93),
        fill: const Color(0x1AFFFFFF),
        barTint: const Color(0xFF211F2B),
        positive: const Color(0xFF4ADE80),
        caution: const Color(0xFFFFB224),
        critical: const Color(0xFFFF6B6B),
        scrim: const Color(0x99000000),
        stickers: const <Color>[
          Color(0xFFFFE45C),
          Color(0xFF9BE8C2),
          Color(0xFFFFA9DF),
          Color(0xFFA6D6FF),
          Color(0xFFCDF58A),
        ],
      );

  @override
  AppColors copyWith({Color? accent}) => AppColors(
        accent: accent ?? this.accent,
        onAccent: onAccent,
        canvas: canvas,
        surface: surface,
        surfaceSunken: surfaceSunken,
        surfaceElevated: surfaceElevated,
        ink: ink,
        shadow: shadow,
        separator: separator,
        separatorOpaque: separatorOpaque,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textTertiary: textTertiary,
        fill: fill,
        barTint: barTint,
        positive: positive,
        caution: caution,
        critical: critical,
        scrim: scrim,
        stickers: stickers,
      );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      ink: l(ink, other.ink),
      shadow: l(shadow, other.shadow),
      separator: l(separator, other.separator),
      separatorOpaque: l(separatorOpaque, other.separatorOpaque),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      fill: l(fill, other.fill),
      barTint: l(barTint, other.barTint),
      positive: l(positive, other.positive),
      caution: l(caution, other.caution),
      critical: l(critical, other.critical),
      scrim: l(scrim, other.scrim),
      stickers: <Color>[
        for (int i = 0; i < stickers.length; i++)
          l(stickers[i], other.stickers[i]),
      ],
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
