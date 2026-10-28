import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/data/local/database.dart';
import 'package:uuid/uuid.dart';

void main() {
  late AppDatabase db;
  const uuid = Uuid();

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 1 Database Tests - CRUD Operations', () {
    test('Can insert, read, update, and delete a Book', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = uuid.v4();

      final book = BooksCompanion.insert(
        id: bookId,
        isbn13: const Value('9780765326355'),
        title: 'The Way of Kings',
        subtitle: const Value('The Stormlight Archive Book One'),
        authors: '["Brandon Sanderson"]',
        pageCount: const Value(1007),
        format: const Value('hardcover'),
        status: 'reading',
        seriesName: const Value('The Stormlight Archive'),
        seriesIndex: const Value(1.0),
        coverPath: const Value('covers/twok.jpg'),
        customSpinePath: const Value(null),
        spineColorHex: 0xFF1E3A8A,
        spineTextHex: 0xFFFFFFFF,
        rating: const Value(4.75),
        createdAt: now,
        updatedAt: now,
      );

      // Create
      await db.bookDao.insertBook(book);

      // Read
      final fetched = await db.bookDao.getBookById(bookId);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'The Way of Kings');
      expect(fetched.isbn13, '9780765326355');
      expect(fetched.pageCount, 1007);
      expect(fetched.seriesIndex, 1.0);
      expect(fetched.rating, 4.75);

      // Update
      final updated = fetched.copyWith(
        status: 'finished',
        rating: const Value(5.0),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final updateSuccess = await db.bookDao.updateBook(updated);
      expect(updateSuccess, isTrue);

      final reFetched = await db.bookDao.getBookById(bookId);
      expect(reFetched!.status, 'finished');
      expect(reFetched.rating, 5.0);

      // Delete
      final deletedCount = await db.bookDao.deleteBook(bookId);
      expect(deletedCount, 1);

      final afterDelete = await db.bookDao.getBookById(bookId);
      expect(afterDelete, isNull);
    });

    test('Can batch insert books transactionally', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final books = List.generate(
        5,
        (i) => BooksCompanion.insert(
          id: uuid.v4(),
          title: 'Batch Book $i',
          authors: '["Author $i"]',
          status: 'tbr',
          spineColorHex: 0xFF000000,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
      );

      await db.bookDao.insertBooks(books);
      final allBooks = await db.bookDao.getAllBooks();
      expect(allBooks.length, 5);
    });
  });

  group('Phase 1 Database Tests - Fractional seriesIndex Sorting', () {
    test('Sorts books accurately by fractional seriesIndex: 0.5, 1.0, 1.5, 2.0', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      const seriesName = 'The Stormlight Archive';

      final books = [
        BooksCompanion.insert(
          id: uuid.v4(),
          title: 'Words of Radiance',
          authors: '["Brandon Sanderson"]',
          status: 'tbr',
          seriesName: const Value(seriesName),
          seriesIndex: const Value(2.0),
          spineColorHex: 0xFF222222,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
        BooksCompanion.insert(
          id: uuid.v4(),
          title: 'Prelude to the Storm',
          authors: '["Brandon Sanderson"]',
          status: 'finished',
          seriesName: const Value(seriesName),
          seriesIndex: const Value(0.5),
          spineColorHex: 0xFF333333,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
        BooksCompanion.insert(
          id: uuid.v4(),
          title: 'Edgedancer',
          authors: '["Brandon Sanderson"]',
          status: 'finished',
          seriesName: const Value(seriesName),
          seriesIndex: const Value(1.5),
          spineColorHex: 0xFF444444,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
        BooksCompanion.insert(
          id: uuid.v4(),
          title: 'The Way of Kings',
          authors: '["Brandon Sanderson"]',
          status: 'finished',
          seriesName: const Value(seriesName),
          seriesIndex: const Value(1.0),
          spineColorHex: 0xFF111111,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      for (final book in books) {
        await db.bookDao.insertBook(book);
      }

      final sortedBooks = await db.bookDao.getBooksBySeries(seriesName);
      expect(sortedBooks.length, 4);

      expect(sortedBooks[0].title, 'Prelude to the Storm');
      expect(sortedBooks[0].seriesIndex, 0.5);

      expect(sortedBooks[1].title, 'The Way of Kings');
      expect(sortedBooks[1].seriesIndex, 1.0);

      expect(sortedBooks[2].title, 'Edgedancer');
      expect(sortedBooks[2].seriesIndex, 1.5);

      expect(sortedBooks[3].title, 'Words of Radiance');
      expect(sortedBooks[3].seriesIndex, 2.0);
    });
  });

  group('Phase 1 Database Tests - Foreign Key Cascades', () {
    test('Deleting a Shelf cascades to ShelfItems', () async {
      final shelfId = uuid.v4();
      final shelfItemId1 = uuid.v4();
      final shelfItemId2 = uuid.v4();

      await db.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: shelfId,
          name: 'Favorites Shelf',
          sortOrder: 0,
        ),
      );

      await db.shelfDao.insertShelfItem(
        ShelfItemsCompanion.insert(
          id: shelfItemId1,
          shelfId: shelfId,
          itemType: 'prop',
          propAssetId: const Value('plant_monstera'),
          positionIndex: 0,
        ),
      );

      await db.shelfDao.insertShelfItem(
        ShelfItemsCompanion.insert(
          id: shelfItemId2,
          shelfId: shelfId,
          itemType: 'gap',
          positionIndex: 1,
        ),
      );

      var items = await db.shelfDao.getItemsForShelf(shelfId);
      expect(items.length, 2);

      // Delete shelf
      final deletedShelves = await db.shelfDao.deleteShelf(shelfId);
      expect(deletedShelves, 1);

      // Verify ShelfItems were cascade deleted
      items = await db.shelfDao.getItemsForShelf(shelfId);
      expect(items, isEmpty);
    });

    test('Deleting a Book cascades to ShelfItems, ReadingSessions, and BookNotes', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = uuid.v4();
      final shelfId = uuid.v4();
      final shelfItemId = uuid.v4();
      final sessionId = uuid.v4();
      final noteId = uuid.v4();

      // Create shelf
      await db.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: shelfId,
          name: 'Main Shelf',
          sortOrder: 0,
        ),
      );

      // Create book
      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: bookId,
          title: 'Project Hail Mary',
          authors: '["Andy Weir"]',
          status: 'reading',
          spineColorHex: 0xFFF59E0B,
          spineTextHex: 0xFF000000,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Place book on shelf
      await db.shelfDao.insertShelfItem(
        ShelfItemsCompanion.insert(
          id: shelfItemId,
          shelfId: shelfId,
          itemType: 'book',
          bookId: Value(bookId),
          positionIndex: 0,
        ),
      );

      // Log reading session
      await db.sessionDao.insertSession(
        ReadingSessionsCompanion.insert(
          id: sessionId,
          bookId: bookId,
          startTime: now,
          durationSeconds: 1800,
          startPage: 1,
          endPage: 45,
        ),
      );

      // Add quote note
      await db.sessionDao.insertNote(
        BookNotesCompanion.insert(
          id: noteId,
          bookId: bookId,
          noteType: 'quote',
          content: 'I penetrate the outer shell with a tiny burst of thrust.',
          pageNumber: const Value(25),
          createdAt: now,
        ),
      );

      // Confirm entries exist
      expect(await db.shelfDao.getItemsForShelf(shelfId), hasLength(1));
      expect(await db.sessionDao.getSessionsForBook(bookId), hasLength(1));
      expect(await db.sessionDao.getNotesForBook(bookId), hasLength(1));

      // Delete the book
      final deleted = await db.bookDao.deleteBook(bookId);
      expect(deleted, 1);

      // Verify cascade deletion across all referencing tables
      expect(await db.shelfDao.getItemsForShelf(shelfId), isEmpty);
      expect(await db.sessionDao.getSessionsForBook(bookId), isEmpty);
      expect(await db.sessionDao.getNotesForBook(bookId), isEmpty);
    });
  });

  group('Phase 1 Database Tests - Reactive Streams & Shelf Reordering', () {
    test('ShelfDao reorderShelfItems updates position indices in order', () async {
      final shelfId = uuid.v4();
      final item1 = uuid.v4();
      final item2 = uuid.v4();
      final item3 = uuid.v4();

      await db.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: shelfId,
          name: 'Fiction',
          sortOrder: 0,
        ),
      );

      await db.shelfDao.insertShelfItems([
        ShelfItemsCompanion.insert(id: item1, shelfId: shelfId, itemType: 'gap', positionIndex: 0),
        ShelfItemsCompanion.insert(id: item2, shelfId: shelfId, itemType: 'gap', positionIndex: 1),
        ShelfItemsCompanion.insert(id: item3, shelfId: shelfId, itemType: 'gap', positionIndex: 2),
      ]);

      // Reorder: item3, item1, item2
      await db.shelfDao.reorderShelfItems(shelfId, [item3, item1, item2]);

      final reordered = await db.shelfDao.getItemsForShelf(shelfId);
      expect(reordered.map((e) => e.id).toList(), [item3, item1, item2]);
      expect(reordered[0].positionIndex, 0);
      expect(reordered[1].positionIndex, 1);
      expect(reordered[2].positionIndex, 2);
    });

    test('watchAllBooks stream reacts to book insertions', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final stream = db.bookDao.watchAllBooks();

      expectLater(
        stream,
        emitsInOrder([
          isEmpty,
          hasLength(1),
        ]),
      );

      await pumpEventQueue();

      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: uuid.v4(),
          title: 'Dune',
          authors: '["Frank Herbert"]',
          status: 'reading',
          spineColorHex: 0xFFD97706,
          spineTextHex: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        ),
      );
    });
  });
}
