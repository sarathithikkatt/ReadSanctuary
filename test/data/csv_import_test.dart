import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/data/services/csv_import_service.dart';

void main() {
  late CsvImportService service;

  setUp(() {
    service = CsvImportService();
  });

  group('CsvImportService - Goodreads CSV Tests', () {
    test('Parses escaped quotes, ="978..." ISBN, and missing page counts', () {
      const goodreadsCsv = '''
Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,Bookshelves with positions,Exclusive Shelf,My Review,Spoilers,Private Notes,Read Count,Recommended For,Recommended By,Owned Copies
1001,"The ""Ultimate"" Hitchhiker's Guide to the Galaxy",Douglas Adams,"Adams, Douglas",,="0345453743",="9780345453747",5,4.38,Del Rey,Hardcover,815,2002,1979,2023/03/15,2023/01/01,,,read,"A brilliant, hilarious ""classic""!",,,,1,,,0
1002,"Dune Messiah (Dune, #2)","Frank Herbert","Herbert, Frank",,="0441172695",="9780441172696",4,3.88,Ace,Paperback,,1969,1969,2023/04/10,2023/02/01,,,read,,,,,,1,,,0
1003,"Unknown Book Without Pages",Some Author,"Author, Some",,="",="",0,3.50,Publisher,Paperback,,2020,2020,,2023/05/01,,,to-read,,,,,,0,,,0
''';

      final result = service.parseCsv(goodreadsCsv);

      expect(result.totalRows, 3);
      expect(result.successCount, 3);
      expect(result.errorCount, 0);

      // Book 1: Escaped quotes in title and review, valid ISBN13, explicit page count
      final book1 = result.books[0];
      expect(book1.title.value, 'The "Ultimate" Hitchhiker\'s Guide to the Galaxy');
      expect(book1.isbn13.value, '9780345453747');
      expect(book1.pageCount.value, 815);
      expect(book1.status.value, 'finished');
      expect(book1.rating.value, 5.0);
      expect(book1.format.value, 'hardcover');

      // Book 2: Series and index parsed from title, missing page count defaults to 250
      final book2 = result.books[1];
      expect(book2.title.value, 'Dune Messiah');
      expect(book2.seriesName.value, 'Dune');
      expect(book2.seriesIndex.value, 2.0);
      expect(book2.isbn13.value, '9780441172696');
      expect(book2.pageCount.value, 250); // Default applied
      expect(book2.status.value, 'finished');
      expect(book2.rating.value, 4.0);

      // Book 3: ="..." empty ISBNs sanitized to null, unrated (0) mapped to null rating
      final book3 = result.books[2];
      expect(book3.title.value, 'Unknown Book Without Pages');
      expect(book3.isbn13.value, isNull);
      expect(book3.pageCount.value, 250);
      expect(book3.status.value, 'tbr');
      expect(book3.rating.value, isNull);
    });

    test('Parses fractional series novella: #1.5 and #0.5', () {
      const seriesCsv = '''
Book Id,Title,Author,ISBN13,My Rating,Number of Pages,Exclusive Shelf
2001,"Edgedancer (The Stormlight Archive, #1.5)",Brandon Sanderson,="9781250166548",4,272,read
2002,"Dawnshard (The Stormlight Archive, #3.5)",Brandon Sanderson,="9781250868206",5,260,read
''';

      final result = service.parseCsv(seriesCsv);
      expect(result.successCount, 2);

      expect(result.books[0].title.value, 'Edgedancer');
      expect(result.books[0].seriesName.value, 'The Stormlight Archive');
      expect(result.books[0].seriesIndex.value, 1.5);

      expect(result.books[1].title.value, 'Dawnshard');
      expect(result.books[1].seriesName.value, 'The Stormlight Archive');
      expect(result.books[1].seriesIndex.value, 3.5);
    });

    test('Sanitizes various ISBN formats properly', () {
      expect(CsvImportService.sanitizeIsbn('="9780140283297"'), '9780140283297');
      expect(CsvImportService.sanitizeIsbn('="014028329X"'), '014028329X');
      expect(CsvImportService.sanitizeIsbn('=""'), isNull);
      expect(CsvImportService.sanitizeIsbn(''), isNull);
      expect(CsvImportService.sanitizeIsbn(null), isNull);
      expect(CsvImportService.sanitizeIsbn('978-0-14-028329-7'), '9780140283297');
    });
  });

  group('CsvImportService - StoryGraph CSV Tests', () {
    test('Parses StoryGraph CSV format successfully', () {
      const storyGraphCsv = '''
Title,Authors,Contributors,ISBN/UID,Format,Last Date Read,Read Status,Star Rating,Number of Pages,Tags,Review
"Project Hail Mary",Andy Weir,,9780593135204,Hardcover,2023-08-01,read,5.0,496,sci-fi,"Incredible book"
"Tomorrow, and Tomorrow, and Tomorrow",Gabrielle Zevin,,9780593321201,Digital,,currently-reading,,416,contemporary,
''';

      final result = service.parseCsv(storyGraphCsv);
      expect(result.successCount, 2);

      final book1 = result.books[0];
      expect(book1.title.value, 'Project Hail Mary');
      expect(book1.isbn13.value, '9780593135204');
      expect(book1.status.value, 'finished');
      expect(book1.pageCount.value, 496);
      expect(book1.rating.value, 5.0);
      expect(book1.format.value, 'hardcover');

      final book2 = result.books[1];
      expect(book2.title.value, 'Tomorrow, and Tomorrow, and Tomorrow');
      expect(book2.status.value, 'reading');
      expect(book2.format.value, 'ebook');
      expect(book2.rating.value, isNull);
    });
  });
}
