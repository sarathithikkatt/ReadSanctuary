import '../entities/book_note_entity.dart';
import '../entities/reading_session_entity.dart';

/// Abstract repository interface for Reading Sessions and Notes.
abstract class ReadingSessionRepository {
  /// Watches reading sessions for a specific book.
  Stream<List<ReadingSessionEntity>> watchSessionsForBook(String bookId);

  /// Watches all reading sessions across all books.
  Stream<List<ReadingSessionEntity>> watchAllSessions();

  /// Logs a completed reading session.
  Future<void> logSession(ReadingSessionEntity session);

  /// Deletes a reading session by ID.
  Future<void> deleteSession(String sessionId);

  /// Watches all notes for a given book.
  Stream<List<BookNoteEntity>> watchNotesForBook(String bookId);

  /// Adds or updates a note.
  Future<void> saveNote(BookNoteEntity note);

  /// Deletes a note by ID.
  Future<void> deleteNote(String noteId);
}
