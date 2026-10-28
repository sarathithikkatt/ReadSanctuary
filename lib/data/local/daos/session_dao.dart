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
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<ReadingSession>> getSessionsForBook(String bookId) {
    return (select(readingSessions)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<ReadingSession>> getAllSessions() {
    return (select(readingSessions)
          ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)]))
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
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<List<BookNote>> getNotesForBook(String bookId) {
    return (select(bookNotes)
          ..where((t) => t.bookId.equals(bookId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Future<int> insertNote(Insertable<BookNote> note) {
    return into(bookNotes).insert(note);
  }

  Future<int> deleteNote(String id) {
    return (delete(bookNotes)..where((t) => t.id.equals(id))).go();
  }
}
