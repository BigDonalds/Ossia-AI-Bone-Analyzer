import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import 'analysis_engine.dart';
import 'settings_controller.dart';

/// Overall link to the analysis model.
enum LinkState {
  /// Scans run on the phone's own model; no server involved.
  onDevice,

  /// Live mode, but nothing has been checked yet.
  unknown,
  checking,
  online,
  offline,
}

enum StepStatus { pending, running, passed, failed, skipped }

/// One line of the connection checklist.
class CheckStep {
  CheckStep(this.id, this.title);

  final String id;
  final LocalText title;
  StepStatus status = StepStatus.pending;
  LocalText? detail;
}

/// A ping as it happens, for the page's animation to follow.
sealed class PingEvent {
  const PingEvent();
}

class PingSent extends PingEvent {
  const PingSent();
}

class PingReturned extends PingEvent {
  const PingReturned(this.ms);
  final int ms;
}

class PingLost extends PingEvent {
  const PingLost(this.reason);
  final LocalText reason;
}

/// Keeps an eye on the analysis server: a light health ping every
/// [interval] while the app is in the foreground, straight away when the app
/// resumes or the server settings change, plus a step-by-step check the status
/// page can run on demand.
class ServerMonitor extends ChangeNotifier with WidgetsBindingObserver {
  ServerMonitor(this._settings, {http.Client? client})
      : _client = client ?? http.Client() {
    _mode = _settings.engine;
    _url = _settings.serverUrl;
    _settings.addListener(_onSettings);
    WidgetsBinding.instance.addObserver(this);
    _restart();
  }

  static const Duration interval = Duration(seconds: 30);
  static const Duration timeout = Duration(seconds: 8);
  static const int historyLength = 20;

  final SettingsController _settings;
  final http.Client _client;
  final StreamController<PingEvent> _pings = StreamController<PingEvent>.broadcast();

  late EngineMode _mode;
  late String _url;
  Timer? _timer;
  bool _inFlight = false;
  bool _fullRunning = false;
  bool _disposed = false;

  LinkState _state = LinkState.unknown;
  LocalText? _error;
  String? _model;
  String? _device;
  int? _uptimeS;
  int? _latencyMs;
  DateTime? _lastChecked;
  DateTime? _nextCheck;
  final List<int?> _history = <int?>[];

  final List<CheckStep> steps = <CheckStep>[
    CheckStep('address', (AppLocalizations l) => l.checkAddress),
    CheckStep('reach', (AppLocalizations l) => l.checkReach),
    CheckStep('server', (AppLocalizations l) => l.checkServer),
    CheckStep('model', (AppLocalizations l) => l.checkModel),
    CheckStep('ping', (AppLocalizations l) => l.checkSpeed),
  ];

  LinkState get state => _state;
  bool get fullCheckRunning => _fullRunning;
  LocalText? get error => _error;
  String? get model => _model;
  String? get device => _device;
  int? get uptimeSeconds => _uptimeS;
  int? get latencyMs => _latencyMs;
  DateTime? get lastChecked => _lastChecked;
  DateTime? get nextCheck => _nextCheck;

  /// Most recent last; `null` entries are failed pings.
  List<int?> get history => List<int?>.unmodifiable(_history);
  Stream<PingEvent> get pings => _pings.stream;
  String get serverUrl => _settings.serverUrl;

  // ── Scheduling ────────────────────────────────────────────────────────────

