import 'package:flutter/material.dart';

import '../../../../core/utils/streak_calculator.dart';

/// Row displaying current streak and all-time longest streak cards.
class StreakCardsRow extends StatelessWidget {
  final StreakResult streak;

  const StreakCardsRow({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Current Streak
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department,
                      size: 36, color: Colors.amber.shade800),
                  const SizedBox(height: 8),
                  Text(
                    '${streak.currentStreak} Days',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streak.isTodayCompleted
                        ? 'Read Today ✨'
                        : 'Today Pending ⏳',
                    style:
                        TextStyle(fontSize: 12, color: Colors.amber.shade900),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Longest Streak
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.emoji_events,
                      size: 36, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    '${streak.longestStreak} Days',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Best Daily Streak',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
