import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/local/database.dart';

/// Dialog allowing readers to manually log or backfill reading sessions
/// (e.g., when reading offline, during a flight, or fixing a broken streak).
class LogManualSessionDialog extends ConsumerStatefulWidget {
  final Book? preselectedBook;

  const LogManualSessionDialog({super.key, this.preselectedBook});

  static Future<bool?> show(BuildContext context, {Book? book}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => LogManualSessionDialog(preselectedBook: book),
    );
  }

  @override
  ConsumerState<LogManualSessionDialog> createState() =>
      _LogManualSessionDialogState();
}

class _LogManualSessionDialogState
    extends ConsumerState<LogManualSessionDialog> {
  static const _uuid = Uuid();

  Book? _selectedBook;
  late DateTime _selectedDate;
  late TextEditingController _startPageCtrl;
  late TextEditingController _endPageCtrl;
  late TextEditingController _minutesCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.preselectedBook;
    _selectedDate = DateTime.now();

    final startPage = _selectedBook?.lastReadPage ?? 1;
    final endPage = (startPage + 25).clamp(1, _selectedBook?.pageCount ?? 500);

    _startPageCtrl = TextEditingController(text: '$startPage');
    _endPageCtrl = TextEditingController(text: '$endPage');
    _minutesCtrl = TextEditingController(text: '30');
  }

  @override
  void dispose() {
    _startPageCtrl.dispose();
    _endPageCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          12,
          0,
        );
      });
    }
  }

  Future<void> _saveSession() async {
    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book.')),
      );
      return;
    }

    final startPage = int.tryParse(_startPageCtrl.text.trim()) ?? 1;
    final endPage = int.tryParse(_endPageCtrl.text.trim()) ?? startPage;
    final minutes = int.tryParse(_minutesCtrl.text.trim()) ?? 15;

    if (endPage < startPage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ending page cannot be less than start page.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = ref.read(appDatabaseProvider);
      final sessionEpochMs = _selectedDate.millisecondsSinceEpoch;

      await db.sessionDao.insertSession(
        ReadingSessionsCompanion.insert(
          id: _uuid.v4(),
          bookId: _selectedBook!.id,
          startTime: sessionEpochMs,
          durationSeconds: minutes * 60,
          startPage: startPage,
          endPage: endPage,
        ),
      );

      // Update book's lastReadPage and status if finished
      final isFinished = endPage >= _selectedBook!.pageCount;
      await db.bookDao.updateBook(
        _selectedBook!.copyWith(
          lastReadPage: endPage,
          status: isFinished ? 'finished' : _selectedBook!.status,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logged ${endPage - startPage} pages on ${DateFormat.yMMMd().format(_selectedDate)}! 📖🔥',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookDao = ref.watch(bookDaoProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.history_edu, color: Colors.teal),
          SizedBox(width: 10),
          Text('Log Reading Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Selector (if not preselected)
            if (widget.preselectedBook == null) ...[
              const Text('Select Book:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              StreamBuilder<List<Book>>(
                stream: bookDao.watchAllBooks(),
                builder: (context, snapshot) {
                  final books = snapshot.data ?? [];
                  if (books.isEmpty) {
                    return const Text('No books in library. Please add a book first.');
                  }

                  _selectedBook ??= books.first;

                  return DropdownButtonFormField<String>(
                    value: _selectedBook?.id,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: books.map((b) {
                      return DropdownMenuItem<String>(
                        value: b.id,
                        child: Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (id) {
                      final chosen = books.firstWhere((b) => b.id == id);
                      setState(() {
                        _selectedBook = chosen;
                        _startPageCtrl.text = '${chosen.lastReadPage}';
                        _endPageCtrl.text = '${(chosen.lastReadPage + 20).clamp(1, chosen.pageCount)}';
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.book, size: 20, color: Colors.teal),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.preselectedBook!.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Date Picker Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(DateFormat.yMMMd().format(_selectedDate)),
                    onPressed: _pickDate,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Set to Today',
                  icon: const Icon(Icons.today, color: Colors.teal),
                  onPressed: () => setState(() => _selectedDate = DateTime.now()),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start & End Pages
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startPageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Start Page',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endPageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'End Page',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Minutes Read
            TextField(
              controller: _minutesCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Duration (Minutes)',
                prefixIcon: const Icon(Icons.timer_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSaving ? null : _saveSession,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Log Session'),
        ),
      ],
    );
  }
}
