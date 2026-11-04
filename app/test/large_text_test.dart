import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:ossia/data/history_store.dart';
import 'package:ossia/data/models/analysis.dart';
import 'package:ossia/data/on_device/on_device_model.dart';
import 'package:ossia/data/reference_data.dart';
import 'package:ossia/data/server_monitor.dart';
import 'package:ossia/data/settings_controller.dart';
import 'package:ossia/l10n/l10n.dart';
import 'package:ossia/main.dart';
import 'package:ossia/ui/language/language_picker.dart';
import 'package:ossia/ui/library/library_screen.dart';
import 'package:ossia/ui/reference/bone_detail_screen.dart';
import 'package:ossia/ui/reference/pipeline_screen.dart';
import 'package:ossia/ui/reference/reference_screen.dart';
import 'package:ossia/ui/results/report_page.dart';
import 'package:ossia/ui/results/specimen_header.dart';
import 'package:ossia/ui/scan/analyzing_screen.dart';
import 'package:ossia/ui/scan/auto_snap_fx.dart';
import 'package:ossia/ui/scan/bone_guide.dart';
import 'package:ossia/ui/scan/camera_screen.dart';
import 'package:ossia/ui/scan/review_screen.dart';
import 'package:ossia/ui/scan/scan_screen.dart';
import 'package:ossia/ui/settings/about_screen.dart';
import 'package:ossia/ui/settings/privacy_screen.dart';
import 'package:ossia/ui/settings/settings_screen.dart';
import 'package:ossia/ui/status/model_status_screen.dart';
import 'package:ossia/ui/widgets/inset_group.dart';
import 'package:ossia/ui/widgets/nav.dart';
import 'package:ossia/ui/widgets/sheets.dart';
import 'package:ossia/ui/widgets/wide.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Larger Text: every screen at text scale 2.0, in English, German and Arabic,
/// at phone widths 320, 360 and 390 and on a tablet. Every page is scrolled
/// from top to bottom, and a test fails on
///
///  - an overflow (the framework reports those itself),
///  - text cut off by its box or ended with "…",
///  - text off the screen with no way to scroll to it,
///  - text printed on top of other text,
///  - text smaller than normal size.
///
/// The app's real fonts are loaded, so German and Arabic measure as they will
/// on a phone. Store links are behind kStoreLinksLive, so run this with and
/// without `--dart-define=STORE_LINKS=true` to cover both.
///
/// `--dart-define=SWEEP_SHOTS=<folder>` also saves a picture of every step,
/// with a list of the text below the phone's size and of words wrapped mid-word.
void main() {
  setUpAll(() async {
    await _loadFonts();
    DateFormat.useNativeDigitsByDefaultFor('ar', false);
  });

  tearDownAll(() {
    if (_shots.isNotEmpty) {
      File('$_shots/_caps.txt').writeAsStringSync((_caps.toList()..sort()).join('\n'));
      File('$_shots/_splits.txt').writeAsStringSync((_splits.toList()..sort()).join('\n'));
    }
  });

  testWidgets('text follows the phone up to 200% and no further', (WidgetTester t) async {
    final _Sweep s = _Sweep(t, 'en', _phones.first, 'clamp');
    await s.open();
    t.platformDispatcher.textScaleFactorTestValue = 3;
    await t.pump();
    expect(MediaQuery.textScalerOf(s.tabContext).scale(10), 20);
    await s.close();
  });

  for (final String lang in <String>['en', 'de', 'ar']) {
    for (final _Phone phone in _phones) {
      group('$lang at ${phone.width.toInt()}', () {
        _screens.forEach((String name, _Screen screen) {
          testWidgets(name, (WidgetTester t) async {
            final _Sweep s = _Sweep(t, lang, phone, name);
            await screen(s);
            await s.close();
          });
        });
      });
    }
  }
}

const double _scale = int.fromEnvironment('SWEEP_PERCENT', defaultValue: 200) / 100;
const String _shots = String.fromEnvironment('SWEEP_SHOTS');

class _Phone {
  const _Phone(this.width, this.height, this.top, this.bottom);

  final double width;
  final double height;
  final double top;
  final double bottom;
}

const List<_Phone> _phones = <_Phone>[
  _Phone(320, 568, 20, 0),
  _Phone(360, 640, 24, 0),
  _Phone(390, 844, 47, 34),
  _Phone(768, 1024, 24, 20),
];

