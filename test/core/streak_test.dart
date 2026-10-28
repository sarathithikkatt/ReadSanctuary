import 'package:flutter_test/flutter_test.dart';
import 'package:shelfcraft/core/utils/streak_calculator.dart';

void main() {
  group('Verification Gate 4 - Streak Calculation Logic Tests', () {
    // Reference date fixed to 2026-10-28 at 14:00:00 local time
    final refDate = DateTime(2026, 10, 28, 14, 0, 0);

    test('Consecutive days reading calculates currentStreak and longestStreak correctly', () {
      // 4 consecutive days: Today (Oct 28), Oct 27, Oct 26, Oct 25
      final sessions = [
        DateTime(2026, 10, 28, 9, 30).millisecondsSinceEpoch,
        DateTime(2026, 10, 27, 21, 00).millisecondsSinceEpoch,
        DateTime(2026, 10, 26, 18, 15).millisecondsSinceEpoch,
        DateTime(2026, 10, 25, 12, 00).millisecondsSinceEpoch,
      ];

      final result = StreakCalculator.calculate(
        sessionEpochMs: sessions,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 4);
      expect(result.longestStreak, 4);
      expect(result.isTodayCompleted, isTrue);
    });

    test('Today pending preserves streak when user read yesterday but not yet today', () {
      // 3 consecutive days ending yesterday (Oct 27, Oct 26, Oct 25). No session on Oct 28.
      final sessions = [
        DateTime(2026, 10, 27, 20, 00).millisecondsSinceEpoch,
        DateTime(2026, 10, 26, 14, 30).millisecondsSinceEpoch,
        DateTime(2026, 10, 25, 10, 15).millisecondsSinceEpoch,
      ];

      final result = StreakCalculator.calculate(
        sessionEpochMs: sessions,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 3);
      expect(result.longestStreak, 3);
      expect(result.isTodayCompleted, isFalse);
    });

    test('Streak resets to 0 when user missed both today and yesterday', () {
      // User last read on Oct 26 (2 days ago), missed Oct 27 and Oct 28
      final sessions = [
        DateTime(2026, 10, 26, 19, 00).millisecondsSinceEpoch,
        DateTime(2026, 10, 25, 19, 00).millisecondsSinceEpoch,
      ];

      final result = StreakCalculator.calculate(
        sessionEpochMs: sessions,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 0);
      expect(result.longestStreak, 2);
      expect(result.isTodayCompleted, isFalse);
    });

    test('Manual backfill of a missed past date bridges and restores streak', () {
      // Past gap: Read Oct 25, Oct 26, [MISSED Oct 27], Read Oct 28 (today)
      final sessionsWithGap = [
        DateTime(2026, 10, 28, 10, 00).millisecondsSinceEpoch,
        DateTime(2026, 10, 26, 15, 00).millisecondsSinceEpoch,
        DateTime(2026, 10, 25, 12, 00).millisecondsSinceEpoch,
      ];

      final beforeBackfill = StreakCalculator.calculate(
        sessionEpochMs: sessionsWithGap,
        referenceDate: refDate,
      );

      // Streak was broken by missing Oct 27, only today counts
      expect(beforeBackfill.currentStreak, 1);
      expect(beforeBackfill.longestStreak, 2); // Oct 25 + Oct 26

      // User manually backfills a reading session on Oct 27
      final backfilledSessions = [
        ...sessionsWithGap,
        DateTime(2026, 10, 27, 19, 30).millisecondsSinceEpoch, // Backfilled!
      ];

      final afterBackfill = StreakCalculator.calculate(
        sessionEpochMs: backfilledSessions,
        referenceDate: refDate,
      );

      // Oct 25, 26, 27, 28 are now unbroken -> 4 day streak!
      expect(afterBackfill.currentStreak, 4);
      expect(afterBackfill.longestStreak, 4);
      expect(afterBackfill.isTodayCompleted, isTrue);
    });

    test('Accurately tracks historical longest streak higher than current streak', () {
      // Historical 5-day streak in September
      final historicalStreak = [
        DateTime(2026, 9, 1).millisecondsSinceEpoch,
        DateTime(2026, 9, 2).millisecondsSinceEpoch,
        DateTime(2026, 9, 3).millisecondsSinceEpoch,
        DateTime(2026, 9, 4).millisecondsSinceEpoch,
        DateTime(2026, 9, 5).millisecondsSinceEpoch,
      ];

      // Current 2-day streak (Oct 27, Oct 28)
      final currentStreak = [
        DateTime(2026, 10, 27).millisecondsSinceEpoch,
        DateTime(2026, 10, 28).millisecondsSinceEpoch,
      ];

      final result = StreakCalculator.calculate(
        sessionEpochMs: [...historicalStreak, ...currentStreak],
        referenceDate: refDate,
      );

      expect(result.currentStreak, 2);
      expect(result.longestStreak, 5);
    });

    test('Multiple sessions on the same day do not falsely inflate streak count', () {
      // 3 sessions today and 2 sessions yesterday
      final sessions = [
        DateTime(2026, 10, 28, 8, 0).millisecondsSinceEpoch,
        DateTime(2026, 10, 28, 14, 0).millisecondsSinceEpoch,
        DateTime(2026, 10, 28, 21, 30).millisecondsSinceEpoch,
        DateTime(2026, 10, 27, 9, 0).millisecondsSinceEpoch,
        DateTime(2026, 10, 27, 22, 0).millisecondsSinceEpoch,
      ];

      final result = StreakCalculator.calculate(
        sessionEpochMs: sessions,
        referenceDate: refDate,
      );

      expect(result.currentStreak, 2);
      expect(result.longestStreak, 2);
    });

    test('Handles empty session list gracefully', () {
      final result = StreakCalculator.calculate(
        sessionEpochMs: [],
        referenceDate: refDate,
      );

      expect(result.currentStreak, 0);
      expect(result.longestStreak, 0);
      expect(result.isTodayCompleted, isFalse);
    });
  });
}