  void _onSettings() {
    if (_settings.engine == _mode && _settings.serverUrl == _url) return;
    _mode = _settings.engine;
    _url = _settings.serverUrl;
    _history.clear();
    _latencyMs = null;
    _model = null;
    _device = null;
    _uptimeS = null;
    for (final CheckStep s in steps) {
      s
        ..status = StepStatus.pending
        ..detail = null;
    }
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (_settings.onDevice) {
      _state = LinkState.onDevice;
      _error = null;
      _nextCheck = null;
      for (final CheckStep s in steps) {
        s
          ..status = StepStatus.skipped
          ..detail = null;
      }
      _notify();
      return;
    }
    if (_state == LinkState.onDevice) _state = LinkState.unknown;
    _notify();
    quickCheck();
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    if (_settings.onDevice) return;
    _nextCheck = DateTime.now().add(interval);
    _timer = Timer.periodic(interval, (_) {
      _nextCheck = DateTime.now().add(interval);
      quickCheck();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_settings.onDevice) {
        quickCheck();
        _schedule();
      }
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _nextCheck = null;
    }
  }

  // ── Checks ────────────────────────────────────────────────────────────────

  Uri _healthUri() {
    final Uri analyze = RemoteEngine.endpointFor(_settings.serverUrl);
    final String path = analyze.path.substring(0, analyze.path.length - '/analyze'.length);
    return analyze.replace(path: '$path/');
  }

  /// One quiet health ping. Updates the state, the history and the checklist.
  Future<void> quickCheck() async {
    if (_settings.onDevice || _inFlight || _fullRunning) return;
    _inFlight = true;
    if (_state == LinkState.unknown) {
      _state = LinkState.checking;
      _notify();
    }
    final _Probe probe = await _probe();
    _inFlight = false;
    _apply(probe, animateSteps: false);
  }

