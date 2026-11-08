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
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Text(
                    'No logged reading sessions yet.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final s = sessions[idx];
                final dateStr = DateFormat.yMMMd().format(
                  DateTime.fromMillisecondsSinceEpoch(s.startTime),
                );
                final durationMin = (s.durationSeconds / 60).round();
                final pagesRead = s.endPage - s.startPage;

                return ListTile(
                  dense: true,
                  tileColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  leading: const Icon(Icons.timer_outlined,
                      color: Colors.blueAccent),
                  title: Text('$pagesRead pages in $durationMin mins'),
                  subtitle: Text(dateStr),
                  trailing: Text(
                    'Pgs ${s.startPage} - ${s.endPage}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
