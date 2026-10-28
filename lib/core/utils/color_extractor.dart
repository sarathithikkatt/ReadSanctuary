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

  /// Generates a deterministic, aesthetically pleasing spine color palette from a title/seed string.
  static SpineColors generateFromTitle(String seed) {
    const palette = [
      Color(0xFF2C3E50), // Navy
      Color(0xFF8B0000), // Crimson
      Color(0xFF2E4053), // Slate
      Color(0xFF1E8449), // Forest Green
      Color(0xFF6C3483), // Royal Purple
      Color(0xFF935116), // Leather Brown
      Color(0xFF1F618D), // Ocean Blue
      Color(0xFF78281F), // Dark Mahogany
      Color(0xFF117A65), // Dark Teal
      Color(0xFF4A235A), // Deep Plum
    ];

    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    final color = palette[hash % palette.length];
    return fromColor(color);
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
