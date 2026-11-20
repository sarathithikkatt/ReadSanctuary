import 'package:flutter/material.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../data/local/database.dart';
import '../../../widgets/cover_image_card.dart';
import '../../book_detail/book_detail_screen.dart';

/// Mihon-style high-density library grid view rendering responsive cover cards,
/// reading progress badges, and fast tap interactions.
class LibraryGridView extends StatelessWidget {
  final List<Book> books;
  final bool isGridView;

  const LibraryGridView({
    super.key,
    required this.books,
    this.isGridView = true,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'No books match the current filter.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    if (!isGridView) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: books.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final book = books[index];
          final progress = book.pageCount > 0
              ? (book.lastReadPage / book.pageCount).clamp(0.0, 1.0)
              : 0.0;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 6),
            leading: CoverImageCard(
              coverPath: book.coverPath,
              title: book.title,
              author: Formatters.formatAuthors(book.authors),
              spineColorHex: book.spineColorHex,
              spineTextHex: book.spineTextHex,
              width: 44,
              height: 64,
              borderRadius: 4,
            ),
            title: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.formatAuthors(book.authors),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookDetailScreen(bookId: book.id),
              ),
            ),
          );
        },
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.58,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        final progress = book.pageCount > 0
            ? (book.lastReadPage / book.pageCount).clamp(0.0, 1.0)
            : 0.0;

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BookDetailScreen(bookId: book.id),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    CoverImageCard(
                      coverPath: book.coverPath,
                      title: book.title,
                      author: Formatters.formatAuthors(book.authors),
                      spineColorHex: book.spineColorHex,
                      spineTextHex: book.spineTextHex,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: 8,
                    ),
                    if (book.status == 'finished')
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.check,
                              size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
              if (progress > 0 && book.status != 'finished') ...[
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF8A5D3B)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
