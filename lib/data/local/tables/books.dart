import 'package:drift/drift.dart';

@DataClassName('Book')
@TableIndex(name: 'books_isbn13_idx', columns: {#isbn13})
class Books extends Table {
  TextColumn get id => text()();
  TextColumn get isbn13 => text().nullable()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get authors =>
      text()(); // JSON array of author names e.g. ["Author"]
  IntColumn get pageCount => integer().withDefault(const Constant(250))();
  TextColumn get format => text().withDefault(
      const Constant('paperback'))(); // paperback, hardcover, ebook, audiobook
  TextColumn get status => text()(); // tbr, reading, finished, dnf, lent
  TextColumn get seriesName => text().nullable()();
  RealColumn get seriesIndex =>
      real().nullable()(); // Fractional float e.g. 0.5, 1.0, 1.5, 2.0
  TextColumn get coverPath => text()
      .nullable()(); // Relative path to local cover image in media/covers/
  TextColumn get customSpinePath =>
      text().nullable()(); // Relative path to user spine image in media/spines/
  TextColumn get pdfPath =>
      text().nullable()(); // Relative path to local PDF file in media/pdfs/
  IntColumn get lastReadPage =>
      integer().withDefault(const Constant(1))(); // Last read page index (1-based)
  IntColumn get spineColorHex => integer()(); // ARGB int
  IntColumn get spineTextHex =>
      integer()(); // Contrasting ARGB int for typography
  RealColumn get rating => real().nullable()(); // 0.0 to 5.0 (0.25 steps)
  RealColumn get ratingPlot => real().nullable()(); // 0.0 to 5.0 (0.25 steps)
  RealColumn get ratingCharacters => real().nullable()(); // 0.0 to 5.0 (0.25 steps)
  RealColumn get ratingWriting => real().nullable()(); // 0.0 to 5.0 (0.25 steps)
  RealColumn get ratingPacing => real().nullable()(); // 0.0 to 5.0 (0.25 steps)
  IntColumn get createdAt => integer()(); // Unix epoch ms
  IntColumn get updatedAt => integer()(); // Unix epoch ms

  @override
  Set<Column> get primaryKey => {id};
}
