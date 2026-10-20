/// Live camera frames for the auto snap: the raw planes the camera streams,
/// turned into the model's input, plus a tiny grey thumbnail for telling a
/// still picture from a moving one.
///
/// Pure Dart, so it can run in a background isolate and in tests.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'image_prep.dart';

/// One preview frame as the camera hands it over, in the sensor's own
/// orientation. Either YUV 4:2:0 (Android, and iOS's two-plane format) or
/// 32-bit BGRA (iOS).
class CameraFrame {
  const CameraFrame.yuv({
    required this.width,
    required this.height,
    required Uint8List this.y,
    required this.rowStride,
    required Uint8List this.u,
    required Uint8List this.v,
    this.uStart = 0,
    this.vStart = 0,
    required this.uvRowStride,
    required this.uvPixelStride,
    this.videoRange = false,
    this.rotation = 0,
  }) : bgra = null;

  const CameraFrame.bgra({
    required this.width,
    required this.height,
    required Uint8List this.bgra,
    required this.rowStride,
    this.rotation = 0,
  })  : y = null,
        u = null,
        v = null,
        uStart = 0,
        vStart = 0,
        uvRowStride = 0,
        uvPixelStride = 0,
        videoRange = false;

  final int width;
  final int height;

  /// Clockwise turn, in degrees, that makes the frame upright.
  final int rotation;

  /// Bytes per row of [y], or of [bgra].
  final int rowStride;

  final Uint8List? y;

  /// Chroma samples, one per 2x2 block of pixels. U and V may sit in the same
  /// buffer, interleaved: then [uStart] and [vStart] differ and
  /// [uvPixelStride] is 2.
  final Uint8List? u;
  final Uint8List? v;
  final int uStart;
  final int vStart;
  final int uvRowStride;
  final int uvPixelStride;

  /// Luma in 16-235 rather than 0-255 (iOS's video-range format).
  final bool videoRange;

  final Uint8List? bgra;
}

/// A small grey thumbnail of [f], [cols] x [rows], each cell the mean of a
/// 4x4 spread of samples across it. Left in the sensor's orientation: it is
/// only compared with the previous frame's.
Uint8List lumaGrid(CameraFrame f, {int cols = 32, int rows = 24}) {
  final Uint8List out = Uint8List(cols * rows);
  final double cellW = f.width / cols;
  final double cellH = f.height / rows;
  final Uint8List? y = f.y;
  final Uint8List? bgra = f.bgra;
  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      int sum = 0;
      for (int sy = 0; sy < 4; sy++) {
        final int py = ((r + (sy + 0.5) / 4) * cellH).floor().clamp(0, f.height - 1);
        for (int sx = 0; sx < 4; sx++) {
          final int px = ((c + (sx + 0.5) / 4) * cellW).floor().clamp(0, f.width - 1);
          if (y != null) {
            final int i = py * f.rowStride + px;
            sum += i < y.length ? y[i] : 0;
          } else if (bgra != null) {
            final int i = py * f.rowStride + px * 4;
            if (i + 2 < bgra.length) {
              sum += (bgra[i] * 29 + bgra[i + 1] * 150 + bgra[i + 2] * 77) >> 8;
            }
          }
        }
      }
      out[r * cols + c] = sum >> 4;
    }
  }
  return out;
}

/// How much the picture changed between two [lumaGrid] thumbnails, 0-255:
/// the mean difference per cell once an overall brightening or darkening
/// (the camera adjusting its exposure) is taken out.
double frameChange(Uint8List a, Uint8List b) {
  final int n = math.min(a.length, b.length);
  if (n == 0) return 0;
  int sum = 0;
  for (int i = 0; i < n; i++) {
    sum += b[i] - a[i];
  }
  final double shift = sum / n;
  double total = 0;
  for (int i = 0; i < n; i++) {
    total += (b[i] - a[i] - shift).abs();
  }
  return total / n;
}

