/// Pure Dart domain entity representing a Book in the ReadSanctuary catalog.
/// Free from any Flutter or Drift dependencies.
class BookEntity {
  final String id;
  final String? isbn13;
  final String title;
  final String? subtitle;
  final String? description;
  final String? publisher;
  final String? publishYear;
  final List<String> authors;
  final int pageCount;
  final String format; // paperback, hardcover, ebook, audiobook
  final String status; // tbr, reading, finished, dnf, lent
  final int? finishedAt; // Unix epoch ms
  final String? seriesName;
  final double? seriesIndex;
  final String? coverPath;
  final String? backCoverPath;
  final String? customSpinePath;
  final String? pdfPath;
  final int lastReadPage;
  final int spineColorHex;
  final int spineTextHex;
  final double? rating;
  final double? ratingPlot;
  final double? ratingCharacters;
  final double? ratingWriting;
  final double? ratingPacing;
  final int? lastReadAt; // Unix epoch ms
  final int createdAt; // Unix epoch ms
  final int updatedAt; // Unix epoch ms
  final int? deletedAt; // Unix epoch ms for soft delete

  const BookEntity({
    required this.id,
    this.isbn13,
    required this.title,
    this.subtitle,
    this.description,
    this.publisher,
    this.publishYear,
    this.authors = const [],
    this.pageCount = 250,
    this.format = 'paperback',
    required this.status,
    this.finishedAt,
    this.seriesName,
    this.seriesIndex,
    this.coverPath,
    this.backCoverPath,
    this.customSpinePath,
    this.pdfPath,
    this.lastReadPage = 1,
    required this.spineColorHex,
    required this.spineTextHex,
    this.rating,
    this.ratingPlot,
    this.ratingCharacters,
    this.ratingWriting,
    this.ratingPacing,
    this.lastReadAt,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Computed author line formatted nicely for display.
  String get displayAuthor {
    if (authors.isEmpty) return 'Unknown Author';
    return authors.join(', ');
  }

  /// Current progress ratio between 0.0 and 1.0.
  double get progress {
    if (pageCount <= 0) return 0.0;
    return (lastReadPage / pageCount).clamp(0.0, 1.0);
  }

  /// Whether this entity has been soft-deleted.
  bool get isDeleted => deletedAt != null;

  /// Copy with convenience helper.
  BookEntity copyWith({
    String? id,
    String? isbn13,
    String? title,
    String? subtitle,
    String? description,
    String? publisher,
    String? publishYear,
    List<String>? authors,
    int? pageCount,
    String? format,
    String? status,
    int? finishedAt,
    String? seriesName,
    double? seriesIndex,
    String? coverPath,
    String? backCoverPath,
    String? customSpinePath,
    String? pdfPath,
    int? lastReadPage,
    int? spineColorHex,
    int? spineTextHex,
    double? rating,
    double? ratingPlot,
    double? ratingCharacters,
    double? ratingWriting,
    double? ratingPacing,
    int? lastReadAt,
    int? createdAt,
    int? updatedAt,
    int? deletedAt,
  }) {
    return BookEntity(
      id: id ?? this.id,
      isbn13: isbn13 ?? this.isbn13,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      authors: authors ?? this.authors,
      pageCount: pageCount ?? this.pageCount,
      format: format ?? this.format,
      status: status ?? this.status,
      finishedAt: finishedAt ?? this.finishedAt,
      seriesName: seriesName ?? this.seriesName,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      coverPath: coverPath ?? this.coverPath,
      backCoverPath: backCoverPath ?? this.backCoverPath,
      customSpinePath: customSpinePath ?? this.customSpinePath,
      pdfPath: pdfPath ?? this.pdfPath,
      lastReadPage: lastReadPage ?? this.lastReadPage,
      spineColorHex: spineColorHex ?? this.spineColorHex,
      spineTextHex: spineTextHex ?? this.spineTextHex,
      rating: rating ?? this.rating,
      ratingPlot: ratingPlot ?? this.ratingPlot,
      ratingCharacters: ratingCharacters ?? this.ratingCharacters,
      ratingWriting: ratingWriting ?? this.ratingWriting,
      ratingPacing: ratingPacing ?? this.ratingPacing,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => id.hashCode ^ updatedAt.hashCode;
}
