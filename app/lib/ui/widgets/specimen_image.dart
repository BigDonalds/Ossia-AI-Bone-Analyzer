import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';

/// Renders a stored specimen photograph, falling back to a neutral placeholder
/// whenever the file cannot be shown — deleted from under us or unreadable.
/// On the web preview target a path is a browser URL rather than a file.
class SpecimenImage extends StatelessWidget {
  const SpecimenImage({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.iconSize,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? iconSize;

  /// The image behind [path], or null when there is nothing to show.
  static ImageProvider? providerFor(String path) {
    if (kIsWeb) return path.isEmpty ? null : NetworkImage(path);
    try {
      return File(path).existsSync() ? FileImage(File(path)) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider? image = providerFor(path);
    if (image == null) return _placeholder(context);
    return Image(
      image: image,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (BuildContext context, Object _, StackTrace? _) =>
          _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    final AppColors c = context.colors;
    final double side = iconSize ??
        ((width ?? height ?? 44) * 0.42).clamp(16.0, 34.0).toDouble();
    return Container(
      width: width,
      height: height,
      color: c.surfaceSunken,
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_camera_back_outlined,
        size: side,
        color: c.textTertiary,
      ),
    );
  }
}
