/// Pure Dart domain entity representing a reading timer or manual reading log session.
class ReadingSessionEntity {
  final String id;
  final String bookId;
  final int startTime; // Unix epoch ms
  final int durationSeconds;
  final int startPage;
  final int endPage;

  const ReadingSessionEntity({
    required this.id,
    required this.bookId,
    required this.startTime,
    required this.durationSeconds,
    required this.startPage,
    required this.endPage,
  });

  /// Computed pages read during this session.
  int get pagesRead => (endPage - startPage).clamp(0, 999999);

  ReadingSessionEntity copyWith({
    String? id,
    String? bookId,
    int? startTime,
    int? durationSeconds,
    int? startPage,
    int? endPage,
  }) {
    return ReadingSessionEntity(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingSessionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          startTime == other.startTime;

  @override
  int get hashCode => id.hashCode ^ startTime.hashCode;
}
