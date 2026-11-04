import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ossia/core/theme/app_theme.dart';
import 'package:ossia/core/theme/palette.dart';
import 'package:ossia/data/history_store.dart';
import 'package:ossia/data/models/analysis.dart';
import 'package:ossia/data/on_device/on_device_model.dart';
import 'package:ossia/data/server_monitor.dart';
import 'package:ossia/data/settings_controller.dart';
import 'package:ossia/l10n/l10n.dart';
import 'package:ossia/ui/scan/scan_screen.dart';
import 'package:ossia/ui/settings/settings_screen.dart';
import 'package:ossia/ui/settings/store_links.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The Rate and Share rows and the review card. They are behind kStoreLinksLive,
/// so run this with and without `--dart-define=STORE_LINKS=true`.
void main() {
  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const MethodChannel launcher = MethodChannel('plugins.flutter.io/url_launcher');
  const MethodChannel sharing = MethodChannel('dev.fluttercommunity.plus/share');

  late List<String> opened;
  late bool opens;
  late List<Map<Object?, Object?>> shared;

  setUp(() {
    opened = <String>[];
    opens = true;
    shared = <Map<Object?, Object?>>[];
    messenger().setMockMethodCallHandler(launcher, (MethodCall call) async {
      opened.add((call.arguments as Map<Object?, Object?>)['url']! as String);
      return opens;
    });
    messenger().setMockMethodCallHandler(sharing, (MethodCall call) async {
      shared.add(call.arguments as Map<Object?, Object?>);
      return 'dev.fluttercommunity.plus/share/unavailable';
    });
  });

  tearDown(() {
    messenger().setMockMethodCallHandler(launcher, null);
    messenger().setMockMethodCallHandler(sharing, null);
  });

  /// [page] in the app's language, with [saved] reports saved, tall enough
  /// that nothing is scrolled out of reach.
  Future<SharedPreferences> show(WidgetTester t, Widget page, {int saved = 0}) async {
    t.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues(<String, Object>{
      'locale': 'en',
      'analysis_history': <String>[
        for (int i = 0; i < saved; i++) jsonEncode(_record('$i').toJson()),
      ],
    });
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<ChangeNotifier>>[
          ChangeNotifierProvider<SettingsController>(create: (_) => SettingsController(prefs)),
          ChangeNotifierProvider<HistoryStore>(create: (_) => HistoryStore(prefs, 'documents')),
          ChangeNotifierProvider<OnDeviceModel>(create: (_) => OnDeviceModel()),
          ChangeNotifierProvider<ServerMonitor>(
            create: (BuildContext context) => ServerMonitor(
              context.read<SettingsController>(),
              client: MockClient((http.Request _) async => http.Response('', 500)),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.build(Brightness.light, AccentTone.sunny),
          home: Scaffold(body: page),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 2));
    return prefs;
  }

  Future<void> finish(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 2));
  }

  AppLocalizations en() => lookupAppLocalizations(const Locale('en'));

  test('the links', () {
    expect(kAppStoreReviewUrl, 'https://apps.apple.com/app/id6828234526?action=write-review');
    expect(kPlayStoreUrl, 'https://play.google.com/store/apps/details?id=io.github.bigdonalds.ossia');
  });

  test('the shared text opens with the aim and carries both links, in every language', () {
    for (final String code in <String>['en', 'de', 'ar']) {
      final String text = lookupAppLocalizations(Locale(code)).shareText(kAppStoreUrl, kPlayStoreUrl);
      expect(text, startsWith(switch (code) {
        'de' => 'Ossia wurde für Orte mit knappen forensischen Mitteln',
        'ar' => 'صُمّم Ossia للأماكن',
        _ => 'Ossia is made for places with scarce forensic resources',
      }));
      expect(text, contains(kAppStoreUrl));
      expect(text, contains(kPlayStoreUrl));
    }
  });

  testWidgets('Rate opens the page for this phone, and says so if it can\'t',
      (WidgetTester t) async {
    await show(t, const SizedBox());
    final BuildContext context = t.element(find.byType(SizedBox).last);

    expect(await openStorePage(context), isTrue);
    expect(opened.last, kPlayStoreUrl);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(await openStorePage(context), isTrue);
    debugDefaultTargetPlatformOverride = null;
    expect(opened.last, kAppStoreReviewUrl);

    opens = false;
    expect(await openStorePage(context), isFalse);
    await t.pump();
    expect(find.text(en().storeOpenFailed), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await finish(t);
  });

  testWidgets('Share sends the text and points the sheet at the row', (WidgetTester t) async {
    await show(t, const SizedBox(width: 200, height: 50));
    await shareOssia(t.element(find.byType(SizedBox).last));
    expect(shared.single['text'], en().shareText(kAppStoreUrl, kPlayStoreUrl));
    expect(shared.single['originWidth'], greaterThan(0));
    await finish(t);
  });

  testWidgets('Settings shows the rows only when the flag is on', (WidgetTester t) async {
    await show(t, const SettingsScreen());
    final Matcher shown = kStoreLinksLive ? findsOneWidget : findsNothing;
    expect(find.text(en().settingsRate), shown);
    expect(find.text(en().settingsShare), shown);
    expect(find.text(en().settingsVersion), findsOneWidget);
    if (kStoreLinksLive) {
      await t.tap(find.text(en().settingsRate));
      await t.pump();
      expect(opened, <String>[kPlayStoreUrl]);
      await t.tap(find.text(en().settingsShare));
      await t.pump();
      expect(shared, hasLength(1));
    }
    await finish(t);
  });

  testWidgets('the Scan card waits for three saved reports', (WidgetTester t) async {
    await show(t, const ScanScreen(), saved: 2);
    expect(find.text(en().scanReviewTitle), findsNothing);
    await finish(t);
    await show(t, const ScanScreen(), saved: 3);
    expect(find.text(en().scanReviewTitle), kStoreLinksLive ? findsOneWidget : findsNothing);
    await finish(t);
  });

  testWidgets('closing the card puts it away for good', (WidgetTester t) async {
    final SharedPreferences prefs = await show(t, const ScanScreen(), saved: 3);
    await t.tap(find.byIcon(Icons.close_rounded));
    await t.pump(const Duration(seconds: 1));
    expect(find.text(en().scanReviewTitle), findsNothing);
    expect(prefs.getBool('review_card_dismissed'), isTrue);
    expect(opened, isEmpty);
    await finish(t);
    await t.pumpWidget(
      ChangeNotifierProvider<SettingsController>(
        create: (_) => SettingsController(prefs),
        child: Builder(
          builder: (BuildContext context) {
            expect(context.read<SettingsController>().reviewCardDismissed, isTrue);
            return const SizedBox();
          },
        ),
      ),
    );
    await finish(t);
  }, skip: !kStoreLinksLive);

  testWidgets('tapping the card opens the store and puts it away', (WidgetTester t) async {
    await show(t, const ScanScreen(), saved: 3);
    await t.tap(find.text(en().scanReviewTitle));
    await t.pump(const Duration(seconds: 1));
    expect(opened, <String>[kPlayStoreUrl]);
    expect(find.text(en().scanReviewTitle), findsNothing);
    await finish(t);
  }, skip: !kStoreLinksLive);

  testWidgets('the card stays if the store page won\'t open', (WidgetTester t) async {
    opens = false;
    await show(t, const ScanScreen(), saved: 3);
    await t.tap(find.text(en().scanReviewTitle));
    await t.pump(const Duration(milliseconds: 100));
    expect(find.text(en().storeOpenFailed), findsOneWidget);
    expect(find.text(en().scanReviewTitle), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await finish(t);
  }, skip: !kStoreLinksLive);
}

AnalysisRecord _record(String id) => AnalysisRecord(
      id: id,
      imagePath: 'no-photo.jpg',
      createdAt: DateTime(2026, 10, 16, 15, 5),
      result: const AnalysisResult(
        detection: Detection(present: true, confidence: 0.9),
        species: Scored(label: 'human', confidence: 0.9),
        boneTypes: <Scored>[Scored(label: 'femur', confidence: 0.9)],
        part: Scored(label: 'complete', confidence: 0.9),
        completeness: Scored(label: 'complete', confidence: 0.9),
        damage: DamageProfile(fracture: 0, cutMarks: 0, burnSigns: 0),
        animalSpecies: Scored(label: 'none', confidence: 0),
        biological: BiologicalProfile(
          ageGroup: 'adult',
          ageConfidence: 0.8,
          sex: 'unknown',
          sexConfidence: 0.5,
          applicable: true,
        ),
      ),
    );
