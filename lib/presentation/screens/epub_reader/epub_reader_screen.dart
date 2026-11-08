import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/reading_statuses.dart';
import '../../../core/utils/image_storage_helper.dart';
import '../../../data/local/database.dart';
import '../../../data/services/epub_service.dart';

enum EpubThemeMode {
  light(
    label: 'Light',
    backgroundColor: Color(0xFFFAF9F6),
    textColor: Color(0xFF1C1B1F),
    appBarColor: Color(0xFFF0EFEA),
  ),
  sepia(
    label: 'Sepia',
    backgroundColor: Color(0xFFF8F1E3),
    textColor: Color(0xFF3D2F1D),
    appBarColor: Color(0xFFEEDEC5),
  ),
  night(
    label: 'Night',
    backgroundColor: Color(0xFF18181B),
    textColor: Color(0xFFE4E4E7),
    appBarColor: Color(0xFF27272A),
  );

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color appBarColor;

  const EpubThemeMode({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.appBarColor,
  });
}

/// In-app EPUB reader supporting reflowable text, customizable font sizing,
/// serif/sans typography, light/sepia/night themes, chapter jumping, and reading session logging.
class EpubReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const EpubReaderScreen({
    super.key,
    required this.book,
  });

  @override
  ConsumerState<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends ConsumerState<EpubReaderScreen> {
  static const _uuid = Uuid();

  EpubBook? _epubBook;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentChapterIndex = 0; // 0-based
  int _initialChapterIndex = 0;
  int _sessionStartTime = 0;

  double _fontSize = 17.0;
  String _fontFamily = 'Serif'; // 'Serif', 'Sans', 'Monospace'
  EpubThemeMode _themeMode = EpubThemeMode.sepia;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;
    // 0-indexed internally: chapter 1 in UI is index 0
    _currentChapterIndex =
        (widget.book.lastReadPage > 0 ? widget.book.lastReadPage - 1 : 0);
    _initialChapterIndex = _currentChapterIndex;
    _pageController = PageController(initialPage: 0);

    _loadPreferences();
    _loadEpub();
  }

  @override
  void dispose() {
    _recordReadingSession();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _fontSize = prefs.getDouble('epub_font_size') ?? 17.0;
      _fontFamily = prefs.getString('epub_font_family') ?? 'Serif';
      final themeIndex = prefs.getInt('epub_theme_mode') ?? 1; // default sepia
      if (themeIndex >= 0 && themeIndex < EpubThemeMode.values.length) {
        _themeMode = EpubThemeMode.values[themeIndex];
      }
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('epub_font_size', _fontSize);
    await prefs.setString('epub_font_family', _fontFamily);
    await prefs.setInt('epub_theme_mode', _themeMode.index);
  }

  Future<void> _loadEpub() async {
    final relPath = widget.book.pdfPath;
    if (relPath == null || relPath.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'No EPUB eBook file is attached to this book.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final storage = ref.read(imageStorageHelperProvider);
      final file = await storage.getFile(relPath);
      if (!await file.exists()) {
        if (mounted) {
          setState(() {
            _errorMessage = 'The EPUB file could not be found in local storage.';
            _isLoading = false;
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();
      final epubService = ref.read(epubServiceProvider);
      final book = await epubService.parseEpubBytes(bytes);

      if (!mounted) return;

      // Ensure chapter index is within bounds
      if (_currentChapterIndex >= book.chapters.length) {
        _currentChapterIndex = 0;
      }

      setState(() {
        _epubBook = book;
        _isLoading = false;
      });

      // Jump to last read chapter if needed
      if (_currentChapterIndex > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_currentChapterIndex);
          }
        });
      }

      // Automatically update status to reading if it was TBR
      if (widget.book.status == ReadingStatus.tbr.id) {
        try {
          final bookDao = ref.read(bookDaoProvider);
          await bookDao.updateBook(
            widget.book.copyWith(
              status: ReadingStatus.reading.id,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading EPUB eBook: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _recordReadingSession() async {
    final durationSeconds =
        ((DateTime.now().millisecondsSinceEpoch - _sessionStartTime) / 1000)
            .round();

    final startCh1 = _initialChapterIndex + 1;
    final endCh1 = _currentChapterIndex + 1;

    // Only record if reader was open for at least 5 seconds
    if (durationSeconds >= 5) {
      try {
        final sessionDao = ref.read(sessionDaoProvider);
        await sessionDao.insertSession(
          ReadingSessionsCompanion.insert(
            id: _uuid.v4(),
            bookId: widget.book.id,
            startTime: _sessionStartTime,
            durationSeconds: durationSeconds,
            startPage: startCh1,
            endPage: endCh1 >= startCh1 ? endCh1 : startCh1,
          ),
        );

        final bookDao = ref.read(bookDaoProvider);
        final totalChapters = _epubBook?.chapters.length ?? 1;
        final isFinished = endCh1 >= totalChapters;

        await bookDao.updateBook(
          widget.book.copyWith(
            lastReadPage: endCh1,
            status: isFinished ? ReadingStatus.finished.id : widget.book.status,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } catch (_) {}
    }
  }

  TextStyle _getTextStyle() {
    String? family;
    switch (_fontFamily) {
      case 'Monospace':
        family = 'Courier';
        break;
      case 'Sans':
        family = null; // System sans-serif default
        break;
      case 'Serif':
      default:
        family = 'Georgia';
        break;
    }

    return TextStyle(
      fontSize: _fontSize,
      fontFamily: family,
      height: 1.65,
      color: _themeMode.textColor,
      letterSpacing: 0.2,
    );
  }

  void _showTableOfContents() {
    if (_epubBook == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: _themeMode.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Table of Contents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _themeMode.textColor,
                      ),
                    ),
                    Text(
                      '${_epubBook!.chapters.length} Chapters',
                      style: TextStyle(
                        fontSize: 13,
                        color: _themeMode.textColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: _epubBook!.chapters.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: _themeMode.textColor.withOpacity(0.1)),
                  itemBuilder: (ctx, index) {
                    final chapter = _epubBook!.chapters[index];
                    final isCurrent = index == _currentChapterIndex;

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 12,
                        backgroundColor: isCurrent
                            ? Theme.of(context).primaryColor
                            : _themeMode.textColor.withOpacity(0.1),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            color: isCurrent ? Colors.white : _themeMode.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        chapter.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent
                              ? Theme.of(context).primaryColor
                              : _themeMode.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${chapter.wordCount} words',
                        style: TextStyle(
                          fontSize: 11,
                          color: _themeMode.textColor.withOpacity(0.6),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _pageController.jumpToPage(index);
                        setState(() => _currentChapterIndex = index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTypographySettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _themeMode.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reading Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _themeMode.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Font Size Slider
                    Row(
                      children: [
                        Text('A',
                            style: TextStyle(
                                fontSize: 13, color: _themeMode.textColor)),
                        Expanded(
                          child: Slider(
                            value: _fontSize,
                            min: 13.0,
                            max: 26.0,
                            divisions: 13,
                            label: '${_fontSize.toInt()} pt',
                            onChanged: (val) {
                              setSheetState(() => _fontSize = val);
                              setState(() => _fontSize = val);
                              _savePreferences();
                            },
                          ),
                        ),
                        Text('A',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _themeMode.textColor)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Font Family Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['Serif', 'Sans', 'Monospace'].map((font) {
                        final isSelected = _fontFamily == font;
                        return ChoiceChip(
                          label: Text(font),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => _fontFamily = font);
                              setState(() => _fontFamily = font);
                              _savePreferences();
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Theme Mode Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: EpubThemeMode.values.map((mode) {
                        final isSelected = _themeMode == mode;
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() => _themeMode = mode);
                            setState(() => _themeMode = mode);
                            _savePreferences();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: mode.backgroundColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.shade400,
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: Text(
                              mode.label,
                              style: TextStyle(
                                color: mode.textColor,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Unpacking and loading EPUB eBook...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _epubBook == null || _epubBook!.chapters.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book, size: 56, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'No readable chapters found in EPUB.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _loadEpub();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalChapters = _epubBook!.chapters.length;
    final currentChapter = _epubBook!.chapters[_currentChapterIndex];
    final progressPercent =
        totalChapters > 0 ? ((_currentChapterIndex + 1) / totalChapters * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: _themeMode.backgroundColor,
      appBar: AppBar(
        backgroundColor: _themeMode.appBarColor,
        foregroundColor: _themeMode.textColor,
        elevation: 0.5,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              currentChapter.title,
              style: TextStyle(
                fontSize: 11,
                color: _themeMode.textColor.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'Typography & Theme',
            onPressed: _showTypographySettings,
          ),
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'Table of Contents',
            onPressed: _showTableOfContents,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalChapters,
        onPageChanged: (index) {
          setState(() => _currentChapterIndex = index);
        },
        itemBuilder: (context, chapterIdx) {
          final chapter = _epubBook!.chapters[chapterIdx];

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chapter Heading
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      chapter.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _fontSize + 5,
                        fontWeight: FontWeight.bold,
                        fontFamily: _getTextStyle().fontFamily,
                        color: _themeMode.textColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Paragraphs
                for (final p in chapter.paragraphs) ...[
                  Text(
                    p,
                    textAlign: TextAlign.justify,
                    style: _getTextStyle(),
                  ),
                  SizedBox(height: _fontSize * 0.75),
                ],

                const SizedBox(height: 36),
                Center(
                  child: Text(
                    '— End of Chapter ${chapterIdx + 1} —',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: _themeMode.textColor.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        color: _themeMode.appBarColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                tooltip: 'Previous Chapter',
                color: _themeMode.textColor,
                onPressed: _currentChapterIndex > 0
                    ? () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
              Expanded(
                child: Text(
                  'Chapter ${_currentChapterIndex + 1} of $totalChapters ($progressPercent%)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _themeMode.textColor.withOpacity(0.85),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                tooltip: 'Next Chapter',
                color: _themeMode.textColor,
                onPressed: _currentChapterIndex < totalChapters - 1
                    ? () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      }
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
