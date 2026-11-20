import 'dart:async';
import '../../domain/entities/book_note_entity.dart';
import '../../domain/entities/reading_session_entity.dart';
import '../../domain/repositories/reading_session_repository.dart';
import '../local/daos/session_dao.dart';
import '../local/mappers/entity_mappers.dart';

/// Concrete ReadingSessionRepository delegating to Drift SessionDao.
class ReadingSessionRepositoryImpl implements ReadingSessionRepository {
  final SessionDao _sessionDao;

  ReadingSessionRepositoryImpl({required SessionDao sessionDao})
      : _sessionDao = sessionDao;

  @override
  Stream<List<ReadingSessionEntity>> watchSessionsForBook(String bookId) {
    return _sessionDao.watchSessionsForBook(bookId).map(
          (sessions) => sessions.map((s) => s.toEntity()).toList(),
        );
  }

  @override
  Stream<List<ReadingSessionEntity>> watchAllSessions() {
    return _sessionDao.watchAllSessions().map(
          (sessions) => sessions.map((s) => s.toEntity()).toList(),
        );
  }

  @override
  Future<void> logSession(ReadingSessionEntity session) async {
    await _sessionDao.insertSession(session.toCompanion());
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _sessionDao.deleteSession(sessionId);
  }

  @override
  Stream<List<BookNoteEntity>> watchNotesForBook(String bookId) {
    return _sessionDao.watchNotesForBook(bookId).map(
          (notes) => notes.map((n) => n.toEntity()).toList(),
        );
  }

  @override
  Future<void> saveNote(BookNoteEntity note) async {
    final existing = await _sessionDao.getNotesForBook(note.bookId);
    final match = existing.where((n) => n.id == note.id).firstOrNull;
    if (match == null) {
      await _sessionDao.insertNote(note.toCompanion());
    } else {
      await _sessionDao.updateNote(note.toCompanion());
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    await _sessionDao.deleteNote(noteId);
  }
}