  /// The full, step-by-step check shown on the status page.
  Future<void> fullCheck() async {
    if (_fullRunning) return;
    if (_settings.onDevice) {
      _restart();
      return;
    }
    // Let a background ping finish first so the two don't interleave.
    while (_inFlight) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _fullRunning = true;
    _state = LinkState.checking;
    _error = null;
    for (final CheckStep s in steps) {
      s
        ..status = StepStatus.pending
        ..detail = null;
    }
    _notify();

    // 1. Address.
    await _run('address', () async {
      try {
        final Uri u = _healthUri();
        if (u.host.isEmpty) throw const FormatException();
        if (RemoteEngine.pointsAtThisDevice(u)) {
          return (false, RemoteEngine.thisDeviceHint(u));
        }
        return (true, verbatim('${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}'));
      } catch (_) {
        return (false, (AppLocalizations l) => l.checkBadAddress);
      }
    });
    if (_failedAt('address')) return _finishFull();

    // 2–4. One real request, read three ways.
    _Probe? probe;
    await _run('reach', () async {
      probe = await _probe();
      final _Probe p = probe!;
      if (p.transportError != null) return (false, p.transportError!);
      return (true, (AppLocalizations l) => l.checkAnsweredIn(p.ms));
    });
    if (_failedAt('reach')) {
      _apply(probe!, animateSteps: true);
      return _finishFull();
    }
    await _run('server', () async {
      final _Probe p = probe!;
      if (p.httpError != null) return (false, p.httpError!);
      return (true, (AppLocalizations l) => l.checkRunningFor(l.uptime(p.uptime)));
    });
    if (_failedAt('server')) {
      _apply(probe!, animateSteps: true);
      return _finishFull();
    }
    await _run('model', () async {
      final _Probe p = probe!;
      return p.model == null
          ? (false, (AppLocalizations l) => l.checkNotReady)
          : (true, (AppLocalizations l) => l.checkReady);
    });

    // 5. A few pings for a steadier number.
    await _run('ping', () async {
      final List<int> times = <int>[];
      _Probe? last;
      for (int i = 0; i < 3; i++) {
        last = await _probe();
        if (last.ok) {
          times.add(last.ms);
        } else {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      if (times.isEmpty) {
        _apply(last!, animateSteps: true);
        return (false, last.transportError ?? last.httpError ?? ((AppLocalizations l) => l.checkLost));
      }
      final int avg = (times.reduce((int a, int b) => a + b) / times.length).round();
      _apply(last!.copyWithMs(avg), animateSteps: true);
      return (true, (AppLocalizations l) => l.checkPing(avg, l.pingWord(avg)));
    });
    _finishFull();
  }

  bool _failedAt(String id) =>
      steps.firstWhere((CheckStep s) => s.id == id).status == StepStatus.failed;

  void _finishFull() {
    for (final CheckStep s in steps) {
      if (s.status == StepStatus.pending) s.status = StepStatus.skipped;
    }
    if (steps.any((CheckStep s) => s.status == StepStatus.failed)) {
      _state = LinkState.offline;
    }
    _fullRunning = false;
    _schedule();
    _notify();
  }

  /// Runs one checklist step with a minimum on-screen time, so each tick
  /// lands one after another rather than all at once.
  Future<void> _run(String id, Future<(bool, LocalText)> Function() body) async {
    final CheckStep step = steps.firstWhere((CheckStep s) => s.id == id);
    step.status = StepStatus.running;
    _notify();
    final Stopwatch sw = Stopwatch()..start();
    final (bool ok, LocalText detail) = await body();
    final int left = 550 - sw.elapsedMilliseconds;
    if (left > 0) await Future<void>.delayed(Duration(milliseconds: left));
    step
      ..status = ok ? StepStatus.passed : StepStatus.failed
      ..detail = detail;
    _notify();
  }

  Future<_Probe> _probe() async {
    final Uri uri;
    try {
      uri = _healthUri();
    } catch (_) {
      return _Probe.transport((AppLocalizations l) => l.checkBadAddress);
    }
    if (RemoteEngine.pointsAtThisDevice(uri)) {
      final _Probe p = _Probe.transport(RemoteEngine.thisDeviceHint(uri));
      _emit(PingLost(p.transportError!));
      return p;
    }
    _emit(const PingSent());
    final Stopwatch sw = Stopwatch()..start();
    try {
      final http.Response r = await _client.get(uri).timeout(timeout);
      final int ms = sw.elapsedMilliseconds;
      final _Probe probe = _Probe.fromResponse(r, ms);
      if (probe.ok) {
        _emit(PingReturned(ms));
      } else {
        _emit(PingLost(probe.httpError ?? ((AppLocalizations l) => l.netBadAnswer)));
      }
      return probe;
    } on TimeoutException {
      final _Probe p = _Probe.transport((AppLocalizations l) => l.netNoAnswer(timeout.inSeconds));
      _emit(PingLost(p.transportError!));
      return p;
    } on SocketException catch (e) {
      final _Probe p = _Probe.transport(_explain(e.message));
      _emit(PingLost(p.transportError!));
      return p;
    } on http.ClientException catch (e) {
      final _Probe p = _Probe.transport(_explain(e.message));
      _emit(PingLost(p.transportError!));
      return p;
    } catch (e) {
      final _Probe p = _Probe.transport(verbatim('$e'));
      _emit(PingLost(p.transportError!));
      return p;
    }
  }

  static LocalText _explain(String raw) {
    final String m = raw.toLowerCase();
    if (m.contains('host lookup') || m.contains('nodename')) {
      return (AppLocalizations l) => l.netNotFound;
    }
    if (m.contains('refused')) return (AppLocalizations l) => l.netRefused;
    if (m.contains('network is unreachable') || m.contains('no route')) {
      return (AppLocalizations l) => l.netNoInternet;
    }
    if (m.contains('handshake') || m.contains('certificate')) {
      return (AppLocalizations l) => l.netNotSecure;
    }
    return verbatim(raw);
  }

  void _apply(_Probe p, {required bool animateSteps}) {
    _lastChecked = DateTime.now();
    if (p.ok) {
      _state = LinkState.online;
      _error = null;
      _latencyMs = p.ms;
      _model = p.model;
      _device = p.device;
      _uptimeS = p.uptime;
      _push(p.ms);
    } else {
      _state = LinkState.offline;
      _error = p.transportError ?? p.httpError;
      _latencyMs = null;
      _push(null);
    }
    if (!animateSteps && !_fullRunning) {
      // A background ping rewrites the checklist in one go to match.
      bool local = false;
      try {
        local = RemoteEngine.pointsAtThisDevice(_healthUri());
      } catch (_) {}
      if (local) {
        _setStep('address', StepStatus.failed, p.transportError);
        _skipFrom('reach');
      } else {
        _setStep('address', StepStatus.passed, null);
      }
      if (local) {
        // Nothing more to say until the address is fixed.
      } else if (p.transportError != null) {
        _setStep('reach', StepStatus.failed, p.transportError);
        _skipFrom('server');
      } else if (p.httpError != null) {
        _setStep('reach', StepStatus.passed, (AppLocalizations l) => l.checkAnsweredIn(p.ms));
        _setStep('server', StepStatus.failed, p.httpError);
        _skipFrom('model');
      } else {
        _setStep('reach', StepStatus.passed, (AppLocalizations l) => l.checkAnsweredIn(p.ms));
        _setStep('server', StepStatus.passed, (AppLocalizations l) => l.checkRunningFor(l.uptime(p.uptime)));
        _setStep('model', p.model == null ? StepStatus.failed : StepStatus.passed,
            p.model == null ? ((AppLocalizations l) => l.checkNotReady) : ((AppLocalizations l) => l.checkReady));
        _setStep('ping', StepStatus.passed, (AppLocalizations l) => l.checkPing(p.ms, l.pingWord(p.ms)));
      }
    }
    _notify();
  }

  void _setStep(String id, StepStatus status, LocalText? detail) {
    steps.firstWhere((CheckStep s) => s.id == id)
      ..status = status
      ..detail = detail;
  }

  void _skipFrom(String id) {
    bool on = false;
    for (final CheckStep s in steps) {
      if (s.id == id) on = true;
      if (on) {
        s
          ..status = StepStatus.skipped
          ..detail = null;
      }
    }
  }

  void _push(int? ms) {
    _history.add(ms);
    while (_history.length > historyLength) {
      _history.removeAt(0);
    }
  }

  void _emit(PingEvent e) {
    if (!_pings.isClosed) _pings.add(e);
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _settings.removeListener(_onSettings);
    WidgetsBinding.instance.removeObserver(this);
    _pings.close();
    _client.close();
    super.dispose();
  }
}

/// The outcome of one health request.
class _Probe {
  const _Probe({
    required this.ms,
    this.transportError,
    this.httpError,
    this.model,
    this.device,
    this.uptime,
  });

  const _Probe.transport(LocalText this.transportError)
      : ms = 0,
        httpError = null,
        model = null,
        device = null,
        uptime = null;

  factory _Probe.fromResponse(http.Response r, int ms) {
    Map<String, dynamic>? json;
    try {
      final Object? decoded = jsonDecode(r.body);
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {}

    if (r.statusCode == 502) {
      return _Probe(ms: ms, httpError: (AppLocalizations l) => l.netNotRunning);
    }
    if (r.statusCode == 530 || r.statusCode == 1033) {
      return _Probe(ms: ms, httpError: (AppLocalizations l) => l.netExpired);
    }
    if (r.statusCode != 200) {
      return _Probe(ms: ms, httpError: (AppLocalizations l) => l.netHttpError(r.statusCode));
    }
    if (json == null || json['service'] != 'ossia-analysis') {
      return _Probe(ms: ms, httpError: (AppLocalizations l) => l.netNotOssia);
    }
    return _Probe(
      ms: ms,
      model: json['model'] as String?,
      device: json['device'] as String?,
      uptime: (json['uptime_s'] as num?)?.toInt(),
    );
  }

  final int ms;
  final LocalText? transportError;
  final LocalText? httpError;
  final String? model;
  final String? device;
  final int? uptime;

  bool get ok => transportError == null && httpError == null;

  _Probe copyWithMs(int value) => _Probe(
        ms: value,
        transportError: transportError,
        httpError: httpError,
        model: model,
        device: device,
        uptime: uptime,
      );
}
