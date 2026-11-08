import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';

/// Row showing key reading metrics: total books, total pages read, and total hours spent reading.
class ReadingMetricsRow extends StatelessWidget {
  final List<ReadingSession> sessions;
  final List<Book> books;

  const ReadingMetricsRow({
    super.key,
    required this.sessions,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    int totalPages = 0;
    int totalSeconds = 0;
    for (final s in sessions) {
      totalPages += (s.endPage - s.startPage).clamp(0, 5000);
      totalSeconds += s.durationSeconds;
    }
    final totalHours = (totalSeconds / 3600).toStringAsFixed(1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
            child: _buildSingleCounter(
                'Total Books', '${books.length}', Icons.library_books)),
        Expanded(
            child: _buildSingleCounter(
                'Pages Read', '$totalPages', Icons.auto_stories)),
        Expanded(
            child: _buildSingleCounter(
                'Hours Spent', '$totalHours h', Icons.schedule)),
      ],
    );
  }

  Widget _buildSingleCounter(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey.shade700),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
