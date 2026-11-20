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
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note_outlined,
                          size: 28, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No quotes or notes yet. Scan physical pages with OCR!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final note = notes[idx];
                final isQuote = note.noteType.toLowerCase() == 'quote';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isQuote
                                  ? const Color(0xFF6B1D2F).withOpacity(0.08)
                                  : const Color(0xFFC79C5E).withOpacity(0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              note.noteType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isQuote
                                    ? const Color(0xFF6B1D2F)
                                    : const Color(0xFFA87E42),
                              ),
                            ),
                          ),
                          if (note.pageNumber != null)
                            Text(
                              'Page ${note.pageNumber}',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '"${note.content}"',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                          height: 1.4,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ],
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
