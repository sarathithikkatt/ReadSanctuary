/// Result of streak computation containing current streak, longest streak,
/// and whether today's reading is completed or still pending.
class StreakResult {
  final int currentStreak;
  final int longestStreak;
  final bool isTodayCompleted;
  final Set<String> activeDates; // Set of 'YYYY-MM-DD' strings

  const StreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.isTodayCompleted,
    required this.activeDates,
  });
}

/// Robust calculator for daily reading streaks, streak maintenance,
/// today-pending detection, and manual date backfilling.
class StreakCalculator {
  /// Converts a [DateTime] into a normalized date key 'YYYY-MM-DD'.
  static String toDateKey(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// Parses 'YYYY-MM-DD' key back into a [DateTime] at midnight UTC.
  static DateTime parseDateKey(String key) {
    final parts = key.split('-').map(int.parse).toList();
    return DateTime.utc(parts[0], parts[1], parts[2]);
  }

  /// Computes streak metrics given a collection of session timestamps (epoch milliseconds),
  /// evaluated relative to [referenceDate] (defaults to current local time).
  static StreakResult calculate({
    required Iterable<int> sessionEpochMs,
    DateTime? referenceDate,
  }) {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayKey = toDateKey(today);
    final yesterdayKey = toDateKey(yesterday);

    // Normalize all sessions into unique date keys
    final dateKeys = <String>{};
    for (final ms in sessionEpochMs) {
      final dt = DateTime.fromMillisecondsSinceEpoch(ms);
      dateKeys.add(toDateKey(dt));
    }

    final isTodayCompleted = dateKeys.contains(todayKey);
    final isYesterdayCompleted = dateKeys.contains(yesterdayKey);

    // If no reading today and no reading yesterday, current streak is 0
    int currentStreak = 0;
    if (isTodayCompleted) {
      currentStreak = 1;
      var checkDate = yesterday;
      while (dateKeys.contains(toDateKey(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    } else if (isYesterdayCompleted) {
      // Today is pending (streak is preserved from yesterday)
      currentStreak = 1;
      var checkDate = yesterday.subtract(const Duration(days: 1));
      while (dateKeys.contains(toDateKey(checkDate))) {
        currentStreak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      }
    }

    // Longest streak calculation across all historical dates
    int longestStreak = 0;
    if (dateKeys.isNotEmpty) {
      final sortedDates = dateKeys.map(parseDateKey).toList()..sort();
      int tempStreak = 1;
      longestStreak = 1;

      for (int i = 1; i < sortedDates.length; i++) {
        final diffDays = sortedDates[i].difference(sortedDates[i - 1]).inDays;
        if (diffDays == 1) {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else if (diffDays > 1) {
          tempStreak = 1;
        }
      }
    }

    // Longest streak cannot be less than current streak
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    return StreakResult(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      isTodayCompleted: isTodayCompleted,
      activeDates: dateKeys,
    );
  }
}
