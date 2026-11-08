import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shelfcraft/core/utils/streak_calculator.dart';
import 'package:shelfcraft/data/local/database.dart';
import 'package:shelfcraft/data/services/csv_import_service.dart';
import 'package:shelfcraft/data/services/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pro Monetization & Offline Gift Code Tests', () {
    test('Redeeming curated gift code unlocks Pro and persists entitlement', () async {
      final notifier = ProUserNotifier();
      expect(notifier.state, isFalse);

      final success = await notifier.redeemGiftCode('GIFT-SHELFCRAFT');
      expect(success, isTrue);
      expect(notifier.state, isTrue);
      expect(notifier.unlockSource, equals('gift_code'));
      expect(notifier.redeemedCode, equals('GIFT-SHELFCRAFT'));

      // Verify persistence by instantiating a new notifier
      final restoredNotifier = ProUserNotifier();
      // Allow async load to complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(restoredNotifier.state, isTrue);
    });

    test('Redeeming pattern-based gift code (GIFT-XXXXX) unlocks Pro', () async {
      final notifier = ProUserNotifier();
      final success = await notifier.redeemGiftCode('GIFT-FRIEND-2026');
      expect(success, isTrue);
      expect(notifier.state, isTrue);
    });

    test('Redeeming creator passkey unlocks Pro with creator source', () async {
      final notifier = ProUserNotifier();
      final success = await notifier.redeemGiftCode('SHELFCRAFT-CREATOR');
      expect(success, isTrue);
      expect(notifier.state, isTrue);
      expect(notifier.unlockSource, equals('creator_passkey'));
    });

    test('Invalid gift code is rejected without modifying state', () async {
      final notifier = ProUserNotifier();
      final success = await notifier.redeemGiftCode('INVALID_PROMO');
      expect(success, isFalse);
      expect(notifier.state, isFalse);
    });

    test('Resetting Pro status clears SharedPreferences and sets state false', () async {
      final notifier = ProUserNotifier();
      await notifier.redeemGiftCode('BOOKWORM-PRO');
      expect(notifier.state, isTrue);

      await notifier.resetProStatus();
      expect(notifier.state, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ProUserNotifier.spKeyProUnlocked), isFalse);
    });
  });

  group('CSV Export and Round-Trip Import Tests', () {
    late CsvImportService csvService;

    setUp(() {
      csvService = CsvImportService();
    });

    test('exportToCsv generates valid CSV and imports back with 100% fidelity', () {
      final books = [
        Book(
          id: 'b1',
          title: 'The Way of Kings',
          authors: '["Brandon Sanderson"]',
          pageCount: 1007,
          format: 'hardcover',
          status: 'reading',
          rating: 4.85,
          ratingPlot: 4.5,
          ratingCharacters: 4.75,
          ratingWriting: 4.25,
          ratingPacing: 4.0,
          seriesName: 'The Stormlight Archive',
          seriesIndex: 1.0,
          spineColorHex: 0xFF1C2833,
          spineTextHex: 0xFFFFFFFF,
          lastReadPage: 340,
          createdAt: DateTime(2026, 1, 15).millisecondsSinceEpoch,
          updatedAt: DateTime(2026, 1, 15).millisecondsSinceEpoch,
        ),
        Book(
          id: 'b2',
          title: 'Edgedancer',
          authors: '["Brandon Sanderson"]',
          pageCount: 272,
          format: 'paperback',
          status: 'finished',
          rating: 4.5,
          ratingPlot: null,
          ratingCharacters: null,
          ratingWriting: null,
          ratingPacing: null,
          seriesName: 'The Stormlight Archive',
          seriesIndex: 2.5,
          spineColorHex: 0xFF78281F,
          spineTextHex: 0xFFFFFFFF,
          lastReadPage: 272,
          createdAt: DateTime(2026, 2, 10).millisecondsSinceEpoch,
          updatedAt: DateTime(2026, 2, 10).millisecondsSinceEpoch,
        ),
      ];

      // Export to CSV
      final csvString = csvService.exportToCsv(books);
      expect(csvString, contains('The Way of Kings'));
      expect(csvString, contains('Brandon Sanderson'));
      expect(csvString, contains('Edgedancer'));
      expect(csvString, contains('2.5'));

      // Re-import exported CSV
      final parseResult = csvService.parseCsv(csvString);
      expect(parseResult.totalRows, equals(2));
      expect(parseResult.successCount, equals(2));
      expect(parseResult.errorCount, equals(0));

      final imported1 = parseResult.books[0];
      expect(imported1.title.value, equals('The Way of Kings'));
      expect(imported1.authors.value, contains('Brandon Sanderson'));
      expect(imported1.pageCount.value, equals(1007));
      expect(imported1.status.value, equals('reading'));
      expect(imported1.rating.value, equals(4.85));
      expect(imported1.ratingPlot.value, equals(4.5));
      expect(imported1.ratingCharacters.value, equals(4.75));
      expect(imported1.ratingWriting.value, equals(4.25));
      expect(imported1.ratingPacing.value, equals(4.0));

      final imported2 = parseResult.books[1];
      expect(imported2.title.value, equals('Edgedancer'));
      expect(imported2.pageCount.value, equals(272));
      expect(imported2.seriesName.value, equals('The Stormlight Archive'));
      expect(imported2.seriesIndex.value, equals(2.5));
    });
  });

  group('Manual Session Logging & Streak Backfill Tests', () {
    test('Manual session added for a past missed date bridges streak', () {
      final now = DateTime(2026, 11, 8, 12, 0);
      final today = DateTime(2026, 11, 8);
      final twoDaysAgo = today.subtract(const Duration(days: 2));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      // User read today, and read 2 & 3 days ago, but missed yesterday
      final initialSessions = [
        today.millisecondsSinceEpoch,
        twoDaysAgo.millisecondsSinceEpoch,
        threeDaysAgo.millisecondsSinceEpoch,
      ];

      final beforeBackfill = StreakCalculator.calculate(
        sessionEpochMs: initialSessions,
        referenceDate: now,
      );
      // Streak was broken yesterday, so current streak is only 1 (today)
      expect(beforeBackfill.currentStreak, equals(1));

      // Now backfill yesterday manually
      final yesterday = today.subtract(const Duration(days: 1));
      final backfilledSessions = [
        ...initialSessions,
        yesterday.millisecondsSinceEpoch,
      ];

      final afterBackfill = StreakCalculator.calculate(
        sessionEpochMs: backfilledSessions,
        referenceDate: now,
      );
      // Streak bridged: 4 consecutive days!
      expect(afterBackfill.currentStreak, equals(4));
      expect(afterBackfill.isTodayCompleted, isTrue);
    });
  });
}
