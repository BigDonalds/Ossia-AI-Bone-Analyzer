import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:ossia/data/on_device/image_prep.dart';

/// Photos must reach the on-device model exactly as the training images were
/// made. Each case is a small image and the 64 px letterbox that
/// `data/images.py` (OpenCV) made of it, written by `scripts/export_mobile.py`.
void main() {
  const String dir = 'test/fixtures/prep';

  Uint8List expectedPixels(String stem) {
    final img.Image e =
        img.decodePng(File('$dir/$stem.expected.png').readAsBytesSync())!;
    expect((e.width, e.height), (64, 64));
    return Uint8List.fromList(e.getBytes(order: img.ChannelOrder.rgb));
  }

  Uint8List ours(String file) {
    final RgbImage? image = decodeUpright(File('$dir/$file').readAsBytesSync());
    expect(image, isNotNull, reason: file);
    return letterbox(image!, 64);
  }

  (int, double, double) compare(Uint8List a, Uint8List b) {
    int worst = 0;
    int same = 0;
    int total = 0;
    for (int i = 0; i < a.length; i++) {
      final int d = (a[i] - b[i]).abs();
      if (d > worst) worst = d;
      if (d == 0) same++;
      total += d;
    }
    return (worst, same / a.length, total / a.length);
  }

  for (final String file in <String>[
    'shrink_fraction.png',
    'shrink_whole.png',
    'enlarge.png',
    'grey.png',
    'rgba.png',
  ]) {
    test('$file letterboxes like OpenCV', () {
      final String stem = file.split('.').first;
      final (int worst, double same, double _) = compare(ours(file), expectedPixels(stem));
      // Shrinking matches OpenCV exactly. Enlarging (photos under the model's
      // size) runs in OpenCV's fixed point, so a few values land one step off.
      expect(worst, lessThanOrEqualTo(1), reason: 'largest difference');
      expect(same, greaterThan(0.95), reason: 'share of identical values');
    });
  }

  test('a sideways JPEG is turned upright first', () {
    final Uint8List got = ours('rotated.jpg');
    final (int _, double _, double mean) = compare(got, expectedPixels('rotated'));
    // JPEG decoders differ by a level or two; an unrotated picture would be
    // off by tens.
    expect(mean, lessThan(3));

    final RgbImage? raw =
        decodeUpright(File('$dir/rotated.jpg').readAsBytesSync());
    expect((raw!.width, raw.height), (80, 120));
  });

  test('the tensor is the letterbox, channels last, 0-255', () {
    final Uint8List box = ours('shrink_fraction.png');
    final Float32List tensor = toTensor(box);
    expect(tensor.length, 64 * 64 * 3);
    expect(tensor[1000], box[1000].toDouble());
    // Letterbox bars are black: the picture is wider than tall.
    expect(tensor.sublist(0, 64 * 3).every((double v) => v == 0), isTrue);
  });
}
