import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/database.dart';
import 'dialogs/edit_book_dialog.dart';
import 'widgets/book_action_buttons.dart';
import 'widgets/book_detail_header.dart';
import 'widgets/book_notes_section.dart';
import 'widgets/reading_sessions_section.dart';
import 'widgets/shelf_settings_card.dart';

/// Screen displaying complete details for a book:
/// visual cover/spine previews, reading timers, OCR quote scans,
/// custom spine cropping, granular ratings, and notes.
class BookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends ConsumerState<BookDetailScreen> {
  late final Stream<Book?> _bookStream;
  late final Stream<List<BookNote>> _notesStream;
  late final Stream<List<ReadingSession>> _sessionsStream;

  @override
  void initState() {
    super.initState();
    _bookStream = ref.read(bookDaoProvider).watchBookById(widget.bookId);
    _notesStream =
        ref.read(sessionDaoProvider).watchNotesForBook(widget.bookId);
    _sessionsStream =
        ref.read(sessionDaoProvider).watchSessionsForBook(widget.bookId);
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text(
            'Are you sure you want to delete "${book.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(appDatabaseProvider);
      await db.bookDao.deleteBook(book.id);
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _shareReview(Book book, List<String> authors) async {
    final sessionDao = ref.read(sessionDaoProvider);
    final notes = await sessionDao.getNotesForBook(book.id);

    final quotes = notes.where((n) => n.noteType == 'quote').toList();
    final thoughts = notes.where((n) => n.noteType == 'thought').toList();

    final buffer = StringBuffer();
    buffer.writeln('📚 ReadSanctuary Reading Review: "${book.title}"');
    buffer.writeln('✍️ Author(s): ${authors.join(', ')}');
    if (book.rating != null && book.rating! > 0) {
      buffer.writeln('⭐ Rating: ${book.rating!.toStringAsFixed(2)} / 5.0');
    }
    if (book.ratingPlot != null ||
        book.ratingCharacters != null ||
        book.ratingWriting != null ||
        book.ratingPacing != null) {
      buffer.writeln('📊 Sub-Ratings Breakdown:');
      if (book.ratingPlot != null && book.ratingPlot! > 0) {
        buffer.writeln('  • Plot: ${book.ratingPlot!.toStringAsFixed(2)} ★');
      }
      if (book.ratingCharacters != null && book.ratingCharacters! > 0) {
        buffer.writeln('  • Characters: ${book.ratingCharacters!.toStringAsFixed(2)} ★');
      }
      if (book.ratingWriting != null && book.ratingWriting! > 0) {
        buffer.writeln('  • Writing: ${book.ratingWriting!.toStringAsFixed(2)} ★');
      }
      if (book.ratingPacing != null && book.ratingPacing! > 0) {
        buffer.writeln('  • Pacing: ${book.ratingPacing!.toStringAsFixed(2)} ★');
      }
    }
    buffer.writeln('📖 Status: ${book.status.toUpperCase()} • ${book.pageCount} pages (${book.format})');

    if (book.seriesName != null && book.seriesName!.isNotEmpty) {
      final vol = book.seriesIndex != null ? '#${book.seriesIndex}' : '';
      buffer.writeln('🔖 Series: ${book.seriesName} $vol');
    }

    if (quotes.isNotEmpty) {
      buffer.writeln('\n💬 Favorite Quotes:');
      for (final q in quotes.take(3)) {
        final pg = q.pageNumber != null ? ' (Page ${q.pageNumber})' : '';
        buffer.writeln('> "${q.content}"$pg');
      }
    }

    if (thoughts.isNotEmpty) {
      buffer.writeln('\n🧠 Reader Thoughts:');
      for (final t in thoughts.take(3)) {
        buffer.writeln('• ${t.content}');
      }
    }

    buffer.writeln('\nTracked with ReadSanctuary — Visual Bookshelf & Reading Companion 📚✨');

    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        subject: 'Review: ${book.title}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shelfDao = ref.watch(shelfDaoProvider);
    final bookDao = ref.watch(bookDaoProvider);

    return StreamBuilder<Book?>(
      stream: _bookStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final book = snapshot.data;
        if (book == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Book not found or deleted.')),
          );
        }

        final authorsList = Formatters.parseAuthors(book.authors);

        return Scaffold(
          appBar: AppBar(
            title:
                Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share Review',
                onPressed: () => _shareReview(book, authorsList),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Details',
                onPressed: () => EditBookDialog.show(context, book, bookDao),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete Book',
                onPressed: () => _confirmDelete(book),
              ),
            ],
          ),
          body: ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Visual Header (Cover preview + basic stats)
              BookDetailHeader(book: book, authors: authorsList),
              const SizedBox(height: 20),

              // 2. Action Buttons (Read Timer, Quote OCR, Crop Spine)
              BookActionButtons(book: book),
              const SizedBox(height: 20),

              // 3. Display Mode & Shelf Status
              ShelfSettingsCard(book: book, shelfDao: shelfDao),
              const SizedBox(height: 20),

              // 4. Quotes & Notes Section
              BookNotesSection(
                bookId: widget.bookId,
                bookTitle: book.title,
                notesStream: _notesStream,
              ),
              const SizedBox(height: 20),

              // 5. Reading History Section
              ReadingSessionsSection(
                sessionsStream: _sessionsStream,
                book: book,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
