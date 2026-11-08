import 'package:flutter/material.dart';

import '../../../data/local/daos/shelf_dao.dart';
import '../../screens/bookshelf/widgets/book_cover_tilt_widget.dart';
import '../../screens/bookshelf/widgets/book_spine_25d_widget.dart';
import '../../screens/bookshelf/widgets/shelf_prop_widget.dart';
import '../../screens/bookshelf/widgets/wooden_shelf_row.dart';

/// Specialized widget rendered offscreen to produce the Home Screen AppWidget preview.
/// Renders the shelf wall texture, 2.5D book spines, custom covers, props, and wooden shelf plank.
class ShelfHomeWidgetView extends StatelessWidget {
  final String shelfName;
  final String woodThemeId;
  final String wallThemeId;
  final List<ShelfItemWithBook> items;
  final double width;
  final double height;

  const ShelfHomeWidgetView({
    super.key,
    required this.shelfName,
    this.woodThemeId = 'oak',
    this.wallThemeId = 'warm_cream',
    this.items = const [],
    this.width = 400.0,
    this.height = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final woodTheme = ShelfWoodTheme.fromId(woodThemeId);
    final wallTheme = ShelfWallTheme.fromId(wallThemeId);

    final displayableItems = items
        .where((entry) =>
            entry.item.itemType == 'prop' ||
            entry.item.itemType == 'gap' ||
            entry.book != null)
        .toList();

    final bookCount = displayableItems
        .where((entry) => entry.item.itemType == 'book' && entry.book != null)
        .length;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: width,
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: wallTheme.fallbackColor,
          borderRadius: BorderRadius.circular(16.0),
          image: wallTheme.assetPath != null
              ? DecorationImage(
                  image: AssetImage(wallTheme.assetPath!),
                  fit: BoxFit.cover,
                  opacity: 0.9,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Header: Shelf Name & ShelfCraft Brand Tag
            Positioned(
              top: 10.0,
              left: 14.0,
              right: 14.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          size: 15.0,
                          color:
                              wallTheme.isDark ? Colors.white70 : Colors.black87,
                        ),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            shelfName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                              color: wallTheme.isDark
                                  ? Colors.white
                                  : Colors.black87,
                              shadows: [
                                Shadow(
                                  color: wallTheme.isDark
                                      ? Colors.black54
                                      : Colors.white70,
                                  blurRadius: 2.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (bookCount > 0) ...[
                          const SizedBox(width: 6.0),
                          Text(
                            '($bookCount)',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              color: wallTheme.isDark
                                  ? Colors.white60
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: (wallTheme.isDark ? Colors.white : Colors.black)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      'ShelfCraft',
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: wallTheme.isDark
                            ? Colors.white70
                            : const Color(0xFF4A3428),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Shelf content: books and props resting on shelf
            Positioned(
              left: 12.0,
              right: 12.0,
              bottom: 30.0,
              top: 36.0,
              child: displayableItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 32.0,
                            color: wallTheme.isDark
                                ? Colors.white38
                                : Colors.brown.withOpacity(0.35),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            'Empty shelf • Tap to add books',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontStyle: FontStyle.italic,
                              color: wallTheme.isDark
                                  ? Colors.white54
                                  : Colors.brown.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: _buildShelfItemWidgets(displayableItems),
                      ),
                    ),
            ),

            // Wooden shelf plank at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 32.0,
              child: CustomPaint(
                painter: WoodenShelfPainter(
                  woodTheme: woodTheme,
                  topSurfaceDepth: 10.0,
                  fasciaHeight: 14.0,
                  shadowDepth: 8.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildShelfItemWidgets(List<ShelfItemWithBook> items) {
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

    return widgets;
  }
}
