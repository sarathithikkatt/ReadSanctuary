import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';

/// Card showing progress towards the annual reading goal with quick edit support.
class YearlyGoalCard extends StatelessWidget {
  final List<Book> books;
  final int yearlyGoal;
  final VoidCallback? onEditGoal;

  const YearlyGoalCard({
    super.key,
    required this.books,
    required this.yearlyGoal,
    this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final finishedThisYear = books.where((b) {
      if (b.status != 'finished') return false;
      final year = DateTime.fromMillisecondsSinceEpoch(b.updatedAt).year;
      return year == currentYear;
    }).length;

    final progress = (finishedThisYear / yearlyGoal).clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          '$currentYear Reading Goal',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onEditGoal != null) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Yearly Goal',
                          onPressed: onEditGoal,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$finishedThisYear / $yearlyGoal books',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                color: Colors.green.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$percent% of goal completed',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (finishedThisYear >= yearlyGoal)
                  const Text(
                    '🎉 Goal Reached!',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
