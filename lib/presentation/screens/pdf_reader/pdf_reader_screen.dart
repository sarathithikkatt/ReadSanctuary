import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/reading_statuses.dart';
import '../../../core/utils/image_storage_helper.dart';
import '../../../data/local/database.dart';

/// Full-featured in-app PDF reader supporting page navigation, zoom,
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
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    // 0-indexed internally: page 1 in UI is index 0
    _currentPage = (widget.book.lastReadPage > 0 ? widget.book.lastReadPage - 1 : 0);
    _initialStartPage = _currentPage;
    _resolvePdfPath();
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

      if (!exists) {
        if (mounted) {
          setState(() {
            _errorMessage = 'The PDF file could not be found on local storage.';
            _isLoading = false;
          });
        }
        return;
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
      bottomNavigationBar: _totalPages > 0 ? _buildBottomBar() : null,
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
        PDFView(
          filePath: _pdfAbsolutePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          pageSnap: true,
          defaultPage: _currentPage,
          fitPolicy: FitPolicy.BOTH,
          nightMode: _isNightMode,
          onRender: (pages) {
            setState(() {
              _totalPages = pages ?? 0;
              _isLoading = false;
            });
          },
          onViewCreated: (PDFViewController controller) {
            _pdfViewController = controller;
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
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final displayPage = _currentPage + 1;

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
              onPressed: _currentPage > 0
                  ? () async {
                      final prev = _currentPage - 1;
                      await _pdfViewController?.setPage(prev);
                      setState(() => _currentPage = prev);
                    }
                  : null,
            ),
            Expanded(
              child: Slider(
                value: displayPage.toDouble().clamp(1.0, _totalPages.toDouble()),
                min: 1.0,
                max: _totalPages.toDouble(),
                divisions: _totalPages > 1 ? _totalPages - 1 : 1,
                label: '$displayPage',
                onChanged: (val) {
                  final target = val.round();
                  final targetIndex = target - 1;
                  if (targetIndex != _currentPage) {
                    _pdfViewController?.setPage(targetIndex);
                    setState(() => _currentPage = targetIndex);
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Page',
              onPressed: displayPage < _totalPages
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
