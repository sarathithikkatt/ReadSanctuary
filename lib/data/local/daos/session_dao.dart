import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/reading_sessions.dart';
import '../tables/book_notes.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [ReadingSessions, BookNotes])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  Stream<List<ReadingSession>> watchSessionsForBook(String bookId) {
    return (select(readingSessions)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<ReadingSession>> getSessionsForBook(String bookId) {
    return (select(readingSessions)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Stream<List<ReadingSession>> watchAllSessions() {
    return (select(readingSessions)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<ReadingSession>> getAllSessions() {
    return (select(readingSessions)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> insertSession(Insertable<ReadingSession> session) {
    return into(readingSessions).insert(session);
  }

  Future<int> deleteSession(String id) {
    return (delete(readingSessions)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<BookNote>> watchNotesForBook(String bookId) {
    return (select(bookNotes)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<BookNote>> getNotesForBook(String bookId) {
    return (select(bookNotes)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
          ]))
        .get();
  }

  Future<int> insertNote(Insertable<BookNote> note) {
    return into(bookNotes).insert(note);
  }

  Future<bool> updateNote(Insertable<BookNote> note) {
    return update(bookNotes).replace(note);
  }

  Future<int> deleteNote(String id) {
    return (delete(bookNotes)..where((t) => t.id.equals(id))).go();
  }

  /// Streams all bookmarks for a specific book ordered ascending by page number.
  Stream<List<BookNote>> watchBookmarksForBook(String bookId) {
    return (select(bookNotes)
          ..where((t) => t.bookId.equals(bookId) & t.noteType.equals('bookmark'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.pageNumber, mode: OrderingMode.asc)
          ]))
        .watch();
  }

  /// Fetches all bookmarks for a specific book ordered ascending by page number.
  Future<List<BookNote>> getBookmarksForBook(String bookId) {
    return (select(bookNotes)
          ..where((t) => t.bookId.equals(bookId) & t.noteType.equals('bookmark'))
          ..orderBy([
            (t) => OrderingTerm(expression: t.pageNumber, mode: OrderingMode.asc)
          ]))
        .get();
  }

  /// Deletes a bookmark for a specific book and page number.
  Future<int> deleteBookmarkForPage(String bookId, int pageNumber) {
    return (delete(bookNotes)
          ..where((t) =>
              t.bookId.equals(bookId) &
              t.noteType.equals('bookmark') &
              t.pageNumber.equals(pageNumber)))
        .go();
  }
}
