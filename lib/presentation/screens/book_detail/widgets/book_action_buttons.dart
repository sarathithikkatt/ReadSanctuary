import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/local/database.dart';
import '../../../../data/remote/free_book_service.dart';
import '../../epub_reader/epub_reader_screen.dart';
import '../../pdf_reader/pdf_reader_screen.dart';
import '../../spine_cropper/spine_cropper_screen.dart';
import '../../timer/reading_timer_screen.dart';
import '../ocr_quote_scanner.dart';

/// Action buttons for a book: Read PDF (or Upload/Find Free PDF), Read Timer,
/// Quote OCR scanner, and Crop Spine shortcut.
class BookActionButtons extends ConsumerWidget {
  final Book book;

  const BookActionButtons({
    super.key,
    required this.book,
  });

  Future<void> _handleFindFreePdf(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final freeBookService = ref.read(freeBookServiceProvider);
    final authors = Formatters.parseAuthors(book.authors);
    final author = authors.isNotEmpty ? authors.first : null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Searching Internet Archive & Gutenberg...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final freePdfUrl =
          await freeBookService.findFreePdfForBook(book.title, author: author);

      if (context.mounted) Navigator.of(context).pop(); // dismiss search dialog

      if (freePdfUrl != null && context.mounted) {
        // Confirm download
        final download = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Free PDF Found! 🎉'),
            content: Text(
                'A free open-access copy was found for "${book.title}". Would you like to download it now?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Download & Attach'),
              ),
            ],
          ),
        );

        if (download == true && context.mounted) {
          // Show downloading dialog
          double progress = 0.0;
          StateSetter? dialogSetState;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDialogState) {
                dialogSetState = setDialogState;
                return AlertDialog(
                  title: const Text('Downloading Free Book...'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      LinearProgressIndicator(value: progress > 0 ? progress : null),
                      const SizedBox(height: 12),
                      Text(progress > 0
                          ? '${(progress * 100).toStringAsFixed(0)}%'
                          : 'Starting download...'),
                    ],
                  ),
                );
              },
            ),
          );

          final localPdfPath = await freeBookService.downloadAndSavePdf(
            freePdfUrl,
            book.id,
            onProgress: (count, total) {
              if (total > 0 && dialogSetState != null) {
                dialogSetState!(() {
                  progress = count / total;
                });
              }
            },
          );

          if (context.mounted) Navigator.of(context).pop(); // dismiss download dialog

          final db = ref.read(appDatabaseProvider);
          await db.bookDao.updateBookPdf(book.id, localPdfPath);

          final isEpub = localPdfPath.toLowerCase().endsWith('.epub');
          messenger.showSnackBar(
            SnackBar(
              content: Text(isEpub
                  ? 'Free eBook (EPUB) downloaded! Tap Read EPUB to begin 📖'
                  : 'Free PDF downloaded! Tap Read PDF to begin 📖'),
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
                'No free public domain copy found for this title. You can upload your own PDF/eBook anytime!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        final errorMsg = e.toString().contains('401') || e.toString().contains('403')
            ? 'This title is restricted by the archive (borrow-only). You can upload your own PDF/EPUB anytime!'
            : 'Download error: $e';
        messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    }
  }

  Future<void> _handleUploadPdf(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final storage = ref.read(imageStorageHelperProvider);
    final path = await storage.pickAndSavePdf(bookId: book.id);
    if (path != null && context.mounted) {
      final db = ref.read(appDatabaseProvider);
      await db.bookDao.updateBookPdf(book.id, path);
      messenger.showSnackBar(
        const SnackBar(content: Text('PDF uploaded successfully! 📖')),
      );
    }
  }

  Future<void> _handleRemovePdf(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PDF'),
        content: const Text('Are you sure you want to remove the attached PDF from this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final db = ref.read(appDatabaseProvider);
      await db.bookDao.updateBookPdf(book.id, null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF detached from book.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasFile = book.pdfPath != null && book.pdfPath!.isNotEmpty;
    final isEpub = hasFile &&
        (book.pdfPath!.toLowerCase().endsWith('.epub') ||
            book.pdfPath!.toLowerCase().endsWith('.epub3'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Primary Action Row
        if (hasFile) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  ),
                  icon: Icon(isEpub ? Icons.auto_stories : Icons.picture_as_pdf, size: 20),
                  label: Text(
                    isEpub
                        ? (book.lastReadPage > 1
                            ? 'Read EPUB (Resume Ch ${book.lastReadPage})'
                            : 'Read Book (EPUB)')
                        : (book.lastReadPage > 1
                            ? 'Read PDF (Resume Page ${book.lastReadPage})'
                            : 'Read Book (PDF)'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => isEpub
                          ? EpubReaderScreen(book: book)
                          : PdfReaderScreen(book: book),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: isEpub ? 'eBook Options' : 'PDF Options',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) {
                    if (val == 'replace') {
                      _handleUploadPdf(context, ref);
                    } else if (val == 'remove') {
                      _handleRemovePdf(context, ref);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'replace',
                      child: Text(isEpub ? 'Replace EPUB' : 'Replace PDF'),
                    ),
                    PopupMenuItem(
                      value: 'remove',
                      child: Text(isEpub ? 'Remove EPUB' : 'Remove PDF'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Secondary actions for books with attached PDF/eBook
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B1D2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text(
                    'Read Timer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReadingTimerScreen(book: book),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.black.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  ),
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: const Text(
                    'Quote OCR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.crop, size: 18),
                      tooltip: 'Crop Spine',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final customSpinePath =
                            await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => SpineCropperScreen(bookId: book.id),
                          ),
                        );
                        if (customSpinePath != null && context.mounted) {
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
                    Container(width: 1, height: 18, color: Colors.black.withOpacity(0.08)),
                    IconButton(
                      icon: const Icon(Icons.flip_to_back, size: 18),
                      tooltip: 'Set Back Cover',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final storage = ref.read(imageStorageHelperProvider);
                          final bytes = await File(picked.path).readAsBytes();
                          final relPath = await storage.saveCoverBytes(
                            bytes,
                            filename: 'back_${book.id}.jpg',
                          );
                          final db = ref.read(appDatabaseProvider);
                          await db.bookDao.updateBook(
                            book.copyWith(
                              backCoverPath: drift.Value(relPath),
                              updatedAt: DateTime.now().millisecondsSinceEpoch,
                            ),
                          );
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Back cover updated! 🎨')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          // Row 1: Focus reading & OCR quotes
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B1D2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text(
                    'Read Timer',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReadingTimerScreen(book: book),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.black.withOpacity(0.12)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  icon: const Icon(Icons.document_scanner_outlined, size: 18),
                  label: const Text(
                    'Quote OCR',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
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
            ],
          ),
          const SizedBox(height: 10),
          // Row 2: Digital copies & Spine customization
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.black.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  icon: const Icon(Icons.upload_file_outlined, size: 16),
                  label: const Text(
                    'Upload PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () => _handleUploadPdf(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.black.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                  icon: const Icon(Icons.download_outlined, size: 16),
                  label: const Text(
                    'Find Free PDF',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  onPressed: () => _handleFindFreePdf(context, ref),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.crop, size: 18),
                      tooltip: 'Crop Spine',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final customSpinePath =
                            await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (_) => SpineCropperScreen(bookId: book.id),
                          ),
                        );
                        if (customSpinePath != null && context.mounted) {
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
                    Container(width: 1, height: 18, color: Colors.black.withOpacity(0.08)),
                    IconButton(
                      icon: const Icon(Icons.flip_to_back, size: 18),
                      tooltip: 'Set Back Cover',
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          final storage = ref.read(imageStorageHelperProvider);
                          final bytes = await File(picked.path).readAsBytes();
                          final relPath = await storage.saveCoverBytes(
                            bytes,
                            filename: 'back_${book.id}.jpg',
                          );
                          final db = ref.read(appDatabaseProvider);
                          await db.bookDao.updateBook(
                            book.copyWith(
                              backCoverPath: drift.Value(relPath),
                              updatedAt: DateTime.now().millisecondsSinceEpoch,
                            ),
                          );
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Back cover updated! 🎨')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
