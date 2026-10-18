import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'typography.dart';

abstract final class AppTheme {
  static ThemeData build(Brightness brightness, AccentTone tone) {
    final bool dark = brightness == Brightness.dark;
    final Color accent = tone.resolve(brightness);
    final AppColors c = dark ? AppColors.dark(accent) : AppColors.light(accent);

    final TextTheme text = TextTheme(
      displayLarge: AppType.largeTitle,
      headlineLarge: AppType.title1,
      headlineMedium: AppType.title2,
      headlineSmall: AppType.title3,
      titleMedium: AppType.headline,
      bodyLarge: AppType.body,
      bodyMedium: AppType.callout,
      bodySmall: AppType.footnote,
      labelLarge: AppType.headline,
      labelMedium: AppType.caption,
      labelSmall: AppType.caption2,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: brightness,
      ).copyWith(
        primary: accent,
        onPrimary: c.onAccent,
        surface: c.surface,
        error: c.critical,
      ),
      textTheme: text,
      extensions: <ThemeExtension<dynamic>>[c],
      dividerTheme: DividerThemeData(
        color: c.separator,
        thickness: 1,
        space: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.textPrimary,
        selectionColor: accent.withValues(alpha: 0.5),
        selectionHandleColor: c.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: c.textPrimary,
      ),
    );
  }

  /// Status bar icons must contrast with the canvas, not the system default.
  static SystemUiOverlayStyle overlay(Brightness brightness) =>
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: const Color(0xFF13121A),
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: const Color(0xFFFFE8F2),
              systemNavigationBarIconBrightness: Brightness.dark,
            );
}
