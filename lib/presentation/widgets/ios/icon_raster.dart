import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Turns an [IconData] into PNG bytes UIKit can draw.
///
/// The native bottom bar renders its own glyphs so the bar can be a real UIKit
/// control — but the glyphs still have to be M4's, from the same Lucide font
/// the Android bar uses. Rasterising them here rather than registering the
/// font with Core Text keeps that guarantee for any [IconData] the portals
/// pass, bundled font or not, with no font plumbing on the Swift side.
///
/// Every glyph is drawn pure white so UIKit can treat it as a template image
/// and tint it, which is what lets the selected glyph ease to its new colour
/// natively.
abstract final class IconRaster {
  /// Rasters already produced, keyed by glyph and pixel size. The bar rebuilds
  /// often and the icon set never changes, so this is worth holding onto.
  static final Map<String, Uint8List> _cache = <String, Uint8List>{};

  /// PNG bytes for [icon] drawn at [size] logical points, scaled by
  /// [devicePixelRatio] so the image is crisp on any screen.
  static Future<Uint8List> png(
    IconData icon, {
    required double size,
    required double devicePixelRatio,
  }) async {
    final String key =
        '${icon.fontFamily}/${icon.fontPackage}/${icon.codePoint}'
        '@${size}x$devicePixelRatio';
    final Uint8List? hit = _cache[key];
    if (hit != null) return hit;

    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color(0xFFFFFFFF),
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double w = painter.width;
    final double h = painter.height;
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    canvas.scale(devicePixelRatio);
    painter.paint(canvas, Offset.zero);

    final ui.Image image = await recorder.endRecording().toImage(
      (w * devicePixelRatio).ceil().clamp(1, 4096),
      (h * devicePixelRatio).ceil().clamp(1, 4096),
    );
    final ByteData? data = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    image.dispose();
    painter.dispose();

    final Uint8List bytes = data!.buffer.asUint8List();
    _cache[key] = bytes;
    return bytes;
  }

  /// [png] for a whole bar's worth of glyphs, in tab order.
  static Future<List<Uint8List>> all(
    List<IconData> icons, {
    required double size,
    required double devicePixelRatio,
  }) {
    return Future.wait<Uint8List>([
      for (final IconData icon in icons)
        png(icon, size: size, devicePixelRatio: devicePixelRatio),
    ]);
  }
}
