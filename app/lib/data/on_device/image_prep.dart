/// Turns a photo into the model's input exactly the way the training images
/// were made (`scripts/preprocess.py`): decode, apply the EXIF orientation,
/// shrink with OpenCV's INTER_AREA rule and letterbox onto a black square.
/// A different resize softens edges differently from what the model learnt,
/// so the resampling below follows OpenCV's `resize` step for step.
///
/// Pure Dart, so it can run in a background isolate and in tests.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A decoded, upright photo as tightly packed RGB bytes.
class RgbImage {
  const RgbImage(this.width, this.height, this.pixels);

  final int width;
  final int height;

  /// width x height x 3, row by row.
  final Uint8List pixels;
}

/// Decodes JPEG, PNG, WebP, GIF, BMP or TIFF bytes and turns the picture
/// upright. Returns null for anything it can't read (HEIC, for one).
RgbImage? decodeUpright(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  // Like OpenCV's IMREAD_COLOR: 8 bits per channel, alpha dropped (not
  // blended), grey spread over three channels.
  final img.Image upright = img.bakeOrientation(decoded);
  final img.Image rgb = upright.format == img.Format.uint8 &&
          upright.numChannels == 3 &&
          !upright.hasPalette
      ? upright
      : upright.convert(format: img.Format.uint8, numChannels: 3, alpha: 255);
  return RgbImage(rgb.width, rgb.height,
      Uint8List.fromList(rgb.getBytes(order: img.ChannelOrder.rgb)));
}

/// `bone_analyzer.data.images.letterbox_resize`: fit the longer side to [size] keeping
/// the aspect ratio, centre it, pad with black. Returns size x size x 3 bytes.
Uint8List letterbox(RgbImage image, int size) {
  final int w = image.width;
  final int h = image.height;
  final double scale = size / math.max(w, h);
  final int newW = math.max(1, (w * scale).floor());
  final int newH = math.max(1, (h * scale).floor());
  final Uint8List resized = resizeArea(image, newW, newH);

  final Uint8List canvas = Uint8List(size * size * 3);
  final int x0 = (size - newW) ~/ 2;
  final int y0 = (size - newH) ~/ 2;
  for (int y = 0; y < newH; y++) {
    canvas.setRange(((y0 + y) * size + x0) * 3, ((y0 + y) * size + x0 + newW) * 3,
        resized, y * newW * 3);
  }
  return canvas;
}

/// The model's input tensor, [1, size, size, 3] RGB 0-255 (normalisation is
/// inside the exported model).
Float32List toTensor(Uint8List letterboxed) {
  final Float32List out = Float32List(letterboxed.length);
  for (int i = 0; i < letterboxed.length; i++) {
    out[i] = letterboxed[i].toDouble();
  }
  return out;
}

/// Photo bytes to model input in one go, for `compute`.
Float32List? prepareForModel((Uint8List, int) args) {
  final (Uint8List bytes, int size) = args;
  final RgbImage? image = decodeUpright(bytes);
  if (image == null) return null;
  return toTensor(letterbox(image, size));
}

/// Raw RGBA pixels (from the platform's own decoder, for formats package:image
/// can't read) to model input.
Float32List prepareRgbaForModel((Uint8List, int, int, int) args) {
  final (Uint8List rgba, int width, int height, int size) = args;
  final Uint8List rgb = Uint8List(width * height * 3);
  for (int i = 0, j = 0; i < rgb.length; i += 3, j += 4) {
    rgb[i] = rgba[j];
    rgb[i + 1] = rgba[j + 1];
    rgb[i + 2] = rgba[j + 2];
  }
  return toTensor(letterbox(RgbImage(width, height, rgb), size));
}

// ── cv::resize(..., INTER_AREA) ──────────────────────────────────────────────

/// OpenCV's INTER_AREA resize of 8-bit RGB: each output pixel is the
/// area-weighted mean of the source pixels it covers when shrinking; when
/// enlarging, OpenCV switches to its bilinear code with area-style weights,
/// which is reproduced too.
Uint8List resizeArea(RgbImage src, int dstW, int dstH) {
  if (dstW == src.width && dstH == src.height) {
    return Uint8List.fromList(src.pixels);
  }
  final double scaleX = src.width / dstW;
  final double scaleY = src.height / dstH;
  if (scaleX >= 1 && scaleY >= 1) {
    return _shrink(src, dstW, dstH, scaleX, scaleY);
  }
  return _enlarge(src, dstW, dstH, scaleX, scaleY);
}

class _Tap {
  const _Tap(this.dst, this.src, this.alpha);
  final int dst;
  final int src;
  final double alpha;
}