/// Typed by the people using the app, so they can be any length.
const String _typedName = 'Trench 4, unit 12, specimen 0037 (left side)';
const String _typedNote = 'Found under the north wall with two others. Soil still on it; '
    'not cleaned, and the broken end looks fresh.';

final Set<String> _splits = <String>{};
final Set<String> _caps = <String>{};

typedef _Screen = Future<void> Function(_Sweep s);

final Map<String, _Screen> _screens = <String, _Screen>{
  'Welcome': (_Sweep s) async {
    await s.open(chosen: false);
    s.settings.previewLocale(s.lang);
    // The buddy greets in each language in turn.
    for (int i = 0; i < 3; i++) {
      await s.look('hello$i');
      await s.t.pump(const Duration(milliseconds: 1600));
    }
  },
  'Language sheet': (_Sweep s) async {
    await s.open();
    unawaited(showLanguageSheet(s.tabContext));
    await s.look('sheet');
  },
  'Scan, nothing saved': (_Sweep s) async {
    await s.open();
    await s.look('empty');
  },
  'Scan, one saved': (_Sweep s) async {
    await s.open(records: <AnalysisRecord>[_report(43)]);
    await s.look('one');
  },
  'Scan, three saved': (_Sweep s) async {
    await s.open(records: _several());
    await s.look('three');
  },
  'Scan, Online': (_Sweep s) async {
    await s.open(server: true, client: _healthy());
    await s.look('online');
  },
  'Camera, starting': (_Sweep s) async {
    _Camera.install(hang: true);
    await s.open();
    unawaited(openBoneCamera(s.tabContext));
    await s.look('starting');
    _Camera.remove();
  },
  'Camera, unavailable': (_Sweep s) async {
    _Camera.install();
    await s.open();
    unawaited(openBoneCamera(s.tabContext));
    await s.look('unavailable');
    _Camera.remove();
  },
  'Camera, no access': (_Sweep s) async {
    _Camera.install(denied: true);
    await s.open();
    unawaited(openBoneCamera(s.tabContext));
    await s.look('denied');
    _Camera.remove();
  },
  'Camera, ready, every outline': (_Sweep s) async {
    _Camera.install(ready: true);
    await s.open(prefs: <String, Object>{'auto_snap': false});
    unawaited(openBoneCamera(s.tabContext));
    await s.look('longBone');
    // The shapes are named on the picker; a tap changes the tip and outline.
    for (final GuideShape shape in <GuideShape>[GuideShape.skull, GuideShape.flat, GuideShape.small]) {
      // The later ones may be scrolled out of the picker.
      final AppLocalizations l = s.l10n;
      final ScrollableState picker = s.t.state<ScrollableState>(
        find.byWidgetPredicate((Widget w) => w is Scrollable && w.axis == Axis.horizontal).first,
      );
      for (double at = 0; find.text(shape.label(l)).evaluate().isEmpty; at += 80) {
        picker.position.jumpTo(at);
        await s.t.pump();
      }
      await s.t.tap(find.text(shape.label(l)), warnIfMissed: false);
      await s.look(shape.name);
    }
    await s.closeRoute();
    _Camera.remove();
  },
  'Camera, auto snap tips': (_Sweep s) async {
    _Camera.install(ready: true);
    await s.open(prefs: <String, Object>{'auto_snap': false});
    unawaited(openBoneCamera(s.tabContext));
    await s.settle();
    await s.t.tap(find.byIcon(Icons.motion_photos_auto_rounded), warnIfMissed: false);
    await s.look('on');
    await s.t.tap(find.byIcon(Icons.motion_photos_auto_rounded), warnIfMissed: false);
    await s.look('off');
    await s.closeRoute();
    _Camera.remove();
  },
  'Camera, another angle': (_Sweep s) async {
    _Camera.install(ready: true);
    await s.open(prefs: <String, Object>{'auto_snap': false});
    unawaited(captureAnotherAngle(s.tabContext, angle: 2, room: 7));
    await s.look('angle');
    await s.closeRoute();
    _Camera.remove();
  },
  'Auto snap stickers': (_Sweep s) async {
    await s.open();
    final AppLocalizations l = s.l10n;
    s.pushPage(Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: SpottedBadge(show: const AlwaysStoppedAnimation<double>(1), label: l.camAutoSpotted),
          ),
          Center(child: SnapStamp(t: 0.5, label: l.camAutoSnapped)),
        ],
      ),
    ));
    await s.look('stickers');
  },
  'Review, one photo': (_Sweep s) async {
    await s.open();
    s.pushRoot(ReviewScreen(images: _photos(1), fromCamera: true));
    await s.look('one');
  },
  'Review, three photos and a length': (_Sweep s) async {
    await s.open();
    s.pushRoot(ReviewScreen(images: _photos(3), lengthCm: 23.5));
    await s.look('three');
  },
  'Review, full': (_Sweep s) async {
    await s.open(prefs: <String, Object>{'unit': 1});
    s.pushRoot(ReviewScreen(images: _photos(8), lengthCm: 120));
    await s.look('full');
  },
  'Review, adding angles': (_Sweep s) async {
    await s.open();
    final AnalysisRecord r = _report(43, label: _typedName);
    s.pushRoot(ReviewScreen(images: _photos(2), revising: r));
    await s.look('revising');
  },
  'Analyzing': (_Sweep s) async {
    await s.open(hangingModel: true);
    s.pushRoot(AnalyzingScreen(images: _photos(1)));
    await s.look('progress');
  },
  'Analyzing, several photos': (_Sweep s) async {
    await s.open(hangingModel: true);
    s.pushRoot(AnalyzingScreen(images: _photos(3), lengthCm: 30));
    await s.look('progress');
  },
  'Analyzing, failed': (_Sweep s) async {
    await s.open(status: OnDeviceStatus.failed);
    s.pushRoot(AnalyzingScreen(images: _photos(1)));
    await s.look('failed');
  },
  'Analyzing, failed online': (_Sweep s) async {
    await s.refusingNetwork(() async {
      await s.open(server: true, client: _broken());
      // A real photo: the upload reads it before it finds nobody is there.
      s.pushRoot(AnalyzingScreen(images: <File>[File('test/fixtures/prep/grey.png')]));
      await s.t.pump();
      await s.t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await s.look('offer');
      expect(find.text(s.l10n.analyzingOnPhone), findsOneWidget);
    });
  },
  'Report, human': (_Sweep s) async {
    await s.report(_report(0));
  },
  'Report, animal': (_Sweep s) async {
    await s.report(_report(43));
  },
  'Report, no bone': (_Sweep s) async {
    await s.report(_report(34));
  },
  'Report, several photos': (_Sweep s) async {
    await s.report(_report(84));
  },
  'Report, some photos without a bone': (_Sweep s) async {
    await s.report(_report(81));
  },
  'Report, name, note and length': (_Sweep s) async {
    await s.report(_report(52, label: _typedName, note: _typedNote));
  },
  'Report, in inches and not saved': (_Sweep s) async {
    await s.open(prefs: <String, Object>{'unit': 1, 'hide_low_conf': true});
    s.pushRoot(ReportPage(record: _report(60), saved: false, showAnalyzeAnother: true), wide: true);
    await s.look('unsaved');
  },
  'Report, longest words': (_Sweep s) async {
    await s.report(_longest());
  },
  'Report options and name prompt': (_Sweep s) async {
    await s.open(records: <AnalysisRecord>[_report(43)]);
    s.pushPage(ReportPage(record: s.history.records.first, saved: true), wide: true);
    await s.settle();
    await s.t.tap(find.byType(HeaderAction), warnIfMissed: false);
    await s.look('options');
    final AppLocalizations l = s.l10n;
    await s.t.tap(find.text(l.reportNameTitle), warnIfMissed: false);
    await s.look('name');
    await s.keyboard(() => s.look('name, keyboard'));
  },
  'Stash, empty': (_Sweep s) async {
    await s.open();
    await s.tab(1);
    await s.look('empty');
  },
  'Stash, every filter': (_Sweep s) async {
    await s.open(records: _several());
    await s.tab(1);
    await s.look('all');
    for (final LibraryFilter f in <LibraryFilter>[LibraryFilter.human, LibraryFilter.faunal, LibraryFilter.flagged]) {
      s.t
          .widget<SegmentedControl<LibraryFilter>>(find.byType(SegmentedControl<LibraryFilter>))
          .onChanged(f);
      await s.look(f.name);
    }
  },
  'Stash, nothing matches': (_Sweep s) async {
    await s.open(records: _several());
    await s.tab(1);
    await s.settle();
    await s.t.enterText(find.byType(TextField), 'no such bone');
    await s.look('no match');
  },
  'Bones tab': (_Sweep s) async {
    await s.open();
    await s.tab(2);
    await s.look('tab');
  },
  'Every bone page': (_Sweep s) async {
    await s.open();
    await s.tab(2);
    for (final BoneEntry e in kBoneReference) {
      s.pushPage(BoneDetailScreen(entry: e));
      await s.look(e.key);
      await s.closeRoute();
    }
  },
  'How the AI thinks': (_Sweep s) async {
    await s.open();
    s.pushPage(const PipelineScreen());
    await s.look('how');
  },
  'Settings, on this phone': (_Sweep s) async {
    await s.open(records: _several());
    await s.tab(3);
    await s.look('phone');
  },
  'Settings, Online': (_Sweep s) async {
    await s.open(server: true, client: _healthy(), prefs: <String, Object>{
      'server_url': 'http://192.168.100.200:8000/a/rather/long/path/to/the/ossia/computer',
    });
    await s.tab(3);
    await s.look('online');
  },
  'Server address prompt': (_Sweep s) async {
    await s.open(server: true, client: _healthy());
    await s.tab(3);
    await s.settle();
    final AppLocalizations l = s.l10n;
    unawaited(promptForText(
      s.tabContext,
      title: l.settingsOnlineAddress,
      message: l.settingsOnlineAddressBody,
      initial: s.settings.serverUrl,
      placeholder: 'https://…',
      keyboard: TextInputType.url,
    ));
    await s.look('prompt');
    await s.keyboard(() => s.look('prompt, keyboard'));
  },
  'Status, on this phone': (_Sweep s) async {
    for (final OnDeviceStatus status in OnDeviceStatus.values) {
      await s.open(status: status);
      s.pushPage(const ModelStatusScreen());
      await s.look(status.name);
      await s.close();
    }
  },
  'Status, Online and connected': (_Sweep s) async {
    await s.open(server: true, client: _healthy());
    s.pushPage(const ModelStatusScreen());
    for (int i = 0; i < 12; i++) {
      await s.t.pump(const Duration(seconds: 1));
    }
    await s.look('connected');
  },
  'Status, Online and cut off': (_Sweep s) async {
    await s.open(server: true, client: _broken());
    s.pushPage(const ModelStatusScreen());
    for (int i = 0; i < 12; i++) {
      await s.t.pump(const Duration(seconds: 1));
    }
    await s.look('offline');
  },
  'About': (_Sweep s) async {
    await s.open();
    s.pushPage(const AboutScreen());
    await s.look('about');
  },
  'Privacy': (_Sweep s) async {
    await s.open();
    s.pushPage(const PrivacyScreen());
    await s.look('privacy');
  },
  'Dialogs': (_Sweep s) async {
    await s.open();
    final AppLocalizations l = s.l10n;
    final BuildContext c = s.tabContext;
    unawaited(confirm(
      c,
      title: l.settingsDeleteAllTitle,
      message: l.settingsDeleteAllBody(12),
      confirmLabel: l.settingsDeleteAllConfirm,
      destructive: true,
    ));
    await s.look('delete all');
    await s.closeRoute();
    unawaited(confirm(
      c,
      title: l.reviewDropTitle,
      message: l.reviewDropNew(3),
      confirmLabel: l.reviewDropConfirm,
      destructive: true,
    ));
    await s.look('drop photos');
    await s.closeRoute();
  },
  'Prompts': (_Sweep s) async {
    await s.open();
    final AppLocalizations l = s.l10n;
    final BuildContext c = s.tabContext;
    unawaited(promptForText(
      c,
      title: l.reportAddNote,
      message: l.reportNoteBody,
      placeholder: l.reportNotePlaceholder,
      actionLabel: l.done,
    ));
    await s.look('note');
    await s.keyboard(() => s.look('note, keyboard'));
    await s.closeRoute();
    unawaited(promptForText(
      c,
      title: l.reviewTypeLength,
      message: l.reviewTypeLengthCm,
      placeholder: l.reviewExample('23.5'),
      keyboard: const TextInputType.numberWithOptions(decimal: true),
      actionLabel: l.reviewSetLength,
    ));
    await s.look('length');
    await s.keyboard(() => s.look('length, keyboard'));
    await s.closeRoute();
  },
  'Toasts': (_Sweep s) async {
    await s.open();
    final AppLocalizations l = s.l10n;
    for (final (String name, String text, IconData? icon) in <(String, String, IconData?)>[
      ('now speaking', l.languageNowSpeaking, Icons.language_rounded),
      ('saved', l.reportSavedToast, Icons.inventory_2_outlined),
      ('lost', l.toastLostConnection, Icons.cloud_off_rounded),
      ('back', l.toastBackOnline, Icons.cloud_done_rounded),
      ('copied', l.settingsCopiedCount(12), Icons.check_rounded),
      ('no store page', l.storeOpenFailed, Icons.error_outline_rounded),
      ('no sharing', l.shareFailed, Icons.error_outline_rounded),
    ]) {
      showToast(s.tabContext, text, icon: icon);
      await s.look(name);
      await s.t.pump(const Duration(seconds: 3));
      await s.t.pump(const Duration(seconds: 1));
    }
  },
};

