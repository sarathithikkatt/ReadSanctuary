import 'dart:async';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/reading_statuses.dart';
import '../../../core/utils/image_storage_helper.dart';
import '../../../data/local/database.dart';
import '../epub_reader/epub_reader_screen.dart';

/// Full-featured in-app PDF reader supporting page navigation, zoom,
/// horizontal page flipping vs vertical scrolling, bookmarks, jump to page,
/// automatic reading progress syncing, reading session logging, and night mode.
class PdfReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const PdfReaderScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends ConsumerState<PdfReaderScreen> {
  PDFViewController? _pdfViewController;
  String? _pdfAbsolutePath;
  int _currentPage = 0; // 0-indexed in flutter_pdfview
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _sessionStartTime = 0;
  int _initialStartPage = 0;
  bool _isNightMode = false;
  bool _swipeHorizontal = false;
  static const _uuid = Uuid();

  List<BookNote> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    // 0-indexed internally: page 1 in UI is index 0
    _currentPage = (widget.book.lastReadPage > 0 ? widget.book.lastReadPage - 1 : 0);
    _initialStartPage = _currentPage;
    _resolvePdfPath();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    try {
      final sessionDao = ref.read(sessionDaoProvider);
      final bms = await sessionDao.getBookmarksForBook(widget.book.id);
      if (mounted) {
        setState(() {
          _bookmarks = bms;
        });
      }
    } catch (_) {}
  }

  Future<void> _resolvePdfPath() async {
    final pdfRelativePath = widget.book.pdfPath;
    if (pdfRelativePath == null || pdfRelativePath.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No PDF file is attached to this book.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final storage = ref.read(imageStorageHelperProvider);
      final file = await storage.getFile(pdfRelativePath);
      final exists = await file.exists();
      final length = exists ? await file.length() : 0;

      if (!exists || length == 0) {
        if (mounted) {
          setState(() {
            _errorMessage = 'The PDF file could not be found on local storage.';
            _isLoading = false;
          });
        }
        return;
      }

      // Check if file is actually an EPUB (ZIP archive header PK\x03\x04)
      if (length > 4) {
        try {
          final header = await file.openRead(0, 4).first;
          final isZip = header.length >= 4 &&
              header[0] == 0x50 &&
              header[1] == 0x4B &&
              header[2] == 0x03 &&
              header[3] == 0x04;
          if (isZip) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => EpubReaderScreen(book: widget.book)),
              );
            }
            return;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _pdfAbsolutePath = file.path;
        });
      }

      // Automatically update status to Currently Reading if it was TBR
      if (widget.book.status == ReadingStatus.tbr.id) {
        final bookDao = ref.read(bookDaoProvider);
        await bookDao.updateBook(
          widget.book.copyWith(
            status: ReadingStatus.reading.id,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _recordReadingSession();
    super.dispose();
  }

  Future<void> _recordReadingSession() async {
    final durationSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _sessionStartTime) / 1000)
            .round();

    final startPage1 = _initialStartPage + 1;
    final endPage1 = _currentPage + 1;

    // Only record if reader was open for at least 5 seconds
    if (durationSeconds >= 5 && endPage1 >= startPage1) {
      try {
        final sessionDao = ref.read(sessionDaoProvider);
        await sessionDao.insertSession(
          ReadingSessionsCompanion.insert(
            id: _uuid.v4(),
            bookId: widget.book.id,
            startTime: _sessionStartTime,
            durationSeconds: durationSeconds,
            startPage: startPage1,
            endPage: endPage1,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _onPageChanged(int pageIndex) async {
    if (!mounted) return;
    setState(() {
      _currentPage = pageIndex;
    });

    final humanPage = pageIndex + 1;
    final bookDao = ref.read(bookDaoProvider);
    await bookDao.updateBookLastReadPage(widget.book.id, humanPage);

    // If reached last page, update status to finished
    if (_totalPages > 0 && humanPage >= _totalPages) {
      await bookDao.updateBook(
        widget.book.copyWith(
          status: ReadingStatus.finished.id,
          lastReadPage: humanPage,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
  }

  bool get _isCurrentPageBookmarked =>
      _bookmarks.any((b) => b.pageNumber == (_currentPage + 1));

  Future<void> _toggleBookmark() async {
    final humanPage = _currentPage + 1;
    final sessionDao = ref.read(sessionDaoProvider);
    final messenger = ScaffoldMessenger.of(context);

    if (_isCurrentPageBookmarked) {
      await sessionDao.deleteBookmarkForPage(widget.book.id, humanPage);
      await _loadBookmarks();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Bookmark removed from page $humanPage'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      final noteCtrl = TextEditingController(text: 'Page $humanPage');
      final title = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Bookmark Page $humanPage 🔖'),
          content: TextField(
            controller: noteCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Bookmark Label / Note (optional)',
              hintText: 'e.g. Chapter Start, Key Quote...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(noteCtrl.text.trim()),
              child: const Text('Save Bookmark'),
            ),
          ],
        ),
      );

      if (title != null && mounted) {
        final label = title.isNotEmpty ? title : 'Page $humanPage';
        await sessionDao.insertNote(
          BookNotesCompanion.insert(
            id: _uuid.v4(),
            bookId: widget.book.id,
            noteType: 'bookmark',
            content: label,
            pageNumber: drift.Value(humanPage),
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        await _loadBookmarks();
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Page $humanPage bookmarked! 🔖'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _showBookmarksSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bookmarks, color: Colors.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Bookmarks (${_bookmarks.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                if (_bookmarks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(Icons.bookmark_border,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No bookmarks yet.',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the bookmark icon in the top bar to bookmark page ${_currentPage + 1}.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _bookmarks.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final bm = _bookmarks[i];
                        final pageNum = bm.pageNumber ?? 1;
                        final isCurrent = pageNum == (_currentPage + 1);

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCurrent
                                ? Colors.amber.shade700
                                : Colors.amber.shade100,
                            foregroundColor: isCurrent
                                ? Colors.white
                                : Colors.amber.shade900,
                            child: Text(
                              '$pageNum',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          title: Text(
                            bm.content.isNotEmpty ? bm.content : 'Page $pageNum',
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Page $pageNum'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                tooltip: 'Delete bookmark',
                                onPressed: () async {
                                  final sessionDao = ref.read(sessionDaoProvider);
                                  await sessionDao.deleteNote(bm.id);
                                  await _loadBookmarks();
                                  setSheetState(() {});
                                },
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            final targetIndex = pageNum - 1;
                            _pdfViewController?.setPage(targetIndex);
                            setState(() => _currentPage = targetIndex);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showJumpToPageDialog() async {
    final textCtrl = TextEditingController(text: '${_currentPage + 1}');
    final target = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: textCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Page Number (1 - $_totalPages)',
            hintText: 'Enter page',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(textCtrl.text.trim());
              if (page != null && page >= 1 && page <= _totalPages) {
                Navigator.of(context).pop(page);
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );

    if (target != null && _pdfViewController != null) {
      final index = target - 1;
      await _pdfViewController!.setPage(index);
      setState(() => _currentPage = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isNightMode ? const Color(0xFF1E1E1E) : Colors.grey.shade200;
    final displayPage = _currentPage + 1;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
            if (_totalPages > 0)
              Text(
                'Page $displayPage of $_totalPages (${((displayPage / _totalPages) * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isCurrentPageBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: _isCurrentPageBookmarked ? Colors.amber : null,
            ),
            tooltip: _isCurrentPageBookmarked
                ? 'Remove Bookmark (Page $displayPage)'
                : 'Bookmark Page $displayPage',
            onPressed: _totalPages > 0 ? _toggleBookmark : null,
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: _bookmarks.isNotEmpty,
              label: Text('${_bookmarks.length}'),
              child: const Icon(Icons.bookmarks_outlined),
            ),
            tooltip: 'View Bookmarks (${_bookmarks.length})',
            onPressed: _showBookmarksSheet,
          ),
          IconButton(
            icon: Icon(_swipeHorizontal ? Icons.view_day : Icons.view_carousel),
            tooltip: _swipeHorizontal
                ? 'Switch to Vertical Scroll'
                : 'Switch to Horizontal Flip',
            onPressed: () => setState(() => _swipeHorizontal = !_swipeHorizontal),
          ),
          IconButton(
            icon: Icon(_isNightMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: _isNightMode ? 'Light Mode' : 'Night Mode',
            onPressed: () => setState(() => _isNightMode = !_isNightMode),
          ),
          if (_totalPages > 0)
            IconButton(
              icon: const Icon(Icons.pin_outlined),
              tooltip: 'Jump to Page',
              onPressed: _showJumpToPageDialog,
            ),
        ],
      ),
      body: _buildBody(),
      // Keep bottomNavigationBar permanently mounted to prevent Scaffold viewport height jumps
      // which detach/break Android platform view surfaces.
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text('Attach / Replace PDF'),
                onPressed: () async {
                  final storage = ref.read(imageStorageHelperProvider);
                  final relativePath =
                      await storage.pickAndSavePdf(bookId: widget.book.id);
                  if (relativePath != null && mounted) {
                    final bookDao = ref.read(bookDaoProvider);
                    await bookDao.updateBookPdf(widget.book.id, relativePath);
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _resolvePdfPath();
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfAbsolutePath == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Opening book PDF...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: PDFView(
            key: ValueKey('pdf_${widget.book.id}_${_swipeHorizontal ? "h" : "v"}'),
            filePath: _pdfAbsolutePath!,
            enableSwipe: true,
            swipeHorizontal: _swipeHorizontal,
            autoSpacing: true,
            pageFling: false,
            pageSnap: true,
            defaultPage: _initialStartPage,
            fitPolicy: _swipeHorizontal ? FitPolicy.BOTH : FitPolicy.WIDTH,
            nightMode: _isNightMode,
            backgroundColor: _isNightMode ? const Color(0xFF1E1E1E) : Colors.white,
            gestureRecognizers: {
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _totalPages = pages ?? 0;
                  _isLoading = false;
                });
                // Ensure initial last-read page is commanded on the controller
                if (_initialStartPage > 0 && _pdfViewController != null) {
                  _pdfViewController!.setPage(_initialStartPage);
                }
              }
            },
            onViewCreated: (PDFViewController controller) {
              _pdfViewController = controller;
              if (_initialStartPage > 0) {
                controller.setPage(_initialStartPage);
              }
            },
            onPageChanged: (int? page, int? total) {
              if (page != null) {
                _onPageChanged(page);
              }
            },
            onError: (error) {
              if (mounted) {
                setState(() {
                  _errorMessage = error.toString();
                  _isLoading = false;
                });
              }
            },
            onPageError: (page, error) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Page $page error: $error';
                });
              }
            },
          ),
        ),
        if (_isLoading)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Rendering document...'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isReady = _totalPages > 0;
    final displayPage = isReady ? (_currentPage + 1) : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Page',
              onPressed: (isReady && _currentPage > 0)
                  ? () async {
                      final prev = _currentPage - 1;
                      await _pdfViewController?.setPage(prev);
                      setState(() => _currentPage = prev);
                    }
                  : null,
            ),
            Expanded(
              child: Slider(
                value: isReady
                    ? displayPage.toDouble().clamp(1.0, _totalPages.toDouble())
                    : 1.0,
                min: 1.0,
                max: isReady ? _totalPages.toDouble() : 1.0,
                divisions: (isReady && _totalPages > 1) ? _totalPages - 1 : 1,
                label: isReady ? '$displayPage' : null,
                onChanged: isReady
                    ? (val) {
                        final target = val.round();
                        final targetIndex = target - 1;
                        if (targetIndex != _currentPage) {
                          _pdfViewController?.setPage(targetIndex);
                          setState(() => _currentPage = targetIndex);
                        }
                      }
                    : null,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Page',
              onPressed: (isReady && displayPage < _totalPages)
                  ? () async {
                      final next = _currentPage + 1;
                      await _pdfViewController?.setPage(next);
                      setState(() => _currentPage = next);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
