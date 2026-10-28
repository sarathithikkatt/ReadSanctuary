import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
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
            icon: const Icon(Icons.share),
            tooltip: 'Share Bookshelf',
            onPressed: () => ShelfShareExporter.exportAndShare(
              repaintBoundaryKey: _shelfExportKey,
            ),
          ),
        ],
      ),
      body: RepaintBoundary(
        key: _shelfExportKey,
        child: StreamBuilder<List<Shelf>>(
          stream: shelfDao.watchAllShelves(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final shelves = snapshot.data ?? [];
            if (shelves.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
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

  Widget _buildEmptyState() {
    return Center(
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
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _ShelfSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
          child: Text(
            shelf.name,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        StreamBuilder<List<ShelfItem>>(
          stream: shelfDao.watchItemsForShelf(shelf.id),
          builder: (context, itemSnapshot) {
            final items = itemSnapshot.data ?? [];
            return FutureBuilder<List<Widget>>(
              future: _buildShelfWidgets(items),
              builder: (context, widgetSnapshot) {
                final itemWidgets = widgetSnapshot.data ?? [];
                return WoodenShelfRow(
                  shelfId: shelf.id,
                  shelfName: shelf.name,
                  woodThemeId: shelf.woodThemeId,
                  items: itemWidgets,
                  isReorderable: isReorderable,
                  onReorder: (oldIdx, newIdx) async {
                    if (oldIdx < newIdx) newIdx -= 1;
                    final itemIds = items.map((e) => e.id).toList();
                    final moved = itemIds.removeAt(oldIdx);
                    itemIds.insert(newIdx, moved);
                    await shelfDao.reorderShelfItems(shelf.id, itemIds);
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<List<Widget>> _buildShelfWidgets(List<ShelfItem> items) async {
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
        final book = await bookDao.getBookById(item.bookId!);
        if (book != null) {
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
            ));
          }
        }
      }
    }

    return widgets;
  }
}
