import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/database.dart';
import '../../../../data/services/revenuecat_service.dart';
import '../../../../data/services/shelf_widget_service.dart';
import '../../book_detail/book_detail_screen.dart';
import '../dialogs/prop_selection_sheet.dart';
import '../dialogs/shelf_theme_dialogs.dart';
import 'book_cover_tilt_widget.dart';
import 'book_spine_25d_widget.dart';
import 'interactive_3d_book_viewer.dart';
import 'shelf_prop_widget.dart';
import 'wooden_shelf_row.dart';

/// Renders a single bookshelf section:
/// Header title with overflow actions, followed by the 2.5D wooden shelf row.
class ShelfSection extends ConsumerStatefulWidget {
  final Shelf shelf;
  final ShelfDao shelfDao;
  final BookDao bookDao;
  final bool isReorderable;

  const ShelfSection({
    super.key,
    required this.shelf,
    required this.shelfDao,
    required this.bookDao,
    required this.isReorderable,
  });

  @override
  ConsumerState<ShelfSection> createState() => _ShelfSectionState();
}

class _ShelfSectionState extends ConsumerState<ShelfSection> {
  late final Stream<List<ShelfItemWithBook>> _itemsStream;

  @override
  void initState() {
    super.initState();
    // High-performance joined stream (eliminates N+1 database queries)
    _itemsStream = widget.shelfDao.watchItemsWithBooksForShelf(widget.shelf.id);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShelfHeader(context),
        StreamBuilder<List<ShelfItemWithBook>>(
          stream: _itemsStream,
          builder: (context, snapshot) {
            final allItems = snapshot.data ?? [];
            final displayableItems = allItems
                .where((entry) =>
                    entry.item.itemType == 'prop' ||
                    entry.item.itemType == 'gap' ||
                    entry.book != null)
                .toList();
            final itemWidgets = _buildShelfWidgets(context, displayableItems);

            return WoodenShelfRow(
              shelfId: widget.shelf.id,
              shelfName: widget.shelf.name,
              woodThemeId: widget.shelf.woodThemeId,
              wallThemeId: widget.shelf.wallThemeId,
              items: itemWidgets,
              isReorderable: widget.isReorderable,
              onReorder: (oldIdx, newIdx) =>
                  _handleReorder(displayableItems, oldIdx, newIdx),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShelfHeader(BuildContext context) {
    return Padding(
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
            onSelected: (action) => _handleShelfAction(context, action),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'pin_widget',
                child: ListTile(
                  leading: Icon(Icons.widgets_outlined),
                  title: Text('Pin to Home Widget'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'add_prop',
                child: ListTile(
                  leading: Icon(Icons.eco_outlined),
                  title: Text('Add Prop / Spacer'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'wood_theme',
                child: ListTile(
                  leading: Icon(Icons.palette_outlined),
                  title: Text('Change Wood Style'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'wall_theme',
                child: ListTile(
                  leading: Icon(Icons.wallpaper_outlined),
                  title: Text('Change Background Theme'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: Colors.red),
                  title:
                      Text('Delete Shelf', style: TextStyle(color: Colors.red)),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildShelfWidgets(
      BuildContext context, List<ShelfItemWithBook> items) {
    final widgets = <Widget>[];

    for (final entry in items) {
      final item = entry.item;
      final book = entry.book;

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
      } else if (book != null) {
        void openDetail() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(bookId: book.id),
            ),
          );
        }

        void open3dInspect() {
          Interactive3dBookViewer.show(context, book: book);
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
            onLongPress: open3dInspect,
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
            onLongPress: open3dInspect,
          ));
        }
      }
    }

    return widgets;
  }

  Future<void> _handleReorder(
      List<ShelfItemWithBook> items, int oldIdx, int newIdx) async {
    if (oldIdx < newIdx) newIdx -= 1;
    if (oldIdx == newIdx) return;
    final itemIds = items.map((e) => e.item.id).toList();
    if (oldIdx < 0 || oldIdx >= itemIds.length) return;
    newIdx = newIdx.clamp(0, itemIds.length - 1);
    final moved = itemIds.removeAt(oldIdx);
    itemIds.insert(newIdx, moved);
    await widget.shelfDao.reorderShelfItems(widget.shelf.id, itemIds);
    ShelfWidgetService(shelfDao: widget.shelfDao).updateWidget();
  }

  Future<void> _handleShelfAction(BuildContext context, String action) async {
    switch (action) {
      case 'pin_widget':
        final service = ShelfWidgetService(shelfDao: widget.shelfDao);
        await service.setSelectedShelfId(widget.shelf.id);
        await service.updateWidget(targetShelf: widget.shelf);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Pinned "${widget.shelf.name}" to Home Screen Widget!'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        break;
      case 'add_prop':
        final isProForProp = ref.read(isProUserProvider);
        await PropSelectionSheet.show(
          context,
          widget.shelf.id,
          widget.shelfDao,
          isProUser: isProForProp,
        );
        ShelfWidgetService(shelfDao: widget.shelfDao).updateWidget();
        break;
      case 'wood_theme':
        await ShelfThemeDialogs.showWoodThemeDialog(
          context: context,
          shelf: widget.shelf,
          shelfDao: widget.shelfDao,
        );
        ShelfWidgetService(shelfDao: widget.shelfDao).updateWidget();
        break;
      case 'wall_theme':
        final isProForWall = ref.read(isProUserProvider);
        await ShelfThemeDialogs.showWallThemeDialog(
          context: context,
          shelf: widget.shelf,
          shelfDao: widget.shelfDao,
          isProUser: isProForWall,
        );
        ShelfWidgetService(shelfDao: widget.shelfDao).updateWidget();
        break;
      case 'delete':
        await ShelfThemeDialogs.showDeleteShelfDialog(
          context: context,
          shelf: widget.shelf,
          shelfDao: widget.shelfDao,
        );
        ShelfWidgetService(shelfDao: widget.shelfDao).updateWidget();
        break;
    }
  }
}