/// The drivers and checks.
class _Sweep {
  _Sweep(this.t, this.lang, this.phone, this.name);

  final WidgetTester t;
  final String lang;
  final _Phone phone;
  final String name;

  late SettingsController settings;
  late HistoryStore history;
  final Set<String> _problems = <String>{};

  double get _pixelRatio => _shots.isEmpty ? 1 : 2;

  Future<void> open({
    bool chosen = true,
    bool server = false,
    bool hangingModel = false,
    OnDeviceStatus status = OnDeviceStatus.ready,
    http.Client? client,
    List<AnalysisRecord> records = const <AnalysisRecord>[],
    Map<String, Object> prefs = const <String, Object>{},
  }) async {
    final double ratio = _pixelRatio;
    t.view
      ..devicePixelRatio = ratio
      ..physicalSize = Size(phone.width, phone.height) * ratio
      ..padding = FakeViewPadding(top: phone.top * ratio, bottom: phone.bottom * ratio)
      ..viewPadding = FakeViewPadding(top: phone.top * ratio, bottom: phone.bottom * ratio);
    t.platformDispatcher
      ..textScaleFactorTestValue = _scale
      ..localesTestValue = <Locale>[Locale(lang)]
      ..localeTestValue = Locale(lang);
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearAllTestValues);

