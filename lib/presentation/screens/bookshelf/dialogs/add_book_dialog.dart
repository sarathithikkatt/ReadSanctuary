import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/book_formats.dart';
import '../../../../core/constants/reading_statuses.dart';
import '../../../../core/utils/color_extractor.dart';
import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/local/database.dart';
import '../../../../data/services/shelf_widget_service.dart';
import '../../book_search/book_search_screen.dart';

/// Modal dialog for manually creating and placing a new book on a shelf.
class AddBookDialog extends StatefulWidget {
  final ShelfDao shelfDao;
  final BookDao bookDao;

  const AddBookDialog({
    super.key,
    required this.shelfDao,
    required this.bookDao,
  });

  static Future<void> show(
      BuildContext context, ShelfDao shelfDao, BookDao bookDao) async {
    final shelves = await shelfDao.getAllShelves();
    if (shelves.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a shelf first!')),
        );
      }
      return;
    }

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => AddBookDialog(
          shelfDao: shelfDao,
          bookDao: bookDao,
        ),
      );
    }
  }

  @override
  State<AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _pageCtrl = TextEditingController(text: '300');
  final _seriesNameCtrl = TextEditingController();
  final _seriesIdxCtrl = TextEditingController();

  String _format = BookFormat.paperback.id;
  String _status = ReadingStatus.tbr.id;
  String? _selectedShelfId;
  String? _pickedPdfPath;
  String? _pdfFileName;
  List<Shelf> _shelves = [];
  bool _isLoading = true;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _loadShelves();
  }

  Future<void> _loadShelves() async {
    final list = await widget.shelfDao.getAllShelves();
    if (mounted) {
      setState(() {
        _shelves = list;
        if (list.isNotEmpty) {
          _selectedShelfId = list.first.id;
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pageCtrl.dispose();
    _seriesNameCtrl.dispose();
    _seriesIdxCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final author = _authorCtrl.text.trim();
    if (title.isEmpty || _selectedShelfId == null) return;

    final bookId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    final spineColors = ColorExtractor.generateFromTitle(title);
    final pages = int.tryParse(_pageCtrl.text.trim()) ?? 250;
    final seriesIdx = double.tryParse(_seriesIdxCtrl.text.trim());

    // 1. Insert Book
    await widget.bookDao.insertBook(
      BooksCompanion.insert(
        id: bookId,
        title: title,
        authors: jsonEncode([author.isNotEmpty ? author : 'Unknown Author']),
        pageCount: drift.Value(pages),
        format: drift.Value(_format),
        status: _status,
        seriesName: drift.Value(
          _seriesNameCtrl.text.trim().isNotEmpty
              ? _seriesNameCtrl.text.trim()
              : null,
        ),
        seriesIndex: drift.Value(seriesIdx),
        pdfPath: drift.Value(_pickedPdfPath),
        lastReadPage: const drift.Value(1),
        spineColorHex: spineColors.spineColorHex,
        spineTextHex: spineColors.spineTextHex,
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 2. Insert ShelfItem
    final existingItems =
        await widget.shelfDao.getItemsForShelf(_selectedShelfId!);
    await widget.shelfDao.insertShelfItem(
      ShelfItemsCompanion.insert(
        id: _uuid.v4(),
        shelfId: _selectedShelfId!,
        itemType: 'book',
        bookId: drift.Value(bookId),
        positionIndex: existingItems.length,
      ),
    );

    ShelfWidgetService(shelfDao: widget.shelfDao).updateWidget();

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Add Book to Shelf'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Switch to online search
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Search Online / Free Books'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          BookSearchScreen(initialShelfId: _selectedShelfId),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Book Title *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorCtrl,
              decoration: const InputDecoration(labelText: 'Author *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Page Count'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _seriesNameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Series (optional)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _seriesIdxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Vol # (e.g. 1.5)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: BookFormat.values
                  .map((f) =>
                      DropdownMenuItem(value: f.id, child: Text(f.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _format = val);
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: ReadingStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 8),
            // Upload PDF Option
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: OutlinedButton.icon(
                icon: Icon(_pickedPdfPath != null
                    ? Icons.picture_as_pdf
                    : Icons.upload_file),
                label: Text(
                  _pdfFileName != null
                      ? 'PDF: $_pdfFileName'
                      : 'Attach PDF File (eBook)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () async {
                  final storage = ImageStorageHelper();
                  final path = await storage.pickAndSavePdf();
                  if (path != null && mounted) {
                    setState(() {
                      _pickedPdfPath = path;
                      _pdfFileName = path.split('/').last;
                      _format = BookFormat.ebook.id;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedShelfId,
              decoration: const InputDecoration(labelText: 'Target Shelf'),
              items: _shelves
                  .map(
                      (s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedShelfId = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add Book'),
        ),
      ],
    );
  }
}
