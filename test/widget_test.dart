import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/app.dart';
import 'package:shelfcraft/data/local/database.dart';

void main() {
  testWidgets('ShelfCraftApp smoke test pumps successfully',
      (WidgetTester tester) async {
    final testDb = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(testDb),
        ],
        child: const ShelfCraftApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ShelfCraft'), findsWidgets);
    expect(find.text('Bookshelf'), findsOneWidget);
    expect(find.text('Scan ISBN'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
    expect(find.text('Backup & Pro'), findsOneWidget);

    await testDb.close();
  });
}
