import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/motion.dart';
import 'core/theme/typography.dart';
import 'core/util/formatting.dart';
import 'data/history_store.dart';
import 'data/on_device/on_device_model.dart';
import 'data/server_monitor.dart';
import 'data/settings_controller.dart';
import 'l10n/l10n.dart';
import 'ui/language/welcome_screen.dart';
import 'ui/root_shell.dart';
import 'ui/status/status_toaster.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Dates keep Western digits in Arabic, like every other number in the app.
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  LicenseRegistry.addLicense(_fontLicence);

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(prefs),
        ),
        ChangeNotifierProvider<HistoryStore>(
          create: (_) => HistoryStore(prefs),
        ),
        // Loads the bundled model on first use, then keeps it for every scan.
        ChangeNotifierProvider<OnDeviceModel>(create: (_) => OnDeviceModel()),
        // Not lazy: it starts watching the server as soon as the app opens.
        ChangeNotifierProvider<ServerMonitor>(
          lazy: false,
          create: (BuildContext context) =>
              ServerMonitor(context.read<SettingsController>()),
        ),
      ],
      child: const OssiaApp(),
    ),
  );
}

/// The bundled fonts' licence (SIL OFL), listed with the other licences.
Stream<LicenseEntry> _fontLicence() async* {
  final String text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(
    const <String>['Bricolage Grotesque', 'DM Sans', 'Baloo Bhaijaan 2', 'Readex Pro'],
    text,
  );
}

class OssiaApp extends StatefulWidget {
  const OssiaApp({super.key});

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<OssiaApp> createState() => _OssiaAppState();
}

class _OssiaAppState extends State<OssiaApp> {
  late final SettingsController _settings = context.read<SettingsController>();

  /// The language the statics below were last set for.
  String? _shown;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettings);
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    super.dispose();
  }

  /// Fonts (AppType) and number formats (AppLang) are statics, not inherited
  /// widgets, so a widget showing no translated words wouldn't notice a
  /// language switch. Rebuild every widget once instead: unlike keying the
  /// whole app, this keeps the open screens and scroll positions.
  void _onSettings() {
    if (_settings.localeCode == _shown) return;
    _use(_settings.localeCode);
    void mark(Element e) {
      e.markNeedsBuild();
      e.visitChildren(mark);
    }

    void rebuildAll() => WidgetsBinding.instance.rootElement?.visitChildren(mark);
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => rebuildAll());
    } else {
      rebuildAll();
    }
  }

  void _use(String code) {
    _shown = code;
    AppLang.code = code;
    AppType.arabic = code == 'ar';
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();
    // Before the theme is built, so its text styles are the right ones.
    if (settings.localeCode != _shown) _use(settings.localeCode);

    return MaterialApp(
      onGenerateTitle: (BuildContext context) => context.l10n.appName,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: OssiaApp.messengerKey,
      navigatorKey: OssiaApp.navigatorKey,
      locale: settings.language.locale,
      supportedLocales: <Locale>[for (final AppLanguage l in kLanguages) l.locale],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      themeMode: settings.themeMode,
      theme: AppTheme.build(Brightness.light, settings.accent),
      darkTheme: AppTheme.build(Brightness.dark, settings.accent),
      builder: (BuildContext context, Widget? child) {
        final Brightness b = Theme.of(context).brightness;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: AppTheme.overlay(b),
          // Keep layout predictable regardless of the user's text-size setting
          // being pushed to the extremes.
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0.85,
            maxScaleFactor: 1.35,
            child: StatusToaster(
              messengerKey: OssiaApp.messengerKey,
              navigatorKey: OssiaApp.navigatorKey,
              child: child!,
            ),
          ),
        );
      },
      home: const _Home(),
    );
  }
}

/// The language picker until a language has been chosen, then the app.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) {
    final bool chosen =
        context.select<SettingsController, bool>((SettingsController s) => s.hasChosenLocale);
    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Motion.exit,
      transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(a),
          child: child,
        ),
      ),
      child: chosen
          ? const RootShell(key: ValueKey<String>('app'))
          : const WelcomeScreen(key: ValueKey<String>('welcome')),
    );
  }
}
