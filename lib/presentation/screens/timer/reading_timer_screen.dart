import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/local/database.dart';

/// Reading focus timer screen with background-kill resilient SharedPreferences state persistence,
/// pages-per-minute speed calculation, and reading session database logging.
class ReadingTimerScreen extends ConsumerStatefulWidget {
  final Book book;
  final int initialStartPage;

  const ReadingTimerScreen({
    super.key,
    required this.book,
    this.initialStartPage = 1,
  });

  @override
  ConsumerState<ReadingTimerScreen> createState() => _ReadingTimerScreenState();
}

class _ReadingTimerScreenState extends ConsumerState<ReadingTimerScreen> {
  static const _spPrefix = 'shelfcraft_reading_timer_';
  static const _uuid = Uuid();

  Timer? _periodicTimer;
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  late int _startPage;
  int? _sessionStartTimeMs;

  @override
  void initState() {
    super.initState();
    _startPage = widget.initialStartPage;
    _restoreTimerState();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBookId = prefs.getString('${_spPrefix}book_id');

    if (savedBookId == widget.book.id) {
      final isRunning = prefs.getBool('${_spPrefix}is_running') ?? false;
      final startMs = prefs.getInt('${_spPrefix}start_ms');
      final accumulated = prefs.getInt('${_spPrefix}accumulated_seconds') ?? 0;
      final savedStartPage = prefs.getInt('${_spPrefix}start_page');

      if (savedStartPage != null) {
        _startPage = savedStartPage;
      }

      if (isRunning && startMs != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final elapsedSinceStart = ((now - startMs) / 1000).round();
        setState(() {
          _isRunning = true;
          _elapsedSeconds = accumulated + elapsedSinceStart;
          _sessionStartTimeMs = startMs;
        });
        _startPeriodicTicker();
      } else {
        setState(() {
          _elapsedSeconds = accumulated;
        });
      }
    }
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_spPrefix}book_id', widget.book.id);
    await prefs.setBool('${_spPrefix}is_running', _isRunning);
    await prefs.setInt('${_spPrefix}accumulated_seconds', _elapsedSeconds);
    await prefs.setInt('${_spPrefix}start_page', _startPage);
    if (_sessionStartTimeMs != null) {
      await prefs.setInt('${_spPrefix}start_ms', _sessionStartTimeMs!);
    }
  }

  Future<void> _clearPersistedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_spPrefix}book_id');
    await prefs.remove('${_spPrefix}is_running');
    await prefs.remove('${_spPrefix}accumulated_seconds');
    await prefs.remove('${_spPrefix}start_ms');
    await prefs.remove('${_spPrefix}start_page');
  }

  void _startPeriodicTicker() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds++;
      });
      if (_elapsedSeconds % 10 == 0) {
        _persistState();
      }
    });
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _sessionStartTimeMs ??= DateTime.now().millisecondsSinceEpoch;
    });
    _startPeriodicTicker();
    _persistState();
  }

  void _pauseTimer() {
    _periodicTimer?.cancel();
    setState(() {
      _isRunning = false;
    });
    _persistState();
  }

  Future<void> _finishSession() async {
    _periodicTimer?.cancel();
    setState(() => _isRunning = false);

    final endPageController = TextEditingController(text: '${_startPage + 10}');
    final completed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Log Reading Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book: ${widget.book.title}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Time: ${_formatDuration(_elapsedSeconds)}'),
            const SizedBox(height: 16),
            TextField(
              controller: endPageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Ending Page (Started at $_startPage)',
                border: const OutlineInputBorder(),
                suffixText: '/ ${widget.book.pageCount}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Resume Timer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save Session'),
          ),
        ],
      ),
    );

    if (completed == true && mounted) {
      final endPage = int.tryParse(endPageController.text) ?? _startPage;
      final pagesRead = (endPage - _startPage).clamp(0, widget.book.pageCount);
      final duration = _elapsedSeconds > 0 ? _elapsedSeconds : 1;
      final speedPpm = (pagesRead / (duration / 60.0)).toStringAsFixed(1);

      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch;

      // 1. Insert session
      await db.sessionDao.insertSession(
        ReadingSessionsCompanion.insert(
          id: _uuid.v4(),
          bookId: widget.book.id,
          startTime: _sessionStartTimeMs ?? now,
          durationSeconds: duration,
          startPage: _startPage,
          endPage: endPage,
        ),
      );

      // 2. Update book status if reached the end
      if (endPage >= widget.book.pageCount) {
        await db.bookDao.updateBook(
          widget.book.copyWith(
            status: 'finished',
            updatedAt: now,
          ),
        );
      } else if (widget.book.status == 'tbr') {
        await db.bookDao.updateBook(
          widget.book.copyWith(
            status: 'reading',
            updatedAt: now,
          ),
        );
      }

      await _clearPersistedState();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Session saved! $pagesRead pages read ($speedPpm pages/min) 🎉',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      _startTimer();
    }
  }

  String _formatDuration(int totalSeconds) =>
      Formatters.formatDuration(totalSeconds);

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.book.spineColorHex);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus Reading Timer'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Book Title & Author
              Text(
                widget.book.title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Starting from page $_startPage of ${widget.book.pageCount}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 48),

              // Timer Display
              Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.08),
                  border: Border.all(color: color, width: 4.0),
                ),
                child: Center(
                  child: Text(
                    _formatDuration(_elapsedSeconds),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Control Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isRunning)
                    FloatingActionButton.large(
                      heroTag: 'pause_btn',
                      backgroundColor: Colors.amber.shade700,
                      onPressed: _pauseTimer,
                      child: const Icon(Icons.pause,
                          size: 36, color: Colors.white),
                    )
                  else
                    FloatingActionButton.large(
                      heroTag: 'play_btn',
                      backgroundColor: color,
                      onPressed: _startTimer,
                      child: const Icon(Icons.play_arrow,
                          size: 36, color: Colors.white),
                    ),
                  if (_elapsedSeconds > 0) ...[
                    const SizedBox(width: 24),
                    FloatingActionButton(
                      heroTag: 'stop_btn',
                      backgroundColor: Colors.red.shade600,
                      onPressed: _finishSession,
                      child: const Icon(Icons.stop, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
