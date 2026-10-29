import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../l10n/l10n.dart';
import '../l10n/labels.dart';
import 'models/analysis.dart';
import 'on_device/on_device_model.dart';
import 'on_device/report_builder.dart';

/// Photos of one bone analysed together; the server takes at most this many.
const int kMaxPhotos = 8;

sealed class AnalysisEvent {
  const AnalysisEvent();
}

class PhaseStarted extends AnalysisEvent {
  const PhaseStarted(this.index);

  /// Which of the [kPhaseCount] stages, from 0.
  final int index;
}

class AnalysisSucceeded extends AnalysisEvent {
  const AnalysisSucceeded(this.result);
  final AnalysisResult result;
}

class AnalysisFailed extends AnalysisEvent {
  const AnalysisFailed(this.message, {this.serverUnreachable = false});
  final LocalText message;

  /// The server couldn't be reached at all, so the phone's own model is worth
  /// offering instead.
  final bool serverUnreachable;
}

abstract interface class AnalysisEngine {
  /// [images] are photos of the same bone, read together into one report.
  /// [lengthCm] is the user's own end-to-end measurement, when they gave one.
  Stream<AnalysisEvent> analyze(List<File> images, {double? lengthCm});
}

/// Runs the model bundled with the app on this phone and builds the same
/// report the server would (lib/data/on_device/).
class LocalEngine implements AnalysisEngine {
  const LocalEngine(this.model);

  final OnDeviceModel model;

  @override
  Stream<AnalysisEvent> analyze(List<File> images, {double? lengthCm}) async* {
    final Stopwatch sw = Stopwatch()..start();
    yield const PhaseStarted(0);
    try {
      await model.ensureLoaded();
    } catch (_) {
      yield AnalysisFailed((AppLocalizations l) => l.errNotReadyOnPhone);
      return;
    }
    // Rounded like a length sent to the server, so both explain it the same way.
    final double? length =
        lengthCm == null ? null : double.parse(lengthCm.toStringAsFixed(1));

    // One pass of the network answers every stage, so the stages are walked
    // as the photos finish.
    int phase = 0;
    final List<HeadProbabilities> photos = <HeadProbabilities>[];
    for (int i = 0; i < images.length; i++) {
      final Float32List input;
      try {
        input = await model.prepare(images[i]);
      } catch (_) {
        final int number = i + 1;
        yield AnalysisFailed(images.length == 1
            ? ((AppLocalizations l) => l.errPhotoUnreadable)
            : ((AppLocalizations l) => l.errPhotoNUnreadable(number)));
        return;
      }
      try {
        photos.add(await model.run(input));
      } catch (_) {
        yield AnalysisFailed((AppLocalizations l) => l.errReadingPhoto);
        return;
      }
      final int reached = (i + 1) * 5 ~/ images.length;
      while (phase < reached) {
        yield PhaseStarted(++phase);
        await Future<void>.delayed(const Duration(milliseconds: 90));
      }
    }

    final Map<String, dynamic> report = model.builder.report(
      photos,
      <String>[for (final File f in images) f.uri.pathSegments.last],
      length,
    );
    report['engine'] = <String, dynamic>{
      'kind': 'on_device',
      'model': model.spec!.checkpoint,
      'elapsed_ms': sw.elapsedMilliseconds,
    };
    while (phase < kPhaseCount - 1) {
      yield PhaseStarted(++phase);
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }
    yield AnalysisSucceeded(AnalysisResult.fromJson(report));
  }
}

/// Uploads the photos to the Python service and reads back the phase
/// dictionary. Expects `POST {baseUrl}/analyze` with one multipart `image`
/// field per photo, plus an optional `length_cm` field when the user measured
/// the bone.
class RemoteEngine implements AnalysisEngine {
  const RemoteEngine(this.baseUrl);

  final String baseUrl;

  /// True when [uri] names the device the app is running on. On a phone,
  /// `localhost` / `127.0.0.1` is the phone itself, never the computer running
  /// the server — a common mix-up worth catching before any request is sent.
  static bool pointsAtThisDevice(Uri uri) {
    const bool web = bool.fromEnvironment('dart.library.js_interop');
    if (web || !(Platform.isAndroid || Platform.isIOS)) return false;
    final String h = uri.host.toLowerCase();
    return h == 'localhost' || h.startsWith('127.') || h == '::1' || h == '0.0.0.0';
  }

  static LocalText thisDeviceHint(Uri uri) => (AppLocalizations l) => l.errThisDevice;

