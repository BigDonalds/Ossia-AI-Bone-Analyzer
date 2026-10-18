import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

import 'image_prep.dart';
import 'model_spec.dart';
import 'report_builder.dart';

enum OnDeviceStatus { idle, loading, ready, failed }

/// The bone model bundled with the app (assets/model/, written by
/// `scripts/export_mobile.py`), loaded once and kept for every later scan.
class OnDeviceModel extends ChangeNotifier {
  static const String _assets = 'assets/model';

  OnDeviceStatus _status = OnDeviceStatus.idle;
  String? _error;
  ModelSpec? _spec;
  ReportBuilder? _builder;
  Duration? _loadTime;
  OrtSession? _session;
  Future<void>? _loading;

  OnDeviceStatus get status => _status;
  String? get error => _error;

  /// What was exported, readable before the network itself is loaded.
  ModelSpec? get spec => _spec;
  ReportBuilder get builder => _builder!;
  Duration? get loadTime => _loadTime;

  /// On the web there is no file system to hand the model to the runtime.
  static bool get supported => !kIsWeb;

  /// Loads the model if it isn't already; safe to call repeatedly. After a
  /// failure the next call tries again.
  Future<void> ensureLoaded() {
    if (_status == OnDeviceStatus.ready) return Future<void>.value();
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  /// Reads the small description files only, for the status page.
  Future<ModelSpec> describe() async => _spec ??= ModelSpec.fromJson(
      jsonDecode(await rootBundle.loadString('$_assets/ossia_model.json'))
          as Map<String, dynamic>);

  Future<void> _load() async {
    if (!supported) {
      _fail('Analyzing on the device needs the phone app.');
      throw StateError(_error!);
    }
    _status = OnDeviceStatus.loading;
    _error = null;
    notifyListeners();
    final Stopwatch sw = Stopwatch()..start();
    try {
      final ModelSpec spec = await describe();
      final LengthTable lengths = LengthTable.fromJson(
          jsonDecode(await rootBundle.loadString('$_assets/length_reference.json'))
              as Map<String, dynamic>);
      final File file = await _modelFile(spec);
      _session = await OnnxRuntime().createSession(file.path);
      _builder = ReportBuilder(spec, lengths);
      _loadTime = sw.elapsed;
      _status = OnDeviceStatus.ready;
      notifyListeners();
    } catch (e) {
      _fail('$e');
      rethrow;
    }
  }

  void _fail(String message) {
    _status = OnDeviceStatus.failed;
    _error = message;
    notifyListeners();
  }

  /// The runtime needs the model as a file. It is copied out of the app once
  /// per model version; the checksum in the name means an app update with a
  /// new model never reuses the old copy.
  Future<File> _modelFile(ModelSpec spec) async {
    final Directory dir =
        Directory('${(await getApplicationSupportDirectory()).path}/model');
    await dir.create(recursive: true);
    final String name = 'ossia-${spec.modelSha256.substring(0, 16)}.onnx';
    final File file = File('${dir.path}/$name');
    if (!await file.exists() || await file.length() != spec.modelBytes) {
      final ByteData data = await rootBundle.load('$_assets/${spec.modelFile}');
      final File tmp = File('${file.path}.tmp');
      await tmp.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true);
      await tmp.rename(file.path);
    }
    await for (final FileSystemEntity old in dir.list()) {
      if (old is File && old.path != file.path) {
        try {
          await old.delete();
        } catch (_) {}
      }
    }
    return file;
  }

  /// Decodes and letterboxes a photo off the UI thread. Formats the pure-Dart
  /// decoder can't read (HEIC from an iPhone) go through the platform's own.
  Future<Float32List> prepare(File photo) async {
    final int size = _spec!.imgSize;
    final Uint8List bytes = await photo.readAsBytes();
    final Float32List? tensor = await compute(prepareForModel, (bytes, size));
    if (tensor != null) return tensor;

    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.Image image = (await codec.getNextFrame()).image;
    final ByteData? rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final int width = image.width;
    final int height = image.height;
    image.dispose();
    codec.dispose();
    if (rgba == null) throw const FormatException("Couldn't read that photo");
    return compute(prepareRgbaForModel,
        (rgba.buffer.asUint8List(), width, height, size));
  }

  /// One photo through the network: calibrated probabilities for every head.
  Future<HeadProbabilities> run(Float32List input) async {
    final ModelSpec spec = _spec!;
    final OrtValue tensor =
        await OrtValue.fromList(input, <int>[1, spec.imgSize, spec.imgSize, 3]);
    try {
      final Map<String, OrtValue> outputs =
          await _session!.run(<String, OrtValue>{spec.inputName: tensor});
      final HeadProbabilities probs = <String, List<double>>{};
      for (final MapEntry<String, OrtValue> e in outputs.entries) {
        probs[e.key] = <double>[
          for (final dynamic v in await e.value.asFlattenedList()) (v as num).toDouble(),
        ];
        await e.value.dispose();
      }
      return probs;
    } finally {
      await tensor.dispose();
    }
  }

  @override
  void dispose() {
    _session?.close();
    super.dispose();
  }
}
