import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/constants/reading_statuses.dart';
import '../../../../data/local/database.dart';
import '../../bookshelf/widgets/book_cover_tilt_widget.dart';

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
        // Book Cover / Tilt Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(6.0),
          child: Container(
            width: 100,
            height: 150,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(2, 3),
                ),
              ],
            ),
            child: book.coverPath != null && File(book.coverPath!).existsSync()
                ? Image.file(File(book.coverPath!), fit: BoxFit.cover)
                : BookCoverTiltWidget(
                    id: book.id,
                    title: book.title,
                    spineColorHex: book.spineColorHex,
                    spineTextHex: book.spineTextHex,
                  ),
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                authors.join(', '),
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  Chip(
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                    label: Text(book.format.toUpperCase()),
                  ),
                  Chip(
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                    label: Text('${book.pageCount} pgs'),
                  ),
                  Chip(
                    padding: EdgeInsets.zero,
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: statusColor.withOpacity(0.15),
                    label: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (book.status == 'lent' &&
                      book.subtitle != null &&
                      book.subtitle!.isNotEmpty)
                    Chip(
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.amber.withOpacity(0.15),
                      avatar: Icon(Icons.handshake_outlined,
                          size: 14, color: Colors.amber.shade900),
                      label: Text(
                        'Lent to: ${book.subtitle}',
                        style: TextStyle(color: Colors.amber.shade900),
                      ),
                    ),
                  if (book.seriesName != null && book.seriesName!.isNotEmpty)
                    Chip(
                      padding: EdgeInsets.zero,
                      labelStyle: const TextStyle(fontSize: 11),
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.collections_bookmark, size: 14),
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
                      backgroundColor: Colors.green.withOpacity(0.15),
                      avatar: Icon(
                        book.pdfPath!.toLowerCase().endsWith('.epub') ||
                                book.pdfPath!.toLowerCase().endsWith('.epub3')
                            ? Icons.auto_stories
                            : Icons.picture_as_pdf,
                        size: 14,
                        color: Colors.green,
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
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (book.rating != null && book.rating! > 0)
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${book.rating!.toStringAsFixed(2)} / 5.0',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            '${rating.toStringAsFixed(2)}★',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