    SharedPreferences.setMockInitialValues(<String, Object>{
      if (chosen) 'locale': lang,
      if (server) 'engine': 'server',
      if (records.isNotEmpty)
        'analysis_history': <String>[
          for (final AnalysisRecord r in records) jsonEncode(r.toJson()),
        ],
      ...prefs,
    });
    final SharedPreferences store = await SharedPreferences.getInstance();
    await t.pumpWidget(
      MultiProvider(
        providers: <ChangeNotifierProvider<ChangeNotifier>>[
          ChangeNotifierProvider<SettingsController>(create: (_) => settings = SettingsController(store)),
          ChangeNotifierProvider<HistoryStore>(create: (_) => history = HistoryStore(store, 'documents')),
          ChangeNotifierProvider<OnDeviceModel>(
            create: (_) => _FixedModel(status, hanging: hangingModel),
          ),
          ChangeNotifierProvider<ServerMonitor>(
            lazy: false,
            create: (BuildContext context) => ServerMonitor(
              context.read<SettingsController>(),
              client: client ?? _broken(),
            ),
          ),
        ],
        child: const OssiaApp(),
      ),
    );
    await settle();
  }

  /// Lets the entrances and page slides finish. The mascot never stops
  /// moving, so this pumps a fixed time rather than until everything is still.
  Future<void> settle() async {
    for (int i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  BuildContext get tabContext {
    final Finder scan = find.byType(ScanScreen, skipOffstage: false);
    return t.element(scan.first);
  }

  AppLocalizations get l10n => AppLocalizations.of(tabContext);

  NavigatorState get _rootNavigator => OssiaApp.navigatorKey.currentState!;

  /// Pushed as the app pushes it: on the current tab's navigator, phone-wide
  /// on a tablet unless [wide].
  void pushPage(Widget page, {bool wide = false}) {
    final NavigatorState nav = Navigator.of(_currentTabContext());
    nav.push(wide
        ? WidePageRoute<void>(builder: (_) => page)
        : MaterialPageRoute<void>(builder: (_) => page));
  }

  /// Pushed over the tabs, as the scan flow is.
  void pushRoot(Widget page, {bool wide = false}) {
    _rootNavigator.push(wide
        ? WidePageRoute<void>(builder: (_) => page)
        : MaterialPageRoute<void>(builder: (_) => page));
  }

  BuildContext _currentTabContext() {
    for (final Type type in <Type>[ReferenceScreen, SettingsScreen, LibraryScreen, ScanScreen]) {
      final Finder f = find.byType(type);
      if (f.evaluate().isNotEmpty) return t.element(f.first);
    }
    return tabContext;
  }

  Future<void> tab(int i) async {
    t.widget<AppTabBar>(find.byType(AppTabBar)).onChanged(i);
    await t.pump();
  }

  Future<void> report(AnalysisRecord record) async {
    await open(records: <AnalysisRecord>[record]);
    pushPage(ReportPage(record: history.records.first, saved: true), wide: true);
    await look('report');
  }

  Future<void> closeRoute() async {
    final NavigatorState nav = _rootNavigator;
    if (nav.canPop()) {
      nav.pop();
    } else {
      Navigator.of(_currentTabContext()).maybePop();
    }
    await settle();
  }

  /// [body] with the keyboard up.
  Future<void> keyboard(Future<void> Function() body) async {
    final double height = (phone.height * 0.42) * _pixelRatio;
    t.view.viewInsets = FakeViewPadding(bottom: height);
    await t.pump();
    await body();
    t.view.viewInsets = FakeViewPadding.zero;
    await t.pump();
  }

  /// [body] with every connection refused, for the "can't reach it" paths.
  Future<void> refusingNetwork(Future<void> Function() body) async {
    final HttpOverrides? before = HttpOverrides.current;
    HttpOverrides.global = _Refuse();
    try {
      await body();
    } finally {
      HttpOverrides.global = before;
    }
  }

  Future<void> close() async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 6));
    await t.pump(const Duration(seconds: 6));
    expect(_problems, isEmpty);
  }

  /// Checks the screen as it is, then a viewport at a time down every page
  /// that scrolls, and back to the top.
  Future<void> look(String state) async {
    await settle();
    int step = 0;
    await _inspect(state, step);
    for (final ScrollableState page in _verticalPages()) {
      final ScrollPosition p = page.position;
      final double stride = p.viewportDimension * 0.7;
      while (p.pixels < p.maxScrollExtent - 1) {
        p.jumpTo((p.pixels + stride).clamp(0.0, p.maxScrollExtent));
        await t.pump();
        await t.pump(const Duration(milliseconds: 300));
        await _inspect(state, ++step);
      }
      p.jumpTo(0);
      await t.pump();
    }
  }

  List<ScrollableState> _verticalPages() => <ScrollableState>[
        for (final Element e in find.byType(Scrollable).evaluate())
          if ((e as StatefulElement).state case final ScrollableState s
              when s.position.axis == Axis.vertical &&
                  s.position.maxScrollExtent > 0 &&
                  (ModalRoute.of(e)?.isCurrent ?? true))
            s,
      ];

  Future<void> _inspect(String state, int step) async {
    final String where = '$lang ${phone.width.toInt()} $name [$state]';
    final List<_Seen> seen = <_Seen>[];
    final Size screen = Size(phone.width, phone.height);

    for (final Element e in find.byType(RichText).evaluate()) {
      // An icon is drawn as a one-letter text, but it isn't one.
      if (e.findAncestorWidgetOfExactType<Icon>() != null) continue;
      final RenderParagraph p = e.renderObject! as RenderParagraph;
      // The letter stickers on the Welcome page are part of its drawing.
      if (identical(p.textScaler, TextScaler.noScaling)) continue;
      final String text = p.text.toPlainText(includePlaceholders: false).trim();
      if (text.isEmpty || !p.hasSize || !_shown(p)) continue;

      final Matrix4 toScreen = p.getTransformTo(null);
      final Rect rect = MatrixUtils.transformRect(toScreen, Offset.zero & p.size);
      final String quote = '"${text.length > 50 ? '${text.substring(0, 50)}…' : text}"';

      if (p.didExceedMaxLines) _problems.add('$where: $quote is cut short with "…"');
      if (p.textSize.height > p.size.height + 1) _problems.add('$where: $quote is cut off below');
      if (p.textSize.width > p.size.width + 1) _problems.add('$where: $quote is cut off at the side');

      final ScrollableState? scroller = e.findAncestorStateOfType<ScrollableState>();
      final Axis? axis = scroller?.position.axis;
      if (axis != Axis.horizontal && (rect.left < -1 || rect.right > screen.width + 1)) {
        _problems.add('$where: $quote runs off the side of the screen');
      }
      if (axis == null && (rect.top < -1 || rect.bottom > screen.height + 1)) {
        _problems.add('$where: $quote is off the screen, with no way to scroll to it');
      }

      final double shown =
          p.textScaler.scale(100) / 100 * toScreen.getMaxScaleOnAxis() / _scale;
      if (shown < 0.97) _caps.add('$lang ${phone.width.toInt()} ×${(shown * _scale).toStringAsFixed(2)} $quote');
      if (shown * _scale < 0.99) _problems.add('$where: $quote is smaller than normal size');
      if (p.getMinIntrinsicWidth(double.infinity) > p.size.width + 1) {
        _splits.add('$lang ${phone.width.toInt()} $quote');
      }
      if (_onScreen(p, rect, screen)) seen.add(_Seen(quote, rect, _layerOf(e)));
    }

    for (int i = 0; i < seen.length; i++) {
      for (int j = i + 1; j < seen.length; j++) {
        if (seen[i].layer != seen[j].layer) continue;
        final Rect both = seen[i].rect.intersect(seen[j].rect);
        if (both.isEmpty) continue;
        final double smaller = <double>[
          seen[i].rect.width * seen[i].rect.height,
          seen[j].rect.width * seen[j].rect.height,
        ].reduce((double a, double b) => a < b ? a : b);
        if (both.width * both.height > smaller * 0.25) {
          _problems.add('$where: ${seen[i].text} is printed over ${seen[j].text}');
        }
      }
    }

    if (_shots.isNotEmpty) await _shoot(state, step);
  }

  /// True for text in view. Whatever has scrolled past a page's end isn't laid
  /// out where it would show, so it can't collide with anything.
  bool _onScreen(RenderParagraph p, Rect rect, Size screen) {
    Rect view = Offset.zero & screen;
    final RenderAbstractViewport? page = RenderAbstractViewport.maybeOf(p);
    if (page case final RenderBox box) {
      view = view.intersect(MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size));
    }
    return rect.overlaps(view);
  }

  /// Text only collides with text in the same layer: a pinned header and what
  /// scrolls under it, or a page and a toast, are meant to overlap.
  Object _layerOf(Element e) =>
      e.findAncestorRenderObjectOfType<RenderSliverPersistentHeader>() ??
      e.findAncestorStateOfType<ScrollableState>() ??
      e.findAncestorWidgetOfExactType<SnackBar>() ??
      ModalRoute.of(e) ??
      this;

  /// False for text faded out: the bar title before the page has scrolled.
  bool _shown(RenderObject start) {
    RenderObject? r = start;
    while (r != null) {
      if (r is RenderOpacity && r.opacity < 0.2) return false;
      if (r is RenderAnimatedOpacity && r.opacity.value < 0.2) return false;
      r = r.parent;
    }
    return true;
  }

  Future<void> _shoot(String state, int step) async {
    final Element root = find.byType(OssiaApp).evaluate().first;
    await t.runAsync(() async {
      final ui.Image image = await captureImage(root);
      final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final String file = '${lang}_${phone.width.toInt()}_${name}_${state}_$step'
          .replaceAll(RegExp(r'[^A-Za-z0-9_]+'), '-');
      File('$_shots/$file.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}

class _Seen {
  const _Seen(this.text, this.rect, this.layer);

  final String text;
  final Rect rect;
  final Object layer;
}

/// A model that is ready, or stuck, without loading anything.
class _FixedModel extends OnDeviceModel {
  _FixedModel(this._status, {required this.hanging});

  final OnDeviceStatus _status;
  final bool hanging;

  @override
  OnDeviceStatus get status => _status;

  @override
  Future<void> ensureLoaded() {
    if (hanging) return Completer<void>().future;
    if (_status == OnDeviceStatus.failed) return Future<void>.error(StateError('no model'));
    return Future<void>.value();
  }
}

/// A stand-in for the camera plugin.
abstract final class _Camera {
  static const MethodChannel _channel = MethodChannel('plugins.flutter.io/camera');

  static TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  static void install({bool hang = false, bool denied = false, bool ready = false}) {
    _messenger.setMockMethodCallHandler(_channel, (MethodCall call) async {
      switch (call.method) {
        case 'availableCameras':
          if (hang) return Completer<Object?>().future;
          if (denied) throw PlatformException(code: 'CameraAccessDenied');
          if (!ready) return <Map<String, Object>>[];
          return <Map<String, Object>>[
            <String, Object>{'name': 'back', 'lensFacing': 'back', 'sensorOrientation': 90},
          ];
        case 'create':
          return <String, Object>{'cameraId': 1};
        case 'initialize':
          unawaited(_messenger.handlePlatformMessage(
            'flutter.io/cameraPlugin/camera1',
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('initialized', <String, Object>{
                'previewWidth': 1920.0,
                'previewHeight': 1080.0,
                'exposureMode': 'auto',
                'focusMode': 'auto',
                'exposurePointSupported': true,
                'focusPointSupported': true,
              }),
            ),
            (_) {},
          ));
          return null;
        case 'getMinZoomLevel':
          return 1.0;
        case 'getMaxZoomLevel':
          return 4.0;
        default:
          return null;
      }
    });
  }

  static void remove() => _messenger.setMockMethodCallHandler(_channel, null);
}

/// Every HTTP connection refused, as with a computer that is switched off.
class _Refuse extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _RefusingClient();
}

class _RefusingClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future<HttpClientRequest>.error(const SocketException('Connection refused'));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

http.Client _healthy() => MockClient((http.Request _) async => http.Response(
      jsonEncode(<String, Object>{
        'service': 'ossia-analysis',
        'model': 'bone_analyzer.pt',
        'device': 'cpu',
        'uptime_s': 93784,
      }),
      200,
    ));

http.Client _broken() =>
    MockClient((http.Request _) async => throw const SocketException('Connection refused'));

List<File> _photos(int n) => <File>[for (int i = 0; i < n; i++) File('no-photo-$i.jpg')];

final List<dynamic> _cases = (jsonDecode(
  File('test/fixtures/on_device_reports.json').readAsStringSync(),
) as Map<String, dynamic>)['cases'] as List<dynamic>;

AnalysisRecord _report(int index, {String? label, String? note}) {
  final Map<String, dynamic> c = _cases[index] as Map<String, dynamic>;
  final AnalysisResult r = AnalysisResult.fromJson(c['expected'] as Map<String, dynamic>);
  return _record('$index', r, label: label, note: note, lengthCm: (c['length_cm'] as num?)?.toDouble());
}

AnalysisRecord _record(String id, AnalysisResult r, {String? label, String? note, double? lengthCm}) =>
    AnalysisRecord(
      id: id,
      imagePath: 'no-photo-0.jpg',
      extraImagePaths: <String>[for (int i = 1; i < r.imageCount; i++) 'no-photo-$i.jpg'],
      createdAt: DateTime(2026, 10, 16, 15, 5),
      result: r,
      label: label,
      note: note,
      measuredLengthCm: lengthCm,
    );

/// Saved reports of every kind.
List<AnalysisRecord> _several() => <AnalysisRecord>[
      _report(0),
      _report(43, label: _typedName, note: _typedNote),
      _report(34),
      _longest(),
    ];

/// The longest words a report can hold, in every box at once: three bones in
/// the running, every mark found, both "could also be" lines, and a length
/// that changed the answer.
AnalysisRecord _longest() {
  final AnalysisResult changed =
      AnalysisResult.fromJson((_cases[52] as Map<String, dynamic>)['expected'] as Map<String, dynamic>);
  return _record(
    'longest',
    AnalysisResult(
      detection: const Detection(present: true, confidence: 0.91),
      species: const Scored(label: 'non_human', confidence: 0.62),
      boneTypes: const <Scored>[
        Scored(label: 'cervical_vertebrae', confidence: 0.44),
        Scored(label: 'thoracic_vertebrae', confidence: 0.31),
        Scored(label: 'lumbar_vertebrae', confidence: 0.17),
      ],
      part: const Scored(label: 'proximal_end', confidence: 0.55),
      completeness: const Scored(label: 'fragment', confidence: 0.61),
      damage: const DamageProfile(fracture: 0.81, cutMarks: 0.72, burnSigns: 0.66),
      animalSpecies: const Scored(label: 'other_mammal', confidence: 0.58),
      biological: const BiologicalProfile(
        ageGroup: 'unknown',
        ageConfidence: 0,
        sex: 'unknown',
        sexConfidence: 0,
        applicable: false,
      ),
      length: const LengthEstimate(
        minCm: 12.5,
        maxCm: 145.5,
        fromReference: true,
        referenceFor: 'human femur',
      ),
      lengthCheck: changed.lengthCheck,
      imageCount: 8,
      photosWithBone: 5,
      source: const AnalysisSource(onDevice: false, model: 'bone_analyzer.pt', elapsedMs: 1234),
    ),
    label: _typedName,
    note: _typedNote,
    lengthCm: 35.5,
  );
}

Future<void> _loadFonts() async {
  final List<dynamic> families =
      jsonDecode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final dynamic family in families) {
    final Map<String, dynamic> f = family as Map<String, dynamic>;
    final FontLoader loader = FontLoader(f['family'] as String);
    for (final dynamic font in f['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load((font as Map<String, dynamic>)['asset'] as String));
    }
    await loader.load();
  }
}
