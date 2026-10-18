import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

/// Text that can only be worded once the app's language is known. The data
/// layer hands these to the screens, which call them with [AppLocalizations]
/// at build time, so a message already on screen follows a language change.
typedef LocalText = String Function(AppLocalizations l);

/// Text that came from outside the app (the server, the operating system) and
/// is shown as it arrived, in whatever language it was written in.
LocalText verbatim(String text) => (_) => text;

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// A language the app is translated into.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.hello,
    required this.badge,
    this.rtl = false,
  });

  /// ISO 639-1 code, matching the app_<code>.arb file.
  final String code;

  /// The language's name in itself, so anyone can find their own language
  /// whatever the app is currently showing.
  final String nativeName;

  /// A greeting for the language picker.
  final String hello;

  /// Two or so characters for the globe button's badge.
  final String badge;

  /// Written right to left, so the whole layout mirrors.
  final bool rtl;

  Locale get locale => Locale(code);
  TextDirection get direction => rtl ? TextDirection.rtl : TextDirection.ltr;

  /// The language's name in the app's current language, for use inside a
  /// sentence ("Gerade ist das Englisch"), where [nativeName] would mix two.
  String nameIn(AppLocalizations l) => switch (code) {
        'de' => l.languageNameGerman,
        'ar' => l.languageNameArabic,
        _ => l.languageNameEnglish,
      };
}

const List<AppLanguage> kLanguages = <AppLanguage>[
  AppLanguage(code: 'en', nativeName: 'English', hello: 'Hello!', badge: 'EN'),
  AppLanguage(code: 'de', nativeName: 'Deutsch', hello: 'Hallo!', badge: 'DE'),
  AppLanguage(code: 'ar', nativeName: 'العربية', hello: 'مرحبًا!', badge: 'ع', rtl: true),
];

AppLanguage languageFor(String code) => kLanguages.firstWhere(
      (AppLanguage l) => l.code == code,
      orElse: () => kLanguages.first,
    );

/// The first of the phone's preferred languages that the app speaks, or
/// English when it speaks none of them.
String phoneLanguage() => phoneMatch() ?? 'en';

/// The first of the phone's preferred languages that the app speaks, or null
/// when it speaks none of them.
String? phoneMatch() {
  for (final Locale locale in PlatformDispatcher.instance.locales) {
    for (final AppLanguage language in kLanguages) {
      if (locale.languageCode == language.code) return language.code;
    }
  }
  return null;
}
