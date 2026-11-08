import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';
import '../ocr_quote_scanner.dart';

/// Renders the Quotes & Notes section with real-time stream updates and OCR scanner launcher.
class BookNotesSection extends StatelessWidget {
  final String bookId;
  final String bookTitle;
  final Stream<List<BookNote>> notesStream;

  const BookNotesSection({
    super.key,
    required this.bookId,
    this.bookTitle = '',
    required this.notesStream,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Quotes & Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Note'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OcrQuoteScanner(
                    bookId: bookId,
                    bookTitle: bookTitle,
                  ),
                ),
              ),
            ),
          ],
        ),
        StreamBuilder<List<BookNote>>(
          stream: notesStream,
          builder: (context, snapshot) {
            final notes = snapshot.data ?? [];
            if (notes.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    'No quotes or notes yet. Scan physical pages with OCR!',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final note = notes[idx];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              label: Text(note.noteType.toUpperCase()),
                              visualDensity: VisualDensity.compact,
                              labelStyle: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            if (note.pageNumber != null)
                              Text(
                                'Page ${note.pageNumber}',
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"${note.content}"',
                          style: const TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
