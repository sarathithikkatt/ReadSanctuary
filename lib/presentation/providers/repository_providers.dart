import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../data/repositories/reading_session_repository_impl.dart';
import '../../data/repositories/shelf_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/reading_session_repository.dart';
import '../../domain/repositories/shelf_repository.dart';

/// Provider for BookRepository.
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepositoryImpl(
    bookDao: ref.watch(bookDaoProvider),
  );
});

/// Provider for ShelfRepository.
final shelfRepositoryProvider = Provider<ShelfRepository>((ref) {
  return ShelfRepositoryImpl(
    shelfDao: ref.watch(shelfDaoProvider),
  );
});

/// Provider for ReadingSessionRepository.
final readingSessionRepositoryProvider =
    Provider<ReadingSessionRepository>((ref) {
  return ReadingSessionRepositoryImpl(
    sessionDao: ref.watch(sessionDaoProvider),
  );
});

/// Reactive stream provider for all active books.
final allBooksStreamProvider = StreamProvider<List<dynamic>>((ref) {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.watchAllBooks();
});

/// Reactive stream provider for all shelves.
final allShelvesStreamProvider = StreamProvider<List<dynamic>>((ref) {
  final repo = ref.watch(shelfRepositoryProvider);
  return repo.watchShelves();
});
