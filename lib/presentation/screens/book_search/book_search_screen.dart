import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/book_formats.dart';
import '../../../core/constants/reading_statuses.dart';
import '../../../core/utils/color_extractor.dart';
import '../../../core/utils/image_storage_helper.dart';
import '../../../data/local/database.dart';
import '../../../data/remote/book_lookup_service.dart';
import '../../../data/remote/free_book_service.dart';
import '../../../domain/models/book_metadata.dart';
import '../pdf_reader/pdf_reader_screen.dart';

/// Screen allowing users to search books across multiple sources (OpenLibrary,
/// Internet Archive, Project Gutenberg, and Google Books), detect free readable PDFs,
/// download free books, upload their own PDFs, and add them directly to their shelves.
class BookSearchScreen extends ConsumerStatefulWidget {
  final String? initialShelfId;

  const BookSearchScreen({super.key, this.initialShelfId});

  @override
  ConsumerState<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends ConsumerState<BookSearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BookMetadata> _results = [];
  bool _isLoading = false;
  bool _filterFreeOnly = false;
  String? _errorMessage;
  static const _uuid = Uuid();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final freeBookService = ref.read(freeBookServiceProvider);
      final lookupService = ref.read(bookLookupServiceProvider);

      // Query both services in parallel
      final futures = await Future.wait([
        freeBookService.searchFreeBooks(query),
        lookupService.search(query),
      ]);

      final freeResults = futures[0];
      final regularResults = futures[1];

      // Merge and deduplicate by title/author
      final combined = <BookMetadata>[];
      final seenKeys = <String>{};

      for (final book in [...freeResults, ...regularResults]) {
        final key = '${book.title.toLowerCase().trim()}_${book.authors.join(',').toLowerCase().trim()}';
        if (!seenKeys.contains(key)) {
          seenKeys.add(key);
          combined.add(book);
        } else if (book.freePdfUrl != null) {
          // If already added but this one has a free PDF, replace with enriched version
          final existingIdx = combined.indexWhere((b) =>
              '${b.title.toLowerCase().trim()}_${b.authors.join(',').toLowerCase().trim()}' ==
              key);
          if (existingIdx != -1 && combined[existingIdx].freePdfUrl == null) {
            combined[existingIdx] = combined[existingIdx].copyWith(
              freePdfUrl: book.freePdfUrl,
              source: book.source,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _results = combined;
          _isLoading = false;
          if (combined.isEmpty) {
            _errorMessage = 'No books found for "$query". Try another search term.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Search failed: $e';
        });
      }
    }
  }

