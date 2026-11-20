/// Pure Dart domain entity representing a note or quote attached to a book.
class BookNoteEntity {
  final String id;
  final String bookId;
  final String noteType; // 'quote', 'thought', 'character'
  final String content; // Text or OCR-scanned quote
  final int? pageNumber;
  final int createdAt; // Unix epoch ms

  const BookNoteEntity({
    required this.id,
    required this.bookId,
    this.noteType = 'thought',
    required this.content,
    this.pageNumber,
    required this.createdAt,
  });

  BookNoteEntity copyWith({
    String? id,
    String? bookId,
    String? noteType,
    String? content,
    int? pageNumber,
    int? createdAt,
  }) {
    return BookNoteEntity(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      noteType: noteType ?? this.noteType,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookNoteEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ createdAt.hashCode;
}
