import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/data/local/database.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/book_cover_tilt_widget.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/book_spine_25d_widget.dart';
import 'package:shelfcraft/presentation/screens/bookshelf/widgets/interactive_3d_book_viewer.dart';

void main() {
  const testBook = Book(
    id: 'book-3d-test',
    title: 'The Hobbit',
    authors: '["J.R.R. Tolkien"]',
    pageCount: 310,
    format: 'hardcover',
    status: 'reading',
    spineColorHex: 0xFF1565C0,
    spineTextHex: 0xFFFFFFFF,
    createdAt: 1000,
    updatedAt: 1000,
    lastReadPage: 45,
    pdfPath: 'pdfs/hobbit.pdf',
  );

  group('Interactive3dBookViewer Widget Tests', () {
    testWidgets('Renders 3D book header, angle chips, and bottom action bar',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Interactive3dBookViewer(book: testBook),
          ),
        ),
      );

      // Verify header details
      expect(find.text('The Hobbit'), findsWidgets);
      expect(find.textContaining('J.R.R. Tolkien'), findsOneWidget);
      expect(find.textContaining('310 pages'), findsOneWidget);
      expect(find.textContaining('HARDCOVER'), findsOneWidget);

      // Verify angle preset chips
      expect(find.text('3D View'), findsOneWidget);
      expect(find.text('Front Cover'), findsOneWidget);
      expect(find.text('Spine'), findsOneWidget);
      expect(find.text('Page Edges'), findsOneWidget);
      expect(find.text('Back Cover'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Read (Pg 45)'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Tapping preset angle chip triggers camera rotation animation',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Interactive3dBookViewer(book: testBook),
          ),
        ),
      );

      // Tap 'Spine' preset
      await tester.tap(find.text('Spine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 'Back Cover' preset
      await tester.tap(find.text('Back Cover'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Successfully completes animation without errors
      expect(find.byType(Interactive3dBookViewer), findsOneWidget);
    });

    testWidgets('Pan gesture rotates book without exceptions', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Interactive3dBookViewer(book: testBook),
          ),
        ),
      );

      // Drag horizontally
      await tester.drag(
        find.byType(Interactive3dBookViewer),
        const Offset(60.0, 10.0),
        warnIfMissed: false,
      );
      await tester.pump();

      // Drag vertically
      await tester.drag(
        find.byType(Interactive3dBookViewer),
        const Offset(0.0, -40.0),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(find.byType(Interactive3dBookViewer), findsOneWidget);
    });
  });

  group('BookSpine25DWidget and BookCoverTiltWidget LongPress Tests', () {
    testWidgets('BookSpine25DWidget fires onLongPress callback', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookSpine25DWidget(
              id: testBook.id,
              title: testBook.title,
              pageCount: testBook.pageCount,
              format: testBook.format,
              spineColorHex: testBook.spineColorHex,
              spineTextHex: testBook.spineTextHex,
              onLongPress: () {
                longPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(BookSpine25DWidget));
      expect(longPressed, isTrue);
    });

    testWidgets('BookCoverTiltWidget fires onLongPress callback', (tester) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookCoverTiltWidget(
              id: testBook.id,
              title: testBook.title,
              spineColorHex: testBook.spineColorHex,
              spineTextHex: testBook.spineTextHex,
              onLongPress: () {
                longPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(BookCoverTiltWidget));
      expect(longPressed, isTrue);
    });
  });
}
