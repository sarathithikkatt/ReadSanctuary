import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/data/services/epub_service.dart';

void main() {
  group('EpubService Unit Tests', () {
    late EpubService epubService;

    setUp(() {
      epubService = EpubService();
    });

    List<int> createTestEpubBytes({
      String title = 'Frankenstein',
      String author = 'Mary Shelley',
      bool includeCover = true,
    }) {
      final archive = Archive();

      // mimetype
      archive.addFile(ArchiveFile.noCompress(
        'mimetype',
        20,
        utf8.encode('application/epub+zip'),
      ));

      // META-INF/container.xml
      const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
      archive.addFile(ArchiveFile(
        'META-INF/container.xml',
        containerXml.length,
        utf8.encode(containerXml),
      ));

      // OEBPS/content.opf
      final opfXml = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
  </metadata>
  <manifest>
    ${includeCover ? '<item id="cover-image" href="images/cover.jpg" media-type="image/jpeg" properties="cover-image"/>' : ''}
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''';
      archive.addFile(ArchiveFile(
        'OEBPS/content.opf',
        opfXml.length,
        utf8.encode(opfXml),
      ));

      if (includeCover) {
        final dummyCoverBytes = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]; // minimal JPEG header
        archive.addFile(ArchiveFile(
          'OEBPS/images/cover.jpg',
          dummyCoverBytes.length,
          dummyCoverBytes,
        ));
      }

      // OEBPS/text/ch1.xhtml
      const ch1Xhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter I &mdash; Origins</title></head>
<body>
  <h1>Chapter I</h1>
  <p>I am by birth a Genevese, and my family is one of the most distinguished of that republic.</p>
  <p>My ancestors had been for many years counsellors &amp; syndics.</p>
</body>
</html>''';
      archive.addFile(ArchiveFile(
        'OEBPS/text/ch1.xhtml',
        ch1Xhtml.length,
        utf8.encode(ch1Xhtml),
      ));

      // OEBPS/text/ch2.xhtml
      const ch2Xhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter II</title></head>
<body>
  <h2>Chapter II</h2>
  <p>We were brought up together; there was not quite a year difference in our ages.</p>
</body>
</html>''';
      archive.addFile(ArchiveFile(
        'OEBPS/text/ch2.xhtml',
        ch2Xhtml.length,
        utf8.encode(ch2Xhtml),
      ));

      return ZipEncoder().encode(archive)!;
    }

    test('Parses valid EPUB metadata, chapters, paragraphs, and cover', () async {
      final epubBytes = createTestEpubBytes();
      final book = await epubService.parseEpubBytes(epubBytes);

      expect(book.title, 'Frankenstein');
      expect(book.author, 'Mary Shelley');
      expect(book.coverBytes, isNotNull);
      expect(book.totalChapters, 2);

      // Chapter 1
      final ch1 = book.chapters[0];
      expect(ch1.title, 'Chapter I — Origins');
      expect(ch1.paragraphs.length, 2);
      expect(ch1.paragraphs[0],
          'I am by birth a Genevese, and my family is one of the most distinguished of that republic.');
      expect(ch1.paragraphs[1],
          'My ancestors had been for many years counsellors & syndics.');
      expect(ch1.wordCount, greaterThan(15));

      // Chapter 2
      final ch2 = book.chapters[1];
      expect(ch2.title, 'Chapter II');
      expect(ch2.paragraphs.length, 1);
      expect(ch2.paragraphs[0],
          'We were brought up together; there was not quite a year difference in our ages.');
    });

    test('Handles EPUB without cover image gracefully', () async {
      final epubBytes = createTestEpubBytes(includeCover: false);
      final book = await epubService.parseEpubBytes(epubBytes);

      expect(book.title, 'Frankenstein');
      expect(book.coverBytes, isNull);
      expect(book.totalChapters, 2);
    });

    test('Throws FormatException on corrupted or missing container.xml', () async {
      final archive = Archive();
      archive.addFile(ArchiveFile(
        'random.txt',
        5,
        utf8.encode('hello'),
      ));
      final bytes = ZipEncoder().encode(archive)!;

      expect(
        () => epubService.parseEpubBytes(bytes),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
