import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Exporter for rendering high-resolution PNG snapshots of shelves for social sharing.
class ShelfShareExporter {
  /// Captures the widget attached to [repaintBoundaryKey] as a high-res (3.0 pixelRatio) PNG,
  /// saves it to temporary storage, and triggers the OS share sheet.
  static Future<File?> exportAndShare({
    required GlobalKey repaintBoundaryKey,
    String? shareText,
    String filename = 'readsanctuary_bookshelf.png',
  }) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final file = File(p.join(tempDir.path, filename));
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: shareText ?? 'Organized with #ReadSanctuary 📚✨',
        ),
      );

      return file;
    } catch (_) {
      return null;
    }
  }

  /// Converts a [RenderRepaintBoundary] to PNG bytes without sharing (useful for testing or direct saving).
  static Future<List<int>?> captureToPngBytes({
    required GlobalKey repaintBoundaryKey,
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}