  /// Turns whatever the user typed into the `/analyze` endpoint: trims spaces
  /// and trailing slashes, drops a pasted `/analyze`, and adds a scheme when
  /// missing — plain http for a LAN IP or localhost, https for a hostname.
  static Uri endpointFor(String raw) {
    String base = raw.trim();
    while (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    if (base.toLowerCase().endsWith('/analyze')) {
      base = base.substring(0, base.length - '/analyze'.length);
    }
    if (!base.contains('://')) {
      final String host = base.split('/').first.split(':').first;
      final bool local = host == 'localhost' ||
          RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(host);
      base = '${local ? 'http' : 'https'}://$base';
    }
    return Uri.parse('$base/analyze');
  }

  @override
  Stream<AnalysisEvent> analyze(List<File> images, {double? lengthCm}) async* {
    const bool web = bool.fromEnvironment('dart.library.js_interop');
    final Uri uri;
    final http.MultipartRequest request;
    try {
      uri = endpointFor(baseUrl);
      request = http.MultipartRequest('POST', uri);
      for (final File image in images) {
        if (web) {
          // A photo picked in the browser has a blob URL for a path and no file
          // behind it, so its bytes are fetched instead.
          final http.Response photo = await http.get(Uri.parse(image.path));
          request.files.add(http.MultipartFile.fromBytes('image', photo.bodyBytes, filename: 'photo.jpg'));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image', image.path));
        }
      }
    } on FormatException {
      yield AnalysisFailed((AppLocalizations l) => l.errBadOnlineAddress);
      return;
    } catch (_) {
      yield AnalysisFailed((AppLocalizations l) => l.errPhotoTryAnother);
      return;
    }
    if (pointsAtThisDevice(uri)) {
      yield AnalysisFailed(thisDeviceHint(uri), serverUnreachable: true);
      return;
    }
    if (lengthCm != null) {
      request.fields['length_cm'] = lengthCm.toStringAsFixed(1);
    }

    // Advance the phase display while the request is in flight — the server
    // reports only the finished dictionary, not per-phase progress.
    final Future<http.StreamedResponse> pending = request
        .send()
        .timeout(Duration(seconds: 45 + 15 * images.length));

    // Both branches are handled here so this derived future never surfaces as
    // an unhandled error; the real result (or failure) is awaited below.
    bool done = false;
    unawaited(pending.then<void>(
      (_) => done = true,
      onError: (Object _) => done = true,
    ));

    for (int i = 0; i < kPhaseCount; i++) {
      yield PhaseStarted(i);
      if (done && i > 2) break;
      await Future<void>.delayed(const Duration(milliseconds: 260));
    }

    try {
      final http.StreamedResponse response = await pending;
      final String body = await response.stream.bytesToString();
      if (response.statusCode != 200) {
        // The Ossia server explains itself in a JSON `message`, in English, so
        // English shows it as sent and the other languages say what the status
        // code means.
        final int code = response.statusCode;
        String? said;
        try {
          final Object? decoded = jsonDecode(body);
          if (decoded is Map<String, dynamic> && decoded['message'] is String) {
            said = decoded['message'] as String;
          }
        } catch (_) {}
        yield AnalysisFailed((AppLocalizations l) {
          if (said != null && l.localeName == 'en') return said;
          return switch (code) {
            413 => l.errServerTooBig,
            400 => l.errServerRejected,
            422 => l.errServerCouldntAnalyze,
            _ => l.errServerStatus(code),
          };
        });
        return;
      }
      final Map<String, dynamic> report = jsonDecode(body) as Map<String, dynamic>;
      final Map<String, dynamic> server =
          (report['server'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      report['engine'] = <String, dynamic>{
        'kind': 'server',
        'model': server['model'],
        'elapsed_ms': server['elapsed_ms'],
      };
      yield AnalysisSucceeded(AnalysisResult.fromJson(report));
    } on TimeoutException {
      yield AnalysisFailed((AppLocalizations l) => l.errTimeout, serverUnreachable: true);
    } on SocketException catch (e) {
      yield AnalysisFailed(_unreachable(uri, e.message), serverUnreachable: true);
    } on http.ClientException catch (e) {
      // package:http wraps socket and TLS failures in a ClientException.
      yield AnalysisFailed(_unreachable(uri, e.message), serverUnreachable: true);
    } on FormatException {
      yield AnalysisFailed((AppLocalizations l) => l.errNotAReport);
    } catch (_) {
      yield AnalysisFailed((AppLocalizations l) => l.errGeneric);
    }
  }

  static LocalText _unreachable(Uri uri, String detail) => (AppLocalizations l) => l.errUnreachable;
}
