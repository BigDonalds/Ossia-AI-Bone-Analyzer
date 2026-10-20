import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../data/on_device/frame_prep.dart';
import '../../data/on_device/on_device_model.dart';

/// Watches the camera preview for the auto snap. About ten times a second it
/// reports how much the picture moved; whenever the model is free it reports
/// how sure the model is that a bone is in view.
class BoneSpotter {
  BoneSpotter(this._model, {required this.onMotion, required this.onBone});

  final OnDeviceModel _model;

  /// Picture change since the last look, 0-255 (see [frameChange]).
  final ValueChanged<double> onMotion;

  /// The model's bone-in-view probability for a recent frame.
  final ValueChanged<double> onBone;

  /// Time between motion looks.
  static const int _lookMs = 90;

  /// Rest between model runs, so the phone isn't flat out the whole time.
  static const int _restMs = 250;

  final Stopwatch _clock = Stopwatch()..start();
  CameraController? _camera;
  int _rotation = 0;
  Uint8List? _lastGrid;
  int _lastLook = -_lookMs;
  int _nextRun = 0;
  bool _busy = false;

  /// Moves on at every stop, so a run that finishes afterwards is dropped.
  int _session = 0;

  bool get running => _camera != null;

  Future<void> start(CameraController camera) async {
    if (_camera != null) return;
    final int session = ++_session;
    _camera = camera;
    // Android hands frames over as the sensor sees them; iOS turns them to
    // match the locked portrait capture.
    _rotation = Platform.isAndroid ? camera.description.sensorOrientation : 0;
    _lastGrid = null;
    try {
      await camera.startImageStream(_onFrame);
    } catch (_) {
      if (session == _session) _camera = null;
    }
  }

  Future<void> stop() async {
    final CameraController? camera = _camera;
    forget();
    if (camera == null) return;
    try {
      if (camera.value.isInitialized && camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
    } catch (_) {}
  }

  /// Drops everything without touching the camera, for when it is being
  /// thrown away anyway.
  void forget() {
    _camera = null;
    _session++;
    _lastGrid = null;
  }

  void _onFrame(CameraImage image) {
    if (_camera == null) return;
    final int now = _clock.elapsedMilliseconds;
    if (now - _lastLook < _lookMs) return;
    final CameraFrame? frame = _frameOf(image, _rotation);
    if (frame == null) return;
    _lastLook = now;

    final Uint8List grid = lumaGrid(frame);
    final Uint8List? last = _lastGrid;
    _lastGrid = grid;
    if (last != null) onMotion(frameChange(last, grid));

    if (!_busy && now >= _nextRun && _model.status == OnDeviceStatus.ready) {
      _busy = true;
      unawaited(_check(frame, _session));
    }
  }

  Future<void> _check(CameraFrame frame, int session) async {
    try {
      final Float32List input =
          await compute(prepareFrameForModel, (frame, _model.spec!.imgSize));
      if (session != _session) return;
      final Map<String, List<double>> p = await _model.run(input);
      if (session != _session) return;
      final List<double>? bone = p['bone_detection'];
      if (bone != null && bone.isNotEmpty) onBone(bone.first);
    } catch (_) {
      // A frame that couldn't be read; the next one will do.
    } finally {
      _busy = false;
      _nextRun = _clock.elapsedMilliseconds + _restMs;
    }
  }
}

/// Wraps the camera's planes without copying them.
CameraFrame? _frameOf(CameraImage image, int rotation) {
  final List<Plane> planes = image.planes;
  if (planes.isEmpty) return null;
  final Plane p0 = planes.first;
  switch (image.format.group) {
    case ImageFormatGroup.bgra8888:
      return CameraFrame.bgra(
        width: image.width,
        height: image.height,
        bgra: p0.bytes,
        rowStride: p0.bytesPerRow,
        rotation: rotation,
      );
    case ImageFormatGroup.yuv420 when planes.length >= 3:
      return CameraFrame.yuv(
        width: image.width,
        height: image.height,
        y: p0.bytes,
        rowStride: p0.bytesPerRow,
        u: planes[1].bytes,
        v: planes[2].bytes,
        uvRowStride: planes[1].bytesPerRow,
        uvPixelStride: planes[1].bytesPerPixel ?? 1,
        rotation: rotation,
      );
    case ImageFormatGroup.yuv420 when planes.length == 2:
      // iOS: luma, then Cb and Cr interleaved, in video range.
      return CameraFrame.yuv(
        width: image.width,
        height: image.height,
        y: p0.bytes,
        rowStride: p0.bytesPerRow,
        u: planes[1].bytes,
        v: planes[1].bytes,
        vStart: 1,
        uvRowStride: planes[1].bytesPerRow,
        uvPixelStride: 2,
        videoRange: true,
        rotation: rotation,
      );
    case ImageFormatGroup.nv21:
      // One plane: luma, then Cr and Cb interleaved.
      final int lumaBytes = p0.bytesPerRow * image.height;
      return CameraFrame.yuv(
        width: image.width,
        height: image.height,
        y: p0.bytes,
        rowStride: p0.bytesPerRow,
        u: p0.bytes,
        v: p0.bytes,
        uStart: lumaBytes + 1,
        vStart: lumaBytes,
        uvRowStride: p0.bytesPerRow,
        uvPixelStride: 2,
        rotation: rotation,
      );
    default:
      return null;
  }
}
