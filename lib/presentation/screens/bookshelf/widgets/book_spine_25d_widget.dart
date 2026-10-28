import 'dart:io';
import 'package:flutter/material.dart';

/// 2.5D Procedural and Custom Book Spine widget.
/// Renders realistic 3D lighting, dynamic width scaling based on page count,
/// format-based heights, and vertical typography.
class BookSpine25DWidget extends StatelessWidget {
  final String id;
  final String title;
  final List<String> authors;
  final int pageCount;
  final String format; // hardcover, paperback, ebook, audiobook
  final int spineColorHex;
  final int spineTextHex;
  final String? customSpineAbsolutePath;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const BookSpine25DWidget({
    super.key,
    required this.id,
    required this.title,
    this.authors = const [],
    this.pageCount = 250,
    this.format = 'paperback',
    this.spineColorHex = 0xFF2C3E50,
    this.spineTextHex = 0xFFFFFFFF,
    this.customSpineAbsolutePath,
    this.onTap,
    this.onLongPress,
  });

  /// Dynamic width formula:
  /// pages.clamp(80, 1200) / 14.0 clamped between 26.0 and 62.0 logical pixels.
  static double calculateSpineWidth(int pageCount) {
    return (pageCount.clamp(80, 1200) / 14.0).clamp(26.0, 62.0);
  }

  /// Height formula based on physical book format.
  static double calculateSpineHeight(String format) {
    switch (format.toLowerCase()) {
      case 'hardcover':
        return 185.0;
      case 'paperback':
        return 170.0;
      case 'ebook':
        return 160.0;
      case 'audiobook':
        return 165.0;
      default:
        return 170.0;
    }
  }

  /// 3D Cylindrical shadow gradient overlay to simulate spine curve, ridge highlight, and edge shadows.
  static const LinearGradient cylindricalLightingGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    stops: [0.0, 0.08, 0.22, 0.88, 1.0],
    colors: [
      Colors.black38,
      Colors.white24,
      Colors.transparent,
      Colors.black12,
      Colors.black45,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final width = calculateSpineWidth(pageCount);
    final height = calculateSpineHeight(format);
    final spineColor = Color(spineColorHex);
    final textColor = Color(spineTextHex);
    final authorText = authors.isNotEmpty ? authors.first : '';

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          width: width,
          height: height,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(2.0),
              topRight: Radius.circular(2.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(1.5, 0),
                blurRadius: 2.0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(2.0),
              topRight: Radius.circular(2.0),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Layer 1: Background (Custom Photo or Procedural Color)
                if (customSpineAbsolutePath != null &&
                    File(customSpineAbsolutePath!).existsSync())
                  Image.file(
                    File(customSpineAbsolutePath!),
                    fit: BoxFit.cover,
                  )
                else
                  _buildProceduralSpine(spineColor, textColor, authorText, width),

                // Layer 2: 3D Cylindrical Lighting Shader Overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: cylindricalLightingGradient,
                  ),
                ),

                // Layer 3: Crease groove near spine hinge
                Positioned(
                  left: 3.0,
                  top: 0,
                  bottom: 0,
                  width: 1.0,
                  child: Container(
                    color: Colors.black.withOpacity(0.18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProceduralSpine(
    Color spineColor,
    Color textColor,
    String authorText,
    double width,
  ) {
    return Container(
      color: spineColor,
      child: Column(
        children: [
          // Top Decorative Foil Band
          _buildFoilBand(),
          const SizedBox(height: 8),

          // Vertical Typography
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
              child: RotatedBox(
                quarterTurns: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: width > 35 ? 11.5 : 10.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Author
                    if (authorText.isNotEmpty)
                      Text(
                        authorText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor.withOpacity(0.85),
                          fontSize: width > 35 ? 9.5 : 8.5,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          // Bottom Decorative Foil Band
          _buildFoilBand(),
        ],
      ),
    );
  }

  Widget _buildFoilBand() {
    return Container(
      height: 3.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37).withOpacity(0.6), // Metallic gold
            const Color(0xFFFFF4D0),
            const Color(0xFFD4AF37).withOpacity(0.6),
          ],
        ),
      ),
    );
  }
}