/// [f] as upright RGB, shrunk by a whole factor so its longer side stays at
/// least [minSide]. Each output pixel's luma is the mean of the block it
/// covers, which is what INTER_AREA gives for a whole factor; chroma is taken
/// from the block's centre.
RgbImage frameToRgb(CameraFrame f, int minSide) {
  final int k = math.max(1, math.max(f.width, f.height) ~/ minSide);
  final int w = math.max(1, f.width ~/ k);
  final int h = math.max(1, f.height ~/ k);
  final Uint8List rgb = Uint8List(w * h * 3);
  final int area = k * k;

  final Uint8List? y = f.y;
  if (y != null) {
    final Uint8List u = f.u!;
    final Uint8List v = f.v!;
    for (int oy = 0; oy < h; oy++) {
      final int y0 = oy * k;
      final int cy = (y0 + k ~/ 2) >> 1;
      for (int ox = 0; ox < w; ox++) {
        final int x0 = ox * k;
        int sum = 0;
        for (int dy = 0; dy < k; dy++) {
          final int row = (y0 + dy) * f.rowStride + x0;
          for (int dx = 0; dx < k; dx++) {
            final int i = row + dx;
            sum += i < y.length ? y[i] : 0;
          }
        }
        final int cx = (x0 + k ~/ 2) >> 1;
        final int ci = cy * f.uvRowStride + cx * f.uvPixelStride;
        final int ui = f.uStart + ci;
        final int vi = f.vStart + ci;
        final int cb = (ui < u.length ? u[ui] : 128) - 128;
        final int cr = (vi < v.length ? v[vi] : 128) - 128;
        final int l = sum ~/ area;
        final int o = (oy * w + ox) * 3;
        if (f.videoRange) {
          // BT.601 video range: luma 16-235, chroma 16-240.
          final int yy = (l - 16) * 298;
          rgb[o] = ((yy + 409 * cr + 128) >> 8).clamp(0, 255);
          rgb[o + 1] = ((yy - 100 * cb - 208 * cr + 128) >> 8).clamp(0, 255);
          rgb[o + 2] = ((yy + 516 * cb + 128) >> 8).clamp(0, 255);
        } else {
          // BT.601 full range, as Android cameras give it.
          rgb[o] = (l + ((359 * cr) >> 8)).clamp(0, 255);
          rgb[o + 1] = (l - ((88 * cb + 183 * cr) >> 8)).clamp(0, 255);
          rgb[o + 2] = (l + ((454 * cb) >> 8)).clamp(0, 255);
        }
      }
    }
  } else {
    final Uint8List bgra = f.bgra!;
    for (int oy = 0; oy < h; oy++) {
      for (int ox = 0; ox < w; ox++) {
        int b = 0, g = 0, r = 0;
        for (int dy = 0; dy < k; dy++) {
          int i = (oy * k + dy) * f.rowStride + ox * k * 4;
          for (int dx = 0; dx < k; dx++, i += 4) {
            if (i + 2 >= bgra.length) break;
            b += bgra[i];
            g += bgra[i + 1];
            r += bgra[i + 2];
          }
        }
        final int o = (oy * w + ox) * 3;
        rgb[o] = r ~/ area;
        rgb[o + 1] = g ~/ area;
        rgb[o + 2] = b ~/ area;
      }
    }
  }
  return rotateRgb(RgbImage(w, h, rgb), f.rotation);
}

/// [src] turned clockwise by [degrees], a multiple of 90.
RgbImage rotateRgb(RgbImage src, int degrees) {
  final int turns = (degrees ~/ 90) % 4;
  if (turns == 0) return src;
  final int w = src.width;
  final int h = src.height;
  final int ow = turns.isOdd ? h : w;
  final int oh = turns.isOdd ? w : h;
  final Uint8List from = src.pixels;
  final Uint8List out = Uint8List(from.length);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final (int nx, int ny) = switch (turns) {
        1 => (h - 1 - y, x),
        2 => (w - 1 - x, h - 1 - y),
        _ => (y, w - 1 - x),
      };
      final int i = (y * w + x) * 3;
      final int o = (ny * ow + nx) * 3;
      out[o] = from[i];
      out[o + 1] = from[i + 1];
      out[o + 2] = from[i + 2];
    }
  }
  return RgbImage(ow, oh, out);
}

/// A frame to model input in one go, for `compute`.
Float32List prepareFrameForModel((CameraFrame, int) args) {
  final (CameraFrame frame, int size) = args;
  return toTensor(letterbox(frameToRgb(frame, size), size));
}
