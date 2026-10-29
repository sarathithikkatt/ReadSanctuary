import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/local/database.dart';
import '../bookshelf/widgets/book_cover_tilt_widget.dart';
import '../spine_cropper/spine_cropper_screen.dart';
import '../timer/reading_timer_screen.dart';
import 'ocr_quote_scanner.dart';

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
    _notesStream = ref.read(sessionDaoProvider).watchNotesForBook(widget.bookId);
    _sessionsStream = ref.read(sessionDaoProvider).watchSessionsForBook(widget.bookId);
  }

  @override
  Widget build(BuildContext context) {
    final shelfDao = ref.watch(shelfDaoProvider);

    return StreamBuilder<Book?>(
      stream: _bookStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
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

        List<String> authorsList = [];
        try {
          final decoded = jsonDecode(book.authors);
          if (decoded is List) {
            authorsList = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          authorsList = [book.authors];
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Details',
                onPressed: () => _showEditDialog(book),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete Book',
                onPressed: () => _confirmDelete(book),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              // 1. Visual Header (Cover preview + basic stats)
              _buildHeaderSection(book, authorsList),
              const SizedBox(height: 20),

              // 2. Action Buttons (Read Timer, Quote OCR, Crop Spine)
              _buildActionGrid(book),
              const SizedBox(height: 20),

              // 3. Display Mode & Shelf Status
              _buildShelfSettingsCard(book, shelfDao),
              const SizedBox(height: 20),

              // 4. Quotes & Notes Section
              _buildNotesSection(),
              const SizedBox(height: 20),

              // 5. Reading History Section
              _buildSessionsSection(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(Book book, List<String> authors) {
    final color = Color(book.spineColorHex);

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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    backgroundColor: _statusColor(book.status).withOpacity(0.15),
                    label: Text(
                      _statusLabel(book.status),
                      style: TextStyle(
                        color: _statusColor(book.status),
                        fontWeight: FontWeight.bold,
                      ),
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(Book book) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Read Timer', maxLines: 1, overflow: TextOverflow.ellipsis),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReadingTimerScreen(book: book),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            icon: const Icon(Icons.document_scanner, size: 18),
            label: const Text('Quote OCR', maxLines: 1, overflow: TextOverflow.ellipsis),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => OcrQuoteScanner(
                  bookId: book.id,
                  bookTitle: book.title,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.crop),
          tooltip: 'Crop Spine',
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final customSpinePath = await Navigator.of(context).push<String>(
              MaterialPageRoute(
                builder: (_) => SpineCropperScreen(bookId: book.id),
              ),
            );
            if (customSpinePath != null && mounted) {
              final db = ref.read(appDatabaseProvider);
              await db.bookDao.updateBook(
                book.copyWith(
                  customSpinePath: drift.Value(customSpinePath),
                  updatedAt: DateTime.now().millisecondsSinceEpoch,
                ),
              );
              messenger.showSnackBar(
                const SnackBar(content: Text('Custom spine updated! 🎨')),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildShelfSettingsCard(Book book, ShelfDao shelfDao) {
    return FutureBuilder<ShelfItem?>(
      future: shelfDao.getItemByBookId(book.id),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        final isCoverOut = item.displayMode == 'cover_out';

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isCoverOut ? Icons.image : Icons.view_column,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shelf Display Style',
                              style: TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isCoverOut ? 'Front Cover View' : '2.5D Spine View',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isCoverOut,
                  onChanged: (val) async {
                    await shelfDao.updateShelfItem(
                      item.copyWith(displayMode: val ? 'cover_out' : 'spine'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesSection() {
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
                    bookId: widget.bookId,
                    bookTitle: '',
                  ),
                ),
              ),
            ),
          ],
        ),
        StreamBuilder<List<BookNote>>(
          stream: _notesStream,
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                              labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            if (note.pageNumber != null)
                              Text(
                                'Page ${note.pageNumber}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '"${note.content}"',
                          style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14),
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

  Widget _buildSessionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reading Sessions',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReadingSession>>(
          stream: _sessionsStream,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    'No logged reading sessions yet.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final s = sessions[idx];
                final dateStr = DateFormat.yMMMd().format(
                  DateTime.fromMillisecondsSinceEpoch(s.startTime),
                );
                final durationMin = (s.durationSeconds / 60).round();
                final pagesRead = s.endPage - s.startPage;

                return ListTile(
                  dense: true,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.timer_outlined, color: Colors.blueAccent),
                  title: Text('$pagesRead pages in $durationMin mins'),
                  subtitle: Text(dateStr),
                  trailing: Text(
                    'Pgs ${s.startPage} - ${s.endPage}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reading':
        return Colors.green.shade700;
      case 'finished':
        return Colors.blue.shade700;
      case 'dnf':
        return Colors.red.shade700;
      case 'lent':
        return Colors.purple.shade700;
      case 'tbr':
      default:
        return Colors.amber.shade800;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'reading':
        return 'Reading';
      case 'finished':
        return 'Finished';
      case 'dnf':
        return 'DNF';
      case 'lent':
        return 'Lent Out';
      case 'tbr':
      default:
        return 'Want to Read';
    }
  }

  Future<void> _showEditDialog(Book book) async {
    final titleCtrl = TextEditingController(text: book.title);
    final pageCtrl = TextEditingController(text: '${book.pageCount}');
    final seriesNameCtrl = TextEditingController(text: book.seriesName ?? '');
    final seriesIdxCtrl = TextEditingController(
      text: book.seriesIndex != null ? '${book.seriesIndex}' : '',
    );
    double rating = book.rating ?? 0.0;
    String status = book.status;
    String format = book.format;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (setCtx, setDialogState) => AlertDialog(
          title: const Text('Edit Book Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Page Count'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: seriesNameCtrl,
                        decoration: const InputDecoration(labelText: 'Series Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: seriesIdxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Vol # (e.g. 1.5)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: const [
                    DropdownMenuItem(value: 'paperback', child: Text('Paperback')),
                    DropdownMenuItem(value: 'hardcover', child: Text('Hardcover')),
                    DropdownMenuItem(value: 'ebook', child: Text('eBook')),
                    DropdownMenuItem(value: 'audiobook', child: Text('Audiobook')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => format = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Reading Status'),
                  items: const [
                    DropdownMenuItem(value: 'tbr', child: Text('Want to Read (TBR)')),
                    DropdownMenuItem(value: 'reading', child: Text('Currently Reading')),
                    DropdownMenuItem(value: 'finished', child: Text('Finished')),
                    DropdownMenuItem(value: 'dnf', child: Text('Did Not Finish (DNF)')),
                    DropdownMenuItem(value: 'lent', child: Text('Lent Out')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => status = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('Rating: ${rating.toStringAsFixed(2)} ★'),
                    Expanded(
                      child: Slider(
                        value: rating,
                        min: 0.0,
                        max: 5.0,
                        divisions: 20, // 0.25 increment steps
                        label: rating.toStringAsFixed(2),
                        onChanged: (val) => setDialogState(() => rating = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(appDatabaseProvider);
                final now = DateTime.now().millisecondsSinceEpoch;
                final pages = int.tryParse(pageCtrl.text.trim()) ?? book.pageCount;
                final seriesIdx = double.tryParse(seriesIdxCtrl.text.trim());

                await db.bookDao.updateBook(
                  book.copyWith(
                    title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : book.title,
                    pageCount: pages,
                    format: format,
                    status: status,
                    rating: drift.Value(rating > 0 ? rating : null),
                    seriesName: drift.Value(seriesNameCtrl.text.trim().isNotEmpty ? seriesNameCtrl.text.trim() : null),
                    seriesIndex: drift.Value(seriesIdx),
                    updatedAt: now,
                  ),
                );

                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"? This cannot be undone.'),
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
}
