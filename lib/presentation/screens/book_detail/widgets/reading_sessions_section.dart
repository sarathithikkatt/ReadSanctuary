import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/database.dart';
import '../../timer/dialogs/log_manual_session_dialog.dart';

/// Renders logged reading sessions for a book in reverse chronological order
/// with manual backfill shortcut.
class ReadingSessionsSection extends StatelessWidget {
  final Stream<List<ReadingSession>> sessionsStream;
  final Book? book;

  const ReadingSessionsSection({
    super.key,
    required this.sessionsStream,
    this.book,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Reading Sessions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (book != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Manually', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => LogManualSessionDialog.show(context, book: book),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<ReadingSession>>(
          stream: sessionsStream,
          builder: (context, snapshot) {
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: Colors.black.withOpacity(0.06)),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off,
                          size: 28, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No logged reading sessions yet.',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final s = sessions[idx];
                final dateStr = DateFormat.yMMMd().format(
                  DateTime.fromMillisecondsSinceEpoch(s.startTime),
                );
                final durationMin = (s.durationSeconds / 60).round();
                final pagesRead = s.endPage - s.startPage;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                  ),
                  child: ListTile(
                    dense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.timer_outlined,
                          color: Colors.blue.shade700, size: 18),
                    ),
                    title: Text(
                      '$pagesRead pages in $durationMin mins',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(dateStr,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pgs ${s.startPage} - ${s.endPage}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: Color(0xFF4A3E38),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
