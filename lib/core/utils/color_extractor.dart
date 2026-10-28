import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Holds extracted spine background and contrasting typography colors.
class SpineColors {
  final Color spineColor;
  final Color textColor;

  const SpineColors({
    required this.spineColor,
    required this.textColor,
  });

  int get spineColorHex => spineColor.value;
  int get spineTextHex => textColor.value;

  /// Default fallback colors when no cover is available or extraction fails.
  static const fallback = SpineColors(
    spineColor: Color(0xFF2C3E50),
    textColor: Colors.white,
  );
}

/// Helper to extract spine colors from a book cover using PaletteGenerator
/// and calculate high-contrast typography color via luminance calculation.
class ColorExtractor {
  /// Extracts the dominant or vibrant color from [imageProvider] and computes
  /// a contrasting typography color based on luminance.
  static Future<SpineColors> extractFromImageProvider(
    ImageProvider imageProvider, {
    Size? size,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        imageProvider,
        size: size,
        timeout: timeout,
      );

      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color ??
          SpineColors.fallback.spineColor;

      return fromColor(color);
    } catch (_) {
      return SpineColors.fallback;
    }
  }

  /// Calculates contrasting typography color for a given background color.
  /// Uses computeLuminance() > 0.5 ? Colors.black87 : Colors.white.
  static SpineColors fromColor(Color bgColor) {
    final isLight = bgColor.computeLuminance() > 0.5;
    final textColor = isLight ? Colors.black87 : Colors.white;
    return SpineColors(spineColor: bgColor, textColor: textColor);
  }

  /// Calculates contrasting text ARGB int directly from background ARGB int.
  static int getContrastingTextHex(int bgColorHex) {
    final color = Color(bgColorHex);
    return fromColor(color).spineTextHex;
  }
}
