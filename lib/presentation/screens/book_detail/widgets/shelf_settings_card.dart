import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';

/// Card allowing the user to toggle shelf display mode between Front Cover and 2.5D Spine.
class ShelfSettingsCard extends StatelessWidget {
  final Book book;
  final ShelfDao shelfDao;

  const ShelfSettingsCard({
    super.key,
    required this.book,
    required this.shelfDao,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ShelfItem?>(
      future: shelfDao.getItemByBookId(book.id),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        final isCoverOut = item.displayMode == 'cover_out';

        return Card(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        isCoverOut ? Icons.image : Icons.view_column,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shelf Display Style',
                              style: TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              isCoverOut
                                  ? 'Front Cover View'
                                  : '2.5D Spine View',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isCoverOut,
                  onChanged: (val) async {
                    await shelfDao.updateShelfItem(
                      item.copyWith(displayMode: val ? 'cover_out' : 'spine'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
