import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import 'library_filter_provider.dart';

/// Reactive provider yielding books filtered and sorted according to LibraryFilterState.
final filteredBooksProvider = StreamProvider<List<Book>>((ref) {
  final bookDao = ref.watch(bookDaoProvider);
  final shelfDao = ref.watch(shelfDaoProvider);
  final filter = ref.watch(libraryFilterProvider);

  // If FTS search query is present, use FTS5 stream with graceful error fallback
  final baseStream = filter.searchQuery.trim().isNotEmpty
      ? bookDao
          .watchSearchBooksFts(filter.searchQuery.trim())
          .handleError((_) => <Book>[])
      : bookDao.watchAllBooks();

  return baseStream.asyncMap((books) async {
    var result = List<Book>.from(books);

    // 1. Filter by Reading Status
    if (filter.status != null && filter.status!.isNotEmpty) {
      result = result.where((b) => b.status == filter.status).toList();
    }

    // 2. Filter by Shelf (Category)
    if (filter.shelfId != null && filter.shelfId!.isNotEmpty) {
      final shelfItems = await shelfDao.getItemsForShelf(filter.shelfId!);
      final bookIdsOnShelf = shelfItems
          .where((i) => i.bookId != null)
          .map((i) => i.bookId!)
          .toSet();
      result = result.where((b) => bookIdsOnShelf.contains(b.id)).toList();
    }

    // 3. Filter by Minimum Rating
    if (filter.minRating != null && filter.minRating! > 0) {
      result = result
          .where((b) => b.rating != null && b.rating! >= filter.minRating!)
          .toList();
    }

    // 4. Sort
    result.sort((a, b) {
      int cmp = 0;
      switch (filter.sortBy) {
        case LibrarySortField.lastRead:
          final aTime = a.lastReadAt ?? a.updatedAt;
          final bTime = b.lastReadAt ?? b.updatedAt;
          cmp = aTime.compareTo(bTime);
          break;
        case LibrarySortField.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case LibrarySortField.author:
          cmp = a.authors.toLowerCase().compareTo(b.authors.toLowerCase());
          break;
        case LibrarySortField.progress:
          final aProg = a.pageCount > 0 ? a.lastReadPage / a.pageCount : 0.0;
          final bProg = b.pageCount > 0 ? b.lastReadPage / b.pageCount : 0.0;
          cmp = aProg.compareTo(bProg);
          break;
        case LibrarySortField.dateAdded:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        case LibrarySortField.rating:
          final aR = a.rating ?? 0.0;
          final bR = b.rating ?? 0.0;
          cmp = aR.compareTo(bR);
          break;
      }
      return filter.ascending ? cmp : -cmp;
    });

    return result;
  });
});
