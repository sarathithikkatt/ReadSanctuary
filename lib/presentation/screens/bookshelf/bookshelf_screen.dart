import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/color_extractor.dart';
import '../../../data/local/database.dart';
import '../book_detail/book_detail_screen.dart';
import 'shelf_share_exporter.dart';
import 'widgets/book_cover_tilt_widget.dart';
import 'widgets/book_spine_25d_widget.dart';
import 'widgets/shelf_prop_widget.dart';
import 'widgets/wooden_shelf_row.dart';

/// Main visual bookshelf screen rendering 2.5D wooden shelves, reactive database updates,
/// book spines, tilted covers, and props.
class BookshelfScreen extends ConsumerStatefulWidget {
  const BookshelfScreen({super.key});

  @override
  ConsumerState<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends ConsumerState<BookshelfScreen> {
  final GlobalKey _shelfExportKey = GlobalKey();
  bool _isReorderMode = false;
  static const _uuid = Uuid();
  late final Stream<List<Shelf>> _shelvesStream;

  @override
  void initState() {
    super.initState();
    _shelvesStream = ref.read(shelfDaoProvider).watchAllShelves();
  }

  @override
  Widget build(BuildContext context) {
    final shelfDao = ref.watch(shelfDaoProvider);
    final bookDao = ref.watch(bookDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShelfCraft', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isReorderMode ? Icons.done : Icons.swap_horiz),
            tooltip: _isReorderMode ? 'Done Reordering' : 'Reorder Books',
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos_outlined),
            tooltip: 'Add Shelf',
            onPressed: () => _showAddShelfDialog(shelfDao),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Bookshelf',
            onPressed: () => ShelfShareExporter.exportAndShare(
              repaintBoundaryKey: _shelfExportKey,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        onPressed: () => _showAddBookDialog(shelfDao, bookDao),
      ),
      body: RepaintBoundary(
        key: _shelfExportKey,
        child: StreamBuilder<List<Shelf>>(
          stream: _shelvesStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final shelves = snapshot.data ?? [];
            if (shelves.isEmpty) {
              return _buildEmptyState(shelfDao);
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80.0),
              itemCount: shelves.length,
              itemBuilder: (context, index) {
                final shelf = shelves[index];
                return _ShelfSection(
                  shelf: shelf,
                  shelfDao: shelfDao,
                  bookDao: bookDao,
                  isReorderable: _isReorderMode,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ShelfDao shelfDao) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Your shelf is waiting for stories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Add books manually, scan barcodes, or import from CSV.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create a Shelf'),
              onPressed: () => _showAddShelfDialog(shelfDao),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddShelfDialog(ShelfDao shelfDao) async {
    final nameCtrl = TextEditingController(text: 'My Bookshelf');
    String woodTheme = 'oak';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Shelf'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Shelf Name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: woodTheme,
                decoration: const InputDecoration(labelText: 'Wood Style'),
                items: const [
                  DropdownMenuItem(value: 'oak', child: Text('Classic Oak')),
                  DropdownMenuItem(value: 'walnut', child: Text('Dark Walnut')),
                  DropdownMenuItem(value: 'mahogany', child: Text('Rich Mahogany')),
                  DropdownMenuItem(value: 'birch', child: Text('Light Birch')),
                ],
                onChanged: (val) {
                  if (val != null) setDialogState(() => woodTheme = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isNotEmpty) {
                  final allShelves = await shelfDao.getAllShelves();
                  await shelfDao.insertShelf(
                    ShelvesCompanion.insert(
                      id: _uuid.v4(),
                      name: name,
                      woodThemeId: drift.Value(woodTheme),
                      sortOrder: allShelves.length,
                    ),
                  );
                }
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Create Shelf'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddBookDialog(ShelfDao shelfDao, BookDao bookDao) async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pageCtrl = TextEditingController(text: '300');
    final seriesNameCtrl = TextEditingController();
    final seriesIdxCtrl = TextEditingController();
    String format = 'paperback';
    String status = 'tbr';

    final shelves = await shelfDao.getAllShelves();
    if (shelves.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please create a shelf first!')),
        );
      }
      return;
    }
    String selectedShelfId = shelves.first.id;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Book to Shelf'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Book Title *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Page Count'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: seriesNameCtrl,
                        decoration: const InputDecoration(labelText: 'Series (optional)'),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
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
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedShelfId,
                  decoration: const InputDecoration(labelText: 'Target Shelf'),
                  items: shelves
                      .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedShelfId = val);
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
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final author = authorCtrl.text.trim();
                if (title.isEmpty) return;

                final bookId = _uuid.v4();
                final now = DateTime.now().millisecondsSinceEpoch;
                final spineColors = ColorExtractor.generateFromTitle(title);
                final pages = int.tryParse(pageCtrl.text.trim()) ?? 250;
                final seriesIdx = double.tryParse(seriesIdxCtrl.text.trim());

                // 1. Insert Book
                await bookDao.insertBook(
                  BooksCompanion.insert(
                    id: bookId,
                    title: title,
                    authors: jsonEncode([author.isNotEmpty ? author : 'Unknown Author']),
                    pageCount: drift.Value(pages),
                    format: drift.Value(format),
                    status: status,
                    seriesName: drift.Value(seriesNameCtrl.text.trim().isNotEmpty ? seriesNameCtrl.text.trim() : null),
                    seriesIndex: drift.Value(seriesIdx),
                    spineColorHex: spineColors.spineColorHex,
                    spineTextHex: spineColors.spineTextHex,
                    createdAt: now,
                    updatedAt: now,
                  ),
                );

                // 2. Insert ShelfItem
                final existingItems = await shelfDao.getItemsForShelf(selectedShelfId);
                await shelfDao.insertShelfItem(
                  ShelfItemsCompanion.insert(
                    id: _uuid.v4(),
                    shelfId: selectedShelfId,
                    itemType: 'book',
                    bookId: drift.Value(bookId),
                    positionIndex: existingItems.length,
                  ),
                );

                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Add Book'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfSection extends StatefulWidget {
  final Shelf shelf;
  final ShelfDao shelfDao;
  final BookDao bookDao;
  final bool isReorderable;

  const _ShelfSection({
    required this.shelf,
    required this.shelfDao,
    required this.bookDao,
    required this.isReorderable,
  });

  @override
  State<_ShelfSection> createState() => _ShelfSectionState();
}

class _ShelfSectionState extends State<_ShelfSection> {
  static const _uuid = Uuid();
  late final Stream<List<ShelfItem>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _itemsStream = widget.shelfDao.watchItemsForShelf(widget.shelf.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 8.0, 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.shelf.name,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (val) => _handleShelfAction(context, val),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add_prop',
                    child: ListTile(
                      leading: Icon(Icons.eco_outlined),
                      title: Text('Add Prop / Spacer'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'wood_theme',
                    child: ListTile(
                      leading: Icon(Icons.palette_outlined),
                      title: Text('Change Wood Style'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete Shelf', style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        StreamBuilder<List<ShelfItem>>(
          stream: _itemsStream,
          builder: (context, itemSnapshot) {
            final items = itemSnapshot.data ?? [];
            return FutureBuilder<List<Widget>>(
              future: _buildShelfWidgets(context, items),
              builder: (context, widgetSnapshot) {
                final itemWidgets = widgetSnapshot.data ?? [];
                return WoodenShelfRow(
                  shelfId: widget.shelf.id,
                  shelfName: widget.shelf.name,
                  woodThemeId: widget.shelf.woodThemeId,
                  items: itemWidgets,
                  isReorderable: widget.isReorderable,
                  onReorder: (oldIdx, newIdx) async {
                    if (oldIdx < newIdx) newIdx -= 1;
                    final itemIds = items.map((e) => e.id).toList();
                    final moved = itemIds.removeAt(oldIdx);
                    itemIds.insert(newIdx, moved);
                    await widget.shelfDao.reorderShelfItems(widget.shelf.id, itemIds);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<List<Widget>> _buildShelfWidgets(BuildContext context, List<ShelfItem> items) async {
    final widgets = <Widget>[];

    for (final item in items) {
      if (item.itemType == 'prop' && item.propAssetId != null) {
        widgets.add(ShelfPropWidget(
          key: ValueKey(item.id),
          propAssetId: item.propAssetId!,
        ));
      } else if (item.itemType == 'gap') {
        widgets.add(ShelfPropWidget(
          key: ValueKey(item.id),
          propAssetId: 'gap',
        ));
      } else if (item.bookId != null) {
        final book = await widget.bookDao.getBookById(item.bookId!);
        if (book != null) {
          void openDetail() {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookDetailScreen(bookId: book.id),
              ),
            );
          }

          if (item.displayMode == 'spine') {
            widgets.add(BookSpine25DWidget(
              key: ValueKey(item.id),
              id: book.id,
              title: book.title,
              pageCount: book.pageCount,
              format: book.format,
              spineColorHex: book.spineColorHex,
              spineTextHex: book.spineTextHex,
              customSpineAbsolutePath: book.customSpinePath,
              onTap: openDetail,
            ));
          } else {
            widgets.add(BookCoverTiltWidget(
              key: ValueKey(item.id),
              id: book.id,
              title: book.title,
              coverUrl: book.coverPath,
              spineColorHex: book.spineColorHex,
              spineTextHex: book.spineTextHex,
              displayMode: item.displayMode,
              onTap: openDetail,
            ));
          }
        }
      }
    }

    return widgets;
  }

  void _handleShelfAction(BuildContext context, String action) {
    if (action == 'add_prop') {
      _showAddPropDialog(context);
    } else if (action == 'wood_theme') {
      _showWoodThemeDialog(context);
    } else if (action == 'delete') {
      _confirmDeleteShelf(context);
    }
  }

  void _showAddPropDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Add Prop or Spacer to Shelf',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.eco, color: Colors.green),
              title: const Text('Monstera Plant'),
              onTap: () => _insertProp(context, 'plant_monstera', 'prop'),
            ),
            ListTile(
              leading: const Icon(Icons.park, color: Colors.teal),
              title: const Text('Succulent Pot'),
              onTap: () => _insertProp(context, 'plant_succulent', 'prop'),
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.amber),
              title: const Text('Amber Candle'),
              onTap: () => _insertProp(context, 'candle_amber', 'prop'),
            ),
            ListTile(
              leading: const Icon(Icons.coffee, color: Colors.brown),
              title: const Text('Coffee Mug'),
              onTap: () => _insertProp(context, 'cup_coffee', 'prop'),
            ),
            ListTile(
              leading: const Icon(Icons.space_bar, color: Colors.blueGrey),
              title: const Text('Empty Spacer Gap'),
              onTap: () => _insertProp(context, 'gap', 'gap'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _insertProp(BuildContext context, String propId, String type) async {
    Navigator.of(context).pop();
    final existing = await widget.shelfDao.getItemsForShelf(widget.shelf.id);
    await widget.shelfDao.insertShelfItem(
      ShelfItemsCompanion.insert(
        id: _uuid.v4(),
        shelfId: widget.shelf.id,
        itemType: type,
        propAssetId: drift.Value(propId),
        positionIndex: existing.length,
      ),
    );
  }

  void _showWoodThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Wood Style'),
        children: [
          SimpleDialogOption(
            onPressed: () => _updateWoodTheme(context, 'oak'),
            child: const Text('Classic Oak (Warm Gold)'),
          ),
          SimpleDialogOption(
            onPressed: () => _updateWoodTheme(context, 'walnut'),
            child: const Text('Dark Walnut (Deep Brown)'),
          ),
          SimpleDialogOption(
            onPressed: () => _updateWoodTheme(context, 'mahogany'),
            child: const Text('Rich Mahogany (Reddish Timber)'),
          ),
          SimpleDialogOption(
            onPressed: () => _updateWoodTheme(context, 'birch'),
            child: const Text('Light Birch (Pale Sand)'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateWoodTheme(BuildContext context, String themeId) async {
    Navigator.of(context).pop();
    await widget.shelfDao.updateShelf(widget.shelf.copyWith(woodThemeId: themeId));
  }

  void _confirmDeleteShelf(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shelf'),
        content: Text('Delete "${widget.shelf.name}" and remove all items on it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await widget.shelfDao.deleteShelf(widget.shelf.id);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
