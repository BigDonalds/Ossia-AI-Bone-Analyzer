import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/palette.dart';
import '../core/util/haptics.dart';
import '../l10n/l10n.dart';

/// Names and unit symbols for people live in lib/l10n/labels.dart.
enum LengthUnit {
  centimetres('cm'),
  inches('in');

  const LengthUnit(this.symbol);

  /// The Latin symbol, for the report text the model writes.
  final String symbol;

  double from(double cm) => this == inches ? cm / 2.54 : cm;
}

/// Where scans are analysed. Shown to people as "This phone" and "Online".
enum EngineMode {
  /// The model bundled with the app. Works offline; photos never leave the phone.
  onDevice,

  /// The Python pipeline on a computer (scripts/serve.py), which can run any
  /// checkpoint.
  server,
}

class SettingsController extends ChangeNotifier with WidgetsBindingObserver {
  SettingsController(this._prefs) {
    _load();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Saved instead of a language code when the app should follow the phone.
  static const String followPhone = 'system';

  final SharedPreferences _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  AccentTone _accent = AccentTone.sunny;
  bool _haptics = true;
  bool _autoSave = true;
  bool _hideLowConfidence = false;
  double _confidenceFloor = 0.40;
  LengthUnit _unit = LengthUnit.centimetres;
  EngineMode _engine = EngineMode.onDevice;
  String _serverUrl = 'http://192.168.1.10:8000';

  /// The language the person picked ([followPhone] to follow the phone), or
  /// null until they have picked one.
  String? _locale;

  /// A language being tried on the first-run picker, not yet saved.
  String? _preview;

  /// The phone's own language, when the app speaks it. Updated if the phone's
  /// language changes while the app is open.
  String _phone = phoneLanguage();

  ThemeMode get themeMode => _themeMode;
  AccentTone get accent => _accent;
  bool get haptics => _haptics;
  bool get autoSave => _autoSave;
  bool get hideLowConfidence => _hideLowConfidence;

  /// Predictions below this score are dimmed, or hidden entirely when
  /// [hideLowConfidence] is on.
  double get confidenceFloor => _confidenceFloor;
  LengthUnit get unit => _unit;

  EngineMode get engine => _engine;
  bool get onDevice => _engine == EngineMode.onDevice;
  String get serverUrl => _serverUrl;

  /// The language the app is shown in: the person's pick, else the one being
  /// tried on the first-run picker, else the phone's.
  String get localeCode => _locale == null || _locale == followPhone
      ? _preview ?? _phone
      : _locale!;
  AppLanguage get language => languageFor(localeCode);

  /// False until the first-run picker has been answered.
  bool get hasChosenLocale => _locale != null;

  /// True when the app follows the phone's language rather than a fixed pick.
  bool get followsPhone => _locale == followPhone;
  String get phoneLocaleCode => _phone;

  void _load() {
    _themeMode = ThemeMode.values[_prefs.getInt('theme_mode') ?? 0];
    _accent = AccentTone.values[_prefs.getInt('accent') ?? 0];
    _haptics = _prefs.getBool('haptics') ?? true;
    _autoSave = _prefs.getBool('auto_save') ?? true;
    _hideLowConfidence = _prefs.getBool('hide_low_conf') ?? false;
    _confidenceFloor = _prefs.getDouble('conf_floor') ?? 0.40;
    _unit = LengthUnit.values[_prefs.getInt('unit') ?? 0];
    _engine = EngineMode.values.asNameMap()[_prefs.getString('engine')] ??
        EngineMode.onDevice;
    _serverUrl = _prefs.getString('server_url') ?? _serverUrl;
    final String? saved = _prefs.getString('locale');
    _locale = saved == followPhone || kLanguages.any((AppLanguage l) => l.code == saved)
        ? saved
        : null;
    Haptics.enabled = _haptics;
  }

  void setThemeMode(ThemeMode v) {
    _themeMode = v;
    _prefs.setInt('theme_mode', v.index);
    notifyListeners();
  }

  void setAccent(AccentTone v) {
    _accent = v;
    _prefs.setInt('accent', v.index);
    notifyListeners();
  }

  void setHaptics(bool v) {
    _haptics = v;
    Haptics.enabled = v;
    _prefs.setBool('haptics', v);
    notifyListeners();
  }

  void setAutoSave(bool v) {
    _autoSave = v;
    _prefs.setBool('auto_save', v);
    notifyListeners();
  }

  void setHideLowConfidence(bool v) {
    _hideLowConfidence = v;
    _prefs.setBool('hide_low_conf', v);
    notifyListeners();
  }

  void setConfidenceFloor(double v) {
    _confidenceFloor = v;
    _prefs.setDouble('conf_floor', v);
    notifyListeners();
  }

  void setUnit(LengthUnit v) {
    _unit = v;
    _prefs.setInt('unit', v.index);
    notifyListeners();
  }

  void setEngine(EngineMode v) {
    _engine = v;
    _prefs.setString('engine', v.name);
    notifyListeners();
  }

  /// Shows the app in [code] without saving it, for the first-run picker.
  void previewLocale(String code) {
    if (_preview == code) return;
    _preview = code;
    notifyListeners();
  }

  /// Saves a language code, or [followPhone].
  void setLocale(String code) {
    _locale = code;
    _preview = null;
    _prefs.setString('locale', code);
    notifyListeners();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final String now = phoneLanguage();
    if (now == _phone) return;
    _phone = now;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void setServerUrl(String v) {
    _serverUrl = v.trim();
    _prefs.setString('server_url', _serverUrl);
    notifyListeners();
  }
}
