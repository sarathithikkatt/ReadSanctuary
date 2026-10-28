import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders a face-out book cover with subtle 3D perspective tilt or a horizontal stack.
class BookCoverTiltWidget extends StatelessWidget {
  final String id;
  final String title;
  final List<String> authors;
  final String? coverUrl;
  final String? localCoverAbsolutePath;
  final int spineColorHex;
  final int spineTextHex;
  final String displayMode; // 'cover_out' or 'stacked'
  final VoidCallback? onTap;

  const BookCoverTiltWidget({
    super.key,
    required this.id,
    required this.title,
    this.authors = const [],
    this.coverUrl,
    this.localCoverAbsolutePath,
    this.spineColorHex = 0xFF2C3E50,
    this.spineTextHex = 0xFFFFFFFF,
    this.displayMode = 'cover_out',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (displayMode == 'stacked') {
      return _buildStackedView();
    }
    return _buildFaceOutCover();
  }

  Widget _buildFaceOutCover() {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6.0),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateY(-0.06), // subtle 3D tilt
          child: Container(
            width: 110.0,
            height: 170.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 6.0,
                  offset: const Offset(3.0, 3.0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3.0),
              child: _buildCoverContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedView() {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 95.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStackSlice(90.0, 14.0, Color(spineColorHex)),
              const SizedBox(height: 1),
              _buildStackSlice(93.0, 16.0, Color(spineColorHex).withOpacity(0.85)),
              const SizedBox(height: 1),
              _buildStackSlice(95.0, 18.0, Color(spineColorHex).withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStackSlice(double width, double height, Color color) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 2.0,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverContent() {
    if (localCoverAbsolutePath != null && File(localCoverAbsolutePath!).existsSync()) {
      return Image.file(
        File(localCoverAbsolutePath!),
        fit: BoxFit.cover,
      );
    }

    if (coverUrl != null && coverUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Color(spineColorHex),
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ),
        errorWidget: (context, url, error) => _buildProceduralCover(),
      );
    }

    return _buildProceduralCover();
  }

  Widget _buildProceduralCover() {
    final author = authors.isNotEmpty ? authors.first : '';
    return Container(
      color: Color(spineColorHex),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(spineTextHex),
              fontWeight: FontWeight.bold,
              fontSize: 12.0,
            ),
          ),
          if (author.isNotEmpty) ...[
            const SizedBox(height: 8.0),
            Text(
              author,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(spineTextHex).withOpacity(0.85),
                fontSize: 10.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
