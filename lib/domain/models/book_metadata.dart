/// Standardized metadata returned from remote book lookup APIs (OpenLibrary / Google Books).
class BookMetadata {
  final String? isbn13;
  final String title;
  final String? subtitle;
  final List<String> authors;
  final int? pageCount;
  final String? coverUrl;
  final String? publisher;
  final String? publishYear;
  final String? description;
  final String format; // paperback, hardcover, ebook, audiobook

  const BookMetadata({
    this.isbn13,
    required this.title,
    this.subtitle,
    this.authors = const [],
    this.pageCount,
    this.coverUrl,
    this.publisher,
    this.publishYear,
    this.description,
    this.format = 'paperback',
  });

  BookMetadata copyWith({
    String? isbn13,
    String? title,
    String? subtitle,
    List<String>? authors,
    int? pageCount,
    String? coverUrl,
    String? publisher,
    String? publishYear,
    String? description,
    String? format,
  }) {
    return BookMetadata(
      isbn13: isbn13 ?? this.isbn13,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      pageCount: pageCount ?? this.pageCount,
      coverUrl: coverUrl ?? this.coverUrl,
      publisher: publisher ?? this.publisher,
      publishYear: publishYear ?? this.publishYear,
      description: description ?? this.description,
      format: format ?? this.format,
    );
  }

  @override
  String toString() {
    return 'BookMetadata(isbn13: $isbn13, title: $title, authors: $authors, pages: $pageCount, coverUrl: $coverUrl)';
  }
}