  Future<String?> _selectTargetShelf() async {
    final shelfDao = ref.read(shelfDaoProvider);
    final shelves = await shelfDao.getAllShelves();
    if (shelves.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a shelf first!')),
        );
      }
      return null;
    }

    if (widget.initialShelfId != null) {
      return widget.initialShelfId;
    }

    if (!mounted) return null;

    return await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Shelf'),
        children: shelves
            .map(
              (s) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(s.id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(s.name, style: const TextStyle(fontSize: 16)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Future<Book?> _saveBookToDatabase({
    required BookMetadata metadata,
    required String shelfId,
    String? localPdfPath,
  }) async {
    final bookDao = ref.read(bookDaoProvider);
    final shelfDao = ref.read(shelfDaoProvider);
    final storage = ref.read(imageStorageHelperProvider);

    final bookId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final spineColors = ColorExtractor.generateFromTitle(metadata.title);

    // Save cover if available
    String? coverPath;
    if (metadata.coverUrl != null && metadata.coverUrl!.isNotEmpty) {
      try {
        coverPath = await storage.downloadAndSaveCover(metadata.coverUrl!);
      } catch (_) {}
    }

    final pages = metadata.pageCount ?? 250;
    final format = metadata.freePdfUrl != null || localPdfPath != null
        ? BookFormat.ebook.id
        : BookFormat.paperback.id;

    final companion = BooksCompanion.insert(
      id: bookId,
      isbn13: drift.Value(metadata.isbn13),
      title: metadata.title,
      subtitle: drift.Value(metadata.subtitle),
      authors: jsonEncode(
          metadata.authors.isNotEmpty ? metadata.authors : ['Unknown Author']),
      pageCount: drift.Value(pages),
      format: drift.Value(format),
      status: ReadingStatus.tbr.id,
      coverPath: drift.Value(coverPath),
      pdfPath: drift.Value(localPdfPath),
      lastReadPage: const drift.Value(1),
      spineColorHex: spineColors.spineColorHex,
      spineTextHex: spineColors.spineTextHex,
      createdAt: now,
      updatedAt: now,
    );

    await bookDao.insertBook(companion);

    // Insert ShelfItem
    final existingItems = await shelfDao.getItemsForShelf(shelfId);
    await shelfDao.insertShelfItem(
      ShelfItemsCompanion.insert(
        id: _uuid.v4(),
        shelfId: shelfId,
        itemType: 'book',
        bookId: drift.Value(bookId),
        positionIndex: existingItems.length,
      ),
    );

    return await bookDao.getBookById(bookId);
  }

  Future<void> _handleDownloadAndRead(BookMetadata metadata) async {
    if (metadata.freePdfUrl == null) return;

    final shelfId = await _selectTargetShelf();
    if (shelfId == null || !mounted) return;

    // Show download progress dialog
    final freeBookService = ref.read(freeBookServiceProvider);
    final tempBookId = _uuid.v4();

    double progress = 0.0;
    StateSetter? dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          dialogSetState = setDialogState;
          return AlertDialog(
            title: const Text('Downloading Free Book...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: progress > 0 ? progress : null),
                const SizedBox(height: 12),
                Text(
                  progress > 0
                      ? '${(progress * 100).toStringAsFixed(0)}%'
                      : 'Connecting to free source...',
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final localPdfPath = await freeBookService.downloadAndSavePdf(
        metadata.freePdfUrl!,
        tempBookId,
        onProgress: (count, total) {
          if (total > 0 && dialogSetState != null) {
            dialogSetState!(() {
              progress = count / total;
            });
          }
        },
      );

      if (mounted) Navigator.of(context).pop(); // dismiss loading dialog

      final book = await _saveBookToDatabase(
        metadata: metadata,
        shelfId: shelfId,
        localPdfPath: localPdfPath,
      );

      if (book != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${book.title}" added with PDF! Opening reader...')),
        );
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download free PDF: $e')),
        );
      }
    }
  }

  Future<void> _handleUploadMyPdf(BookMetadata metadata) async {
    final shelfId = await _selectTargetShelf();
    if (shelfId == null || !mounted) return;

    final storage = ref.read(imageStorageHelperProvider);
    final localPdfPath = await storage.pickAndSavePdf();

    if (localPdfPath == null) return; // User cancelled

    final book = await _saveBookToDatabase(
      metadata: metadata,
      shelfId: shelfId,
      localPdfPath: localPdfPath,
    );

    if (book != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" added with uploaded PDF! 📖')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
      );
    }
  }

  Future<void> _handleAddBookOnly(BookMetadata metadata) async {
    final shelfId = await _selectTargetShelf();
    if (shelfId == null || !mounted) return;

    final book = await _saveBookToDatabase(
      metadata: metadata,
      shelfId: shelfId,
    );

    if (book != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" added to shelf! 📚')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filterFreeOnly
        ? _results.where((b) => b.freePdfUrl != null).toList()
        : _results;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search & Explore Books'),
      ),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _performSearch(),
                    decoration: InputDecoration(
                      hintText: 'Search by Title, Author, or ISBN...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _results = [];
                                  _errorMessage = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 14.0),
                  ),
                  onPressed: _performSearch,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All Books'),
                  selected: !_filterFreeOnly,
                  onSelected: (val) {
                    setState(() => _filterFreeOnly = !val);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.auto_stories, size: 16),
                  label: const Text('Free to Read (PDF/eBook)'),
                  selected: _filterFreeOnly,
                  onSelected: (val) {
                    setState(() => _filterFreeOnly = val);
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Body Results
          Expanded(
            child: _buildResultBody(filteredList),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBody(List<BookMetadata> list) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Searching across Internet Archive, Gutenberg & OpenLibrary...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Search for any book by title, author, or keyword.\nFind free public books or upload your own PDF.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12.0),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = list[index];
        final hasFreePdf = book.freePdfUrl != null && book.freePdfUrl!.isNotEmpty;

        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: Container(
                    width: 70,
                    height: 105,
                    color: Colors.grey.shade300,
                    child: book.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: book.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(Icons.book, size: 32, color: Colors.grey),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.book, size: 32, color: Colors.grey),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // Book Details & Actions
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Free badge
                      if (hasFreePdf)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_stories,
                                  size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'FREE PDF / EBOOK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.authors.isNotEmpty
                            ? book.authors.join(', ')
                            : 'Unknown Author',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (book.publishYear != null)
                            Text(
                              book.publishYear!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          if (book.publishYear != null && book.pageCount != null)
                            const Text(' • '),
                          if (book.pageCount != null)
                            Text(
                              '${book.pageCount} pages',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          if (book.source != null) ...[
                            const Text(' • '),
                            Text(
                              book.source!,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blueGrey.shade600,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Action Buttons
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (hasFreePdf)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              icon: const Icon(Icons.download, size: 16),
                              label: const Text('Read Free PDF'),
                              onPressed: () => _handleDownloadAndRead(book),
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            icon: const Icon(Icons.shelves, size: 16),
                            label: const Text('Add to Shelf'),
                            onPressed: () => _handleAddBookOnly(book),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                            icon: const Icon(Icons.upload_file, size: 14),
                            label: const Text('Upload PDF'),
                            onPressed: () => _handleUploadMyPdf(book),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
