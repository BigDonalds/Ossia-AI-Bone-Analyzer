import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ossia/data/server_monitor.dart';
import 'package:ossia/data/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A server that takes [delay] to answer each health check and counts the
/// requests that were cut off before it did.
class _SlowServer {
  _SlowServer(this.delay);

  final Duration delay;
  int started = 0;
  int aborted = 0;

  late final http.Client client =
      MockClient.streaming((http.BaseRequest request, http.ByteStream _) {
    started++;
    final Completer<http.StreamedResponse> reply = Completer<http.StreamedResponse>();
    final Timer answer = Timer(delay, () {
      if (reply.isCompleted) return;
      final List<int> body = utf8.encode(jsonEncode(<String, dynamic>{
        'service': 'ossia-analysis',
        'model': 'test',
        'device': 'cpu',
        'uptime_s': 60,
      }));
      reply.complete(http.StreamedResponse(Stream<List<int>>.value(body), 200));
    });
    if (request case http.Abortable(:final Future<void> abortTrigger?)) {
      unawaited(abortTrigger.whenComplete(() {
        if (reply.isCompleted) return;
        answer.cancel();
        aborted++;
        reply.completeError(http.RequestAbortedException(request.url));
      }));
    }
    return reply.future;
  });
}

Future<SettingsController> _settings() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return SettingsController(await SharedPreferences.getInstance());
}

bool _allSkipped(ServerMonitor m) =>
    m.steps.every((CheckStep s) => s.status == StepStatus.skipped);

void main() {
  // Each test pumps until nothing is left in flight, then disposes the
  // monitor, so no timers outlive it.

  testWidgets('choosing This phone mid-check stops it at once', (WidgetTester tester) async {
    final _SlowServer server = _SlowServer(const Duration(seconds: 3));
    final SettingsController s = await _settings();
    final ServerMonitor m = ServerMonitor(s, client: server.client);
    expect(m.state, LinkState.onDevice);

    // What the status page does when Online is tapped.
    s.setEngine(EngineMode.server);
    unawaited(m.fullCheck());
    await tester.pump(const Duration(milliseconds: 400));
    expect(m.state, LinkState.checking);
    expect(server.started, 1);

    s.setEngine(EngineMode.onDevice);
    expect(m.state, LinkState.onDevice);
    expect(m.fullCheckRunning, isFalse);
    expect(_allSkipped(m), isTrue);
    await tester.pump();
    expect(server.aborted, 1);

    // Nothing from the old check lands afterwards.
    await tester.pump(const Duration(seconds: 20));
    expect(m.state, LinkState.onDevice);
    expect(m.fullCheckRunning, isFalse);
    expect(_allSkipped(m), isTrue);
    expect(server.started, 1);
    m.dispose();
  });

  testWidgets('a switch in the middle of the step-by-step check stops it too',
      (WidgetTester tester) async {
    final _SlowServer server = _SlowServer(const Duration(seconds: 1));
    final SettingsController s = await _settings();
    final ServerMonitor m = ServerMonitor(s, client: server.client);

    s.setEngine(EngineMode.server);
    unawaited(m.fullCheck());
    // Past the background ping and the address step, into "reach".
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 900));
    expect(m.fullCheckRunning, isTrue);
    expect(m.steps.first.status, StepStatus.passed);

    s.setEngine(EngineMode.onDevice);
    expect(m.state, LinkState.onDevice);
    expect(_allSkipped(m), isTrue);
    final int sent = server.started;

    await tester.pump(const Duration(seconds: 20));
    expect(m.state, LinkState.onDevice);
    expect(_allSkipped(m), isTrue);
    expect(server.started, sent);
    m.dispose();
  });

  testWidgets('going back to Online straight away runs a fresh check', (WidgetTester tester) async {
    final _SlowServer server = _SlowServer(const Duration(seconds: 1));
    final SettingsController s = await _settings();
    final ServerMonitor m = ServerMonitor(s, client: server.client);

    s.setEngine(EngineMode.server);
    unawaited(m.fullCheck());
    await tester.pump(const Duration(milliseconds: 300));
    s.setEngine(EngineMode.onDevice);
    s.setEngine(EngineMode.server);
    unawaited(m.fullCheck());

    for (int i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
    expect(m.state, LinkState.online);
    expect(m.fullCheckRunning, isFalse);
    expect(m.steps.every((CheckStep c) => c.status == StepStatus.passed), isTrue);
    m.dispose();
    await tester.pump(const Duration(seconds: 2));
  });
}
