import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/constants/reading_statuses.dart';
import '../../../../data/local/database.dart';
import '../../bookshelf/widgets/book_cover_tilt_widget.dart';
import '../../bookshelf/widgets/interactive_3d_book_viewer.dart';

/// Top visual header for BookDetailScreen displaying cover preview, title, author, format, and status chips.
class BookDetailHeader extends StatelessWidget {
  final Book book;
  final List<String> authors;

  const BookDetailHeader({
    super.key,
    required this.book,
    required this.authors,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(book.spineColorHex);
    final statusColor = ReadingStatus.getColor(book.status);
    final statusLabel = ReadingStatus.getLabel(book.status);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Book Cover / Tilt Preview with 3D Inspect trigger
        GestureDetector(
          onTap: () => Interactive3dBookViewer.show(context, book: book),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Container(
                  width: 102,
                  height: 154,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: book.coverPath != null &&
                          File(book.coverPath!).existsSync()
                      ? Image.file(File(book.coverPath!), fit: BoxFit.cover)
                      : BookCoverTiltWidget(
                          id: book.id,
                          title: book.title,
                          spineColorHex: book.spineColorHex,
                          spineTextHex: book.spineTextHex,
                          onTap: () =>
                              Interactive3dBookViewer.show(context, book: book),
                        ),
                ),
              ),
              // Floating 3D badge overlay
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.35),
                      width: 0.8,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar, size: 11, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        '3D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Book Metadata Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book.title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                authors.join(', '),
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 5,
                children: [
                  Chip(
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFFEFEBE4),
                    side: BorderSide(color: Colors.black.withOpacity(0.06)),
                    label: Text(book.format.toUpperCase()),
                  ),
                  Chip(
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: const Color(0xFFEFEBE4),
                    side: BorderSide(color: Colors.black.withOpacity(0.06)),
                    label: Text('${book.pageCount} pgs'),
                  ),
                  Chip(
                    padding: EdgeInsets.zero,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: statusColor.withOpacity(0.12),
                    side: BorderSide(color: statusColor.withOpacity(0.2)),
                    label: Text(statusLabel),
                  ),
                  if (book.status == 'lent' &&
                      book.subtitle != null &&
                      book.subtitle!.isNotEmpty)
                    Chip(
                      padding: EdgeInsets.zero,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.amber.withOpacity(0.12),
                      side: BorderSide(color: Colors.amber.withOpacity(0.25)),
                      avatar: Icon(Icons.handshake_outlined,
                          size: 14, color: Colors.amber.shade900),
                      label: Text('Lent to: ${book.subtitle}'),
                    ),
                  if (book.seriesName != null && book.seriesName!.isNotEmpty)
                    Chip(
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: const Color(0xFFEFEBE4),
                      side: BorderSide(color: Colors.black.withOpacity(0.06)),
                      avatar: const Icon(Icons.collections_bookmark_outlined, size: 14),
                      label: Text(
                        '${book.seriesName} #${book.seriesIndex ?? 1}',
                      ),
                    ),
                  if (book.pdfPath != null && book.pdfPath!.isNotEmpty)
                    Chip(
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.green.withOpacity(0.12),
                      side: BorderSide(color: Colors.green.withOpacity(0.25)),
                      avatar: Icon(
                        book.pdfPath!.toLowerCase().endsWith('.epub') ||
                                book.pdfPath!.toLowerCase().endsWith('.epub3')
                            ? Icons.auto_stories
                            : Icons.picture_as_pdf,
                        size: 14,
                        color: Colors.green.shade800,
                      ),
                      label: Text(
                        book.pdfPath!.toLowerCase().endsWith('.epub') ||
                                book.pdfPath!.toLowerCase().endsWith('.epub3')
                            ? (book.lastReadPage > 1
                                ? 'EPUB • Ch ${book.lastReadPage}'
                                : 'EPUB READY')
                            : (book.lastReadPage > 1
                                ? 'PDF • Pg ${book.lastReadPage}'
                                : 'PDF READY'),
                        style: TextStyle(color: Colors.green.shade800),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (book.rating != null && book.rating! > 0)
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${book.rating!.toStringAsFixed(2)} / 5.0',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF2C2C2C),
                      ),
                    ),
                  ],
                ),
              if (book.ratingPlot != null ||
                  book.ratingCharacters != null ||
                  book.ratingWriting != null ||
                  book.ratingPacing != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (book.ratingPlot != null && book.ratingPlot! > 0)
                      _buildSubRatingBadge(
                          'Plot', book.ratingPlot!, Colors.indigo.shade700),
                    if (book.ratingCharacters != null &&
                        book.ratingCharacters! > 0)
                      _buildSubRatingBadge('Characters',
                          book.ratingCharacters!, Colors.purple.shade700),
                    if (book.ratingWriting != null && book.ratingWriting! > 0)
                      _buildSubRatingBadge('Writing', book.ratingWriting!,
                          Colors.teal.shade700),
                    if (book.ratingPacing != null && book.ratingPacing! > 0)
                      _buildSubRatingBadge('Pacing', book.ratingPacing!,
                          Colors.deepOrange.shade700),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubRatingBadge(String label, double rating, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ${rating.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Icon(Icons.star_rounded, size: 10, color: color),
        ],
      ),
    );
  }
}
