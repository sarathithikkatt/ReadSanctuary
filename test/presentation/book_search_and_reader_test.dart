import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelfcraft/core/utils/image_storage_helper.dart';
import 'package:shelfcraft/data/local/database.dart';
import 'package:shelfcraft/data/services/epub_service.dart';
import 'package:shelfcraft/presentation/screens/book_detail/widgets/book_action_buttons.dart';
import 'package:shelfcraft/presentation/screens/book_search/book_search_screen.dart';
import 'package:shelfcraft/presentation/screens/epub_reader/epub_reader_screen.dart';
import 'package:shelfcraft/presentation/screens/pdf_reader/pdf_reader_screen.dart';

class FakeEpubService extends EpubService {
  @override
  Future<EpubBook> parseEpubBytes(List<int> bytes) async {
    return const EpubBook(
      title: 'Frankenstein',
      author: 'Mary Shelley',
      chapters: [
        EpubChapter(
          title: 'Chapter I - The Laboratory',
          paragraphs: [
            'It was on a dreary night of November that I beheld the accomplishment of my toils.'
          ],
          index: 0,
        ),
        EpubChapter(
          title: 'Chapter II - The Monster',
          paragraphs: [
            'Unable to endure the aspect of the being I had created, I rushed out of the room.'
          ],
          index: 1,
        ),
      ],
    );
  }
}