/// `computeResizeAreaTab`: which source pixels feed each output pixel, and
/// with what weight.
List<_Tap> _areaTable(int srcSize, int dstSize, double scale) {
  final List<_Tap> tab = <_Tap>[];
  for (int dx = 0; dx < dstSize; dx++) {
    final double fsx1 = dx * scale;
    final double fsx2 = fsx1 + scale;
    final double cellWidth = math.min(scale, srcSize - fsx1);
    int sx1 = fsx1.ceil();
    int sx2 = fsx2.floor();
    sx2 = math.min(sx2, srcSize - 1);
    sx1 = math.min(sx1, sx2);
    if (sx1 - fsx1 > 1e-3) {
      tab.add(_Tap(dx, sx1 - 1, _f32((sx1 - fsx1) / cellWidth)));
    }
    for (int sx = sx1; sx < sx2; sx++) {
      tab.add(_Tap(dx, sx, _f32(1.0 / cellWidth)));
    }
    if (fsx2 - sx2 > 1e-3) {
      tab.add(_Tap(dx, sx2,
          _f32(math.min(math.min(fsx2 - sx2, 1.0), cellWidth) / cellWidth)));
    }
  }
  return tab;
}

Uint8List _shrink(RgbImage src, int dstW, int dstH, double scaleX, double scaleY) {
  final List<_Tap> xtab = _areaTable(src.width, dstW, scaleX);
  final List<_Tap> ytab = _areaTable(src.height, dstH, scaleY);
  final Uint8List out = Uint8List(dstW * dstH * 3);
  final Float64List row = Float64List(dstW * 3);
  final Float64List sum = Float64List(dstW * 3);
  final Uint8List px = src.pixels;
  final int srcStride = src.width * 3;

  int k = 0;
  while (k < ytab.length) {
    final int dy = ytab[k].dst;
    sum.fillRange(0, sum.length, 0);
    // Every source row feeding output row dy.
    for (; k < ytab.length && ytab[k].dst == dy; k++) {
      final int base = ytab[k].src * srcStride;
      final double beta = ytab[k].alpha;
      row.fillRange(0, row.length, 0);
      for (final _Tap t in xtab) {
        final int s = base + t.src * 3;
        final int d = t.dst * 3;
        row[d] += px[s] * t.alpha;
        row[d + 1] += px[s + 1] * t.alpha;
        row[d + 2] += px[s + 2] * t.alpha;
      }
      for (int i = 0; i < row.length; i++) {
        sum[i] += row[i] * beta;
      }
    }
    final int o = dy * dstW * 3;
    for (int i = 0; i < sum.length; i++) {
      out[o + i] = _saturate(sum[i]);
    }
  }
  return out;
}

/// OpenCV's enlarging branch of INTER_AREA: bilinear, but each output pixel
/// takes the nearest source pixel unless it straddles a source boundary.
Uint8List _enlarge(RgbImage src, int dstW, int dstH, double scaleX, double scaleY) {
  (Int32List, Float64List) axis(int srcSize, int dstSize, double scale) {
    final Int32List index = Int32List(dstSize);
    final Float64List frac = Float64List(dstSize);
    final double inv = dstSize / srcSize;
    for (int d = 0; d < dstSize; d++) {
      int s = (d * scale).floor();
      double f = _f32((d + 1) - (s + 1) * inv);
      f = f <= 0 ? 0 : f - f.floor();
      if (s < 0) {
        f = 0;
        s = 0;
      }
      if (s >= srcSize - 1) {
        f = 0;
        s = srcSize - 1;
      }
      index[d] = s;
      frac[d] = f;
    }
    return (index, frac);
  }

  final (Int32List xs, Float64List fx) = axis(src.width, dstW, scaleX);
  final (Int32List ys, Float64List fy) = axis(src.height, dstH, scaleY);
  final Uint8List px = src.pixels;
  final Uint8List out = Uint8List(dstW * dstH * 3);
  final int stride = src.width * 3;
  for (int y = 0; y < dstH; y++) {
    final int r0 = ys[y] * stride;
    final int r1 = math.min(ys[y] + 1, src.height - 1) * stride;
    final double b = fy[y];
    for (int x = 0; x < dstW; x++) {
      final int c0 = xs[x] * 3;
      final int c1 = math.min(xs[x] + 1, src.width - 1) * 3;
      final double a = fx[x];
      for (int ch = 0; ch < 3; ch++) {
        final double top = px[r0 + c0 + ch] * (1 - a) + px[r0 + c1 + ch] * a;
        final double bottom = px[r1 + c0 + ch] * (1 - a) + px[r1 + c1 + ch] * a;
        out[(y * dstW + x) * 3 + ch] = _saturate(top * (1 - b) + bottom * b);
      }
    }
  }
  return out;
}

/// OpenCV keeps the weights as 32-bit floats.
double _f32(double v) => (Float32List(1)..[0] = v)[0];

/// `saturate_cast<uchar>`: round half to even, clamp to 0..255.
int _saturate(double v) {
  final double r = v.roundToDouble();
  final int n = (r - v).abs() == 0.5 && r.toInt().isOdd ? r.toInt() - (r > v ? 1 : -1) : r.toInt();
  return n < 0 ? 0 : (n > 255 ? 255 : n);
}
