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
    return StreamBuilder<ShelfItem?>(
      stream: shelfDao.watchItemByBookId(book.id),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        final isCoverOut = item.displayMode == 'cover_out';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B1D2F).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCoverOut ? Icons.image_outlined : Icons.view_column_outlined,
                        color: const Color(0xFF6B1D2F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shelf Display Style',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF222222),
                            ),
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
                activeColor: const Color(0xFF6B1D2F),
                onChanged: (val) async {
                  await shelfDao.updateShelfItem(
                    item.copyWith(displayMode: val ? 'cover_out' : 'spine'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
