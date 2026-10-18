import 'package:flutter/material.dart';

/// Type scale. Two families: Bricolage Grotesque, chunky and a little quirky,
/// for anything that should shout; DM Sans for anything that has to be read.
/// Both are bundled (assets/fonts/), so nothing downloads on first launch.
///
/// Neither has Arabic letters, so Arabic falls back to Baloo Bhaijaan 2 for
/// the loud styles and Readex Pro for reading. Arabic letters join up, so the
/// tight tracking the Latin styles use would pull words apart: [arabic] turns
/// it off and gives the taller Arabic shapes a little more line height.
///
/// The size names keep their iOS roots so call sites stay familiar.
abstract final class AppType {
  /// Set from the app's language before each build of the app (main.dart).
  static bool arabic = false;

  static final TypeScale _latin = TypeScale._(arabic: false);
  static final TypeScale _arabic = TypeScale._(arabic: true);
  static TypeScale get _s => arabic ? _arabic : _latin;

  /// The styles for text written in [code], whatever the app's own language:
  /// a language's name in the language picker, say.
  static TypeScale scaleFor(String code) => code == 'ar' ? _arabic : _latin;

  /// The styles for the app's own language.
  static TypeScale get current => _s;

  /// Hero wordmark and screen titles.
  static TextStyle get mega => _s.mega;
  static TextStyle get largeTitle => _s.largeTitle;
  static TextStyle get title1 => _s.title1;
  static TextStyle get title2 => _s.title2;
  static TextStyle get title3 => _s.title3;
  static TextStyle get headline => _s.headline;
  static TextStyle get body => _s.body;
  static TextStyle get callout => _s.callout;
  static TextStyle get subhead => _s.subhead;
  static TextStyle get footnote => _s.footnote;
  static TextStyle get caption => _s.caption;
  static TextStyle get caption2 => _s.caption2;

  /// Chunky label above a group of rows.
  static TextStyle get groupHeader => _s.groupHeader;

  /// Button labels.
  static TextStyle get button => _s.button;

  /// Tabular figures for anything that reads as a measurement.
  static TextStyle get metric => _s.metric;
  static TextStyle get metricLarge => _s.metricLarge;

  /// Tracking for a hand-styled label: as given in Latin, none in Arabic.
  static double tracking(double latin) => arabic ? 0 : latin;
}

/// One full set of styles, for Latin or Arabic.
class TypeScale {
  TypeScale._({required this.arabic});

  final bool arabic;

  TextStyle _style(
    String family,
    String arabicFamily,
    double size,
    FontWeight weight,
    double tracking,
    double? height,
  ) =>
      TextStyle(
        fontFamily: family,
        fontFamilyFallback: <String>[arabicFamily],
        fontSize: size,
        fontWeight: weight,
        letterSpacing: arabic ? 0 : tracking,
        height: height == null || !arabic ? height : (height < 1.3 ? height + 0.2 : height + 0.1),
        leadingDistribution: TextLeadingDistribution.even,
      );

  TextStyle _display(double size, FontWeight weight, double tracking, {double? height}) =>
      _style('BricolageGrotesque', 'BalooBhaijaan2', size, weight, tracking, height);

  TextStyle _text(double size, FontWeight weight, double tracking, {double? height}) =>
      _style('DMSans', 'ReadexPro', size, weight, tracking, height);

  late final TextStyle mega = _display(44, FontWeight.w800, -1.6, height: 1.0);
  late final TextStyle largeTitle = _display(36, FontWeight.w800, -1.1, height: 1.05);
  late final TextStyle title1 = _display(29, FontWeight.w800, -0.8, height: 1.1);
  late final TextStyle title2 = _display(23, FontWeight.w800, -0.5, height: 1.15);
  late final TextStyle title3 = _display(20, FontWeight.w700, -0.3, height: 1.2);
  late final TextStyle headline = _text(16.5, FontWeight.w700, -0.2, height: 1.3);
  late final TextStyle body = _text(16.5, FontWeight.w500, -0.2, height: 1.32);
  late final TextStyle callout = _text(15.5, FontWeight.w500, -0.15, height: 1.33);
  late final TextStyle subhead = _text(14.5, FontWeight.w400, -0.1, height: 1.38);
  late final TextStyle footnote = _text(13, FontWeight.w500, 0, height: 1.38);
  late final TextStyle caption = _text(12, FontWeight.w500, 0.1, height: 1.33);
  late final TextStyle caption2 = _text(11, FontWeight.w600, 0.2, height: 1.18);
  late final TextStyle groupHeader = _display(17, FontWeight.w800, -0.2, height: 1.2);
  late final TextStyle button = _display(17, FontWeight.w800, -0.1, height: 1.1);
  late final TextStyle metric = _display(17, FontWeight.w800, -0.2, height: 1.2)
      .copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);
  late final TextStyle metricLarge = _display(44, FontWeight.w800, -1.6, height: 1.0)
      .copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()]);
}
