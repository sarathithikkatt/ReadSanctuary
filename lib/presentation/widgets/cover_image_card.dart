import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_storage_helper.dart';

/// Renders a book cover from local cache or remote URL, with graceful offline typographic fallback card.
class CoverImageCard extends StatelessWidget {
  final String? coverPath;
  final String title;
  final String author;
  final int spineColorHex;
  final int spineTextHex;
  final double width;
  final double height;
  final double borderRadius;

  const CoverImageCard({
    super.key,
    this.coverPath,
    required this.title,
    required this.author,
    this.spineColorHex = 0xFF2A2A2A,
    this.spineTextHex = 0xFFFFFFFF,
    this.width = 100,
    this.height = 150,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    File? coverFile;
    if (coverPath != null && coverPath!.isNotEmpty) {
      final absPath = ImageStorageHelper.resolvePathSync(coverPath!);
      if (absPath != null) {
        final f = File(absPath);
        if (f.existsSync()) {
          coverFile = f;
        }
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Color(spineColorHex),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: coverFile != null
            ? Image.file(
                coverFile,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildTypographicFallback(),
              )
            : _buildTypographicFallback(),
      ),
    );
  }

  Widget _buildTypographicFallback() {
    final cleanAuthor = Formatters.formatAuthors(author);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxHeight < 80 || constraints.maxWidth < 60;
        final isTiny = constraints.maxHeight < 50 || constraints.maxWidth < 40;
        final hPad = isSmall ? 4.0 : 8.0;
        final vPad = isSmall ? 4.0 : 10.0;
        final titleFontSize = isTiny ? 7.0 : (isSmall ? 9.0 : 12.0);
        final authorFontSize = isTiny ? 6.0 : (isSmall ? 8.0 : 10.0);

        return Container(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            color: Color(spineColorHex),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: isSmall ? 2 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(spineTextHex),
                    fontWeight: FontWeight.bold,
                    fontSize: titleFontSize,
                    height: 1.15,
                  ),
                ),
              ),
              if (!isTiny) ...[
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    cleanAuthor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Color(spineTextHex).withOpacity(0.75),
                      fontSize: authorFontSize,
                      height: 1.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
