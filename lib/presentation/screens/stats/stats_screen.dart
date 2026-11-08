import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/streak_calculator.dart';
import '../../../data/local/database.dart';
import '../timer/dialogs/log_manual_session_dialog.dart';
import 'widgets/format_distribution_pie_chart.dart';
import 'widgets/monthly_pages_bar_chart.dart';
import 'widgets/reading_metrics_row.dart';
import 'widgets/streak_cards_row.dart';
import 'widgets/yearly_goal_card.dart';

/// Analytics & Reading Statistics Screen displaying daily reading streak cards,
/// pages-read per month bar chart, physical format distribution pie chart, and yearly goal progress.
class StatsScreen extends ConsumerStatefulWidget {
  final int yearlyGoal;

  const StatsScreen({
    super.key,
    this.yearlyGoal = 25,
  });

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  static const String _spKeyYearlyGoal = 'shelfcraft_yearly_goal';
  late int _yearlyGoal;

  @override
  void initState() {
    super.initState();
    _yearlyGoal = widget.yearlyGoal;
    _loadYearlyGoal();
  }

  Future<void> _loadYearlyGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_spKeyYearlyGoal);
      if (saved != null && saved > 0 && mounted) {
        setState(() => _yearlyGoal = saved);
      }
    } catch (_) {}
  }

  Future<void> _editYearlyGoal() async {
    final ctrl = TextEditingController(text: '$_yearlyGoal');
    final newGoal = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Yearly Reading Challenge'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Books for This Year',
            hintText: 'e.g. 25, 52, 100',
            prefixIcon: Icon(Icons.flag_outlined),
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(ctrl.text.trim());
              if (parsed != null && parsed > 0) {
                Navigator.of(ctx).pop(parsed);
              }
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );

    if (newGoal != null && mounted) {
      setState(() => _yearlyGoal = newGoal);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_spKeyYearlyGoal, newGoal);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionDao = ref.watch(sessionDaoProvider);
    final bookDao = ref.watch(bookDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Insights & Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_calendar_outlined),
            tooltip: 'Log Past Session (Fix Streak)',
            onPressed: () => LogManualSessionDialog.show(context),
          ),
        ],
      ),
      body: StreamBuilder<List<ReadingSession>>(
        stream: sessionDao.watchAllSessions(),
        builder: (context, sessionSnap) {
          final sessions = sessionSnap.data ?? [];
          return StreamBuilder<List<Book>>(
            stream: bookDao.watchAllBooks(),
            builder: (context, bookSnap) {
              if (sessionSnap.connectionState == ConnectionState.waiting &&
                  bookSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final books = bookSnap.data ?? [];
              final streak = StreakCalculator.calculate(
                sessionEpochMs: sessions.map((s) => s.startTime),
              );

              return ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 1. Streak Cards Row
                  StreakCardsRow(streak: streak),
                  const SizedBox(height: 20),

                  // 2. Yearly Reading Goal Card with Edit capability
                  YearlyGoalCard(
                    books: books,
                    yearlyGoal: _yearlyGoal,
                    onEditGoal: _editYearlyGoal,
                  ),
                  const SizedBox(height: 24),

                  // 3. Overall Metric Summary
                  ReadingMetricsRow(sessions: sessions, books: books),
                  const SizedBox(height: 28),

                  // 4. Monthly Pages Read Bar Chart
                  MonthlyPagesBarChart(sessions: sessions),
                  const SizedBox(height: 28),

                  // 5. Book Format Distribution Pie Chart
                  FormatDistributionPieChart(books: books),
                  const SizedBox(height: 32),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