void main() {
  late Directory tempDir;
  late ImageStorageHelper storage;
  late AppDatabase db;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('reader_test_');
    storage = ImageStorageHelper(baseDirProvider: () async => tempDir);
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  const testBookWithoutPdf = Book(
    id: 'test-1',
    title: 'The Great Gatsby',
    authors: '["F. Scott Fitzgerald"]',
    pageCount: 180,
    format: 'paperback',
    status: 'tbr',
    spineColorHex: 0xFF1E3A8A,
    spineTextHex: 0xFFFFFFFF,
    createdAt: 1000,
    updatedAt: 1000,
    lastReadPage: 1,
    pdfPath: null,
  );

  const testBookWithPdf = Book(
    id: 'test-2',
    title: 'Pride and Prejudice',
    authors: '["Jane Austen"]',
    pageCount: 350,
    format: 'ebook',
    status: 'reading',
    spineColorHex: 0xFF2E7D32,
    spineTextHex: 0xFFFFFFFF,
    createdAt: 1000,
    updatedAt: 1000,
    lastReadPage: 25,
    pdfPath: 'pdfs/test-2.pdf',
  );

  const testBookWithEpub = Book(
    id: 'test-3',
    title: 'Frankenstein',
    authors: '["Mary Shelley"]',
    pageCount: 280,
    format: 'ebook',
    status: 'reading',
    spineColorHex: 0xFF2E7D32,
    spineTextHex: 0xFFFFFFFF,
    createdAt: 1000,
    updatedAt: 1000,
    lastReadPage: 3,
    pdfPath: 'pdfs/test-3.epub',
  );

  group('BookActionButtons Tests', () {
    testWidgets(
        'Displays Upload PDF and Find Free PDF buttons when book has no PDF',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageStorageHelperProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BookActionButtons(book: testBookWithoutPdf),
            ),
          ),
        ),
      );

      expect(find.text('Upload PDF'), findsOneWidget);
      expect(find.text('Find Free PDF'), findsOneWidget);
      expect(find.text('Read Timer'), findsOneWidget);
      expect(find.text('Quote OCR'), findsOneWidget);
      expect(find.text('Read Book (PDF)'), findsNothing);
    });

    testWidgets(
        'Displays Read PDF button when book has attached PDF', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageStorageHelperProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BookActionButtons(book: testBookWithPdf),
            ),
          ),
        ),
      );

      expect(
          find.text('Read PDF (Resume Page 25)'), findsOneWidget);
      expect(find.text('Read Timer'), findsOneWidget);
      expect(find.text('Quote OCR'), findsOneWidget);
      expect(find.text('Upload PDF'), findsNothing);
    });

    testWidgets(
        'Displays Read EPUB button when book has attached EPUB', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageStorageHelperProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BookActionButtons(book: testBookWithEpub),
            ),
          ),
        ),
      );

      expect(find.text('Read EPUB (Resume Ch 3)'), findsOneWidget);
      expect(find.text('Read Timer'), findsOneWidget);
      expect(find.text('Quote OCR'), findsOneWidget);
      expect(find.text('Upload PDF'), findsNothing);
    });
  });

  group('BookSearchScreen Widget Tests', () {
    testWidgets('Renders search input, search button, and filter chips',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageStorageHelperProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: BookSearchScreen(),
          ),
        ),
      );

      expect(find.text('Search & Explore Books'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('All Books'), findsOneWidget);
      expect(find.text('Free to Read (PDF/eBook)'), findsOneWidget);
    });
  });

  group('PdfReaderScreen Widget Tests', () {
    testWidgets('Shows error screen when PDF file does not exist on disk',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageStorageHelperProvider.overrideWithValue(storage),
              appDatabaseProvider.overrideWithValue(db),
            ],
            child: const MaterialApp(
              home: PdfReaderScreen(book: testBookWithPdf),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('Pride and Prejudice'), findsOneWidget);
      expect(
          find.text('The PDF file could not be found on local storage.'),
          findsOneWidget);
      expect(find.text('Attach / Replace PDF'), findsOneWidget);
    });

    testWidgets('Shows no PDF error when book has null pdfPath',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageStorageHelperProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(
            home: PdfReaderScreen(book: testBookWithoutPdf),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No PDF file is attached to this book.'), findsOneWidget);
      expect(find.text('Attach / Replace PDF'), findsOneWidget);
    });
  });

  group('EpubReaderScreen Widget Tests', () {
    testWidgets('Shows no EPUB error when book has null pdfPath',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            imageStorageHelperProvider.overrideWithValue(storage),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const MaterialApp(
            home: EpubReaderScreen(book: testBookWithoutPdf),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
          find.text('No EPUB eBook file is attached to this book.'),
          findsOneWidget);
    });

    testWidgets('Shows error screen when EPUB file does not exist on disk',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageStorageHelperProvider.overrideWithValue(storage),
              appDatabaseProvider.overrideWithValue(db),
            ],
            child: const MaterialApp(
              home: EpubReaderScreen(book: testBookWithEpub),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      expect(find.text('The EPUB file could not be found in local storage.'),
          findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets(
        'Loads, renders chapters, and displays reader UI controls',
        (tester) async {
      final pdfsDir = Directory('${tempDir.path}/pdfs');
      pdfsDir.createSync(recursive: true);
      final epubFile = File('${pdfsDir.path}/test-3.epub');
      epubFile.writeAsBytesSync([1, 2, 3, 4, 5]);

      await tester.runAsync(() async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              imageStorageHelperProvider.overrideWithValue(storage),
              appDatabaseProvider.overrideWithValue(db),
              epubServiceProvider.overrideWithValue(FakeEpubService()),
            ],
            child: const MaterialApp(
              home: EpubReaderScreen(
                book: Book(
                  id: 'test-3',
                  title: 'Frankenstein',
                  authors: '["Mary Shelley"]',
                  pageCount: 280,
                  format: 'ebook',
                  status: 'reading',
                  spineColorHex: 0xFF2E7D32,
                  spineTextHex: 0xFFFFFFFF,
                  createdAt: 1000,
                  updatedAt: 1000,
                  lastReadPage: 1,
                  pdfPath: 'pdfs/test-3.epub',
                ),
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      expect(find.text('Frankenstein'), findsOneWidget);
      expect(find.text('Chapter I - The Laboratory'), findsWidgets);
      expect(
          find.text(
              'It was on a dreary night of November that I beheld the accomplishment of my toils.'),
          findsOneWidget);
      expect(find.text('Chapter 1 of 2 (50%)'), findsOneWidget);
      expect(find.byIcon(Icons.format_size), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });
  });
}
