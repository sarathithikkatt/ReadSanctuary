import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/streak_calculator.dart';
import '../../../data/local/database.dart';

/// Analytics & Reading Statistics Screen displaying daily reading streak cards,
/// pages-read per month bar chart, physical format distribution pie chart, and yearly goal progress.
class StatsScreen extends ConsumerWidget {
  final int yearlyGoal;

  const StatsScreen({
    super.key,
    this.yearlyGoal = 25,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionDao = ref.watch(sessionDaoProvider);
    final bookDao = ref.watch(bookDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Insights & Stats'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          sessionDao.getAllSessions(),
          bookDao.getAllBooks(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = (snapshot.data?[0] as List<ReadingSession>?) ?? [];
          final books = (snapshot.data?[1] as List<Book>?) ?? [];

          final streak = StreakCalculator.calculate(
            sessionEpochMs: sessions.map((s) => s.startTime),
          );

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // 1. Streak Cards Row
              _buildStreakRow(streak),
              const SizedBox(height: 20),

              // 2. Yearly Reading Goal Card
              _buildYearlyGoalCard(books),
              const SizedBox(height: 24),

              // 3. Overall Metric Summary
              _buildMetricCounters(sessions, books),
              const SizedBox(height: 28),

              // 4. Monthly Pages Read Bar Chart
              _buildMonthlyBarChart(sessions),
              const SizedBox(height: 28),

              // 5. Book Format Distribution Pie Chart
              _buildFormatPieChart(books),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreakRow(StreakResult streak) {
    return Row(
      children: [
        // Current Streak
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.local_fire_department, size: 36, color: Colors.amber.shade800),
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
                    streak.isTodayCompleted ? 'Read Today ✨' : 'Today Pending ⏳',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.emoji_events, size: 36, color: Colors.blue.shade700),
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

  Widget _buildYearlyGoalCard(List<Book> books) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$currentYear Reading Goal',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
            Text(
              '$percent% of goal completed',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCounters(List<ReadingSession> sessions, List<Book> books) {
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
        _buildSingleCounter('Total Books', '${books.length}', Icons.library_books),
        _buildSingleCounter('Pages Read', '$totalPages', Icons.auto_stories),
        _buildSingleCounter('Hours Spent', '$totalHours h', Icons.schedule),
      ],
    );
  }

  Widget _buildSingleCounter(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.grey.shade700),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMonthlyBarChart(List<ReadingSession> sessions) {
    // Group pages read by last 6 months
    final now = DateTime.now();
    final monthsData = <int, int>{}; // monthIndex (0..5) -> pages

    for (int i = 5; i >= 0; i--) {
      monthsData[i] = 0;
    }

    for (final s in sessions) {
      final dt = DateTime.fromMillisecondsSinceEpoch(s.startTime);
      final monthDiff = (now.year - dt.year) * 12 + (now.month - dt.month);
      if (monthDiff >= 0 && monthDiff < 6) {
        final slot = 5 - monthDiff;
        final pages = (s.endPage - s.startPage).clamp(0, 5000);
        monthsData[slot] = (monthsData[slot] ?? 0) + pages;
      }
    }

    final barGroups = <BarChartGroupData>[];
    for (int i = 0; i < 6; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: (monthsData[i] ?? 0).toDouble(),
              color: const Color(0xFF2C3E50),
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pages Read (Last 6 Months)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final slot = value.toInt();
                          if (slot < 0 || slot > 5) return const SizedBox.shrink();
                          final dt = DateTime(now.year, now.month - (5 - slot));
                          final label = DateFormat('MMM').format(dt);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(label, style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatPieChart(List<Book> books) {
    int paperback = 0;
    int hardcover = 0;
    int ebook = 0;
    int audiobook = 0;

    for (final b in books) {
      switch (b.format.toLowerCase()) {
        case 'hardcover':
          hardcover++;
          break;
        case 'ebook':
          ebook++;
          break;
        case 'audiobook':
          audiobook++;
          break;
        case 'paperback':
        default:
          paperback++;
          break;
      }
    }

    final total = books.isEmpty ? 1 : books.length;
    final sections = [
      if (paperback > 0)
        PieChartSectionData(
          value: paperback.toDouble(),
          title: '${((paperback / total) * 100).round()}%',
          color: const Color(0xFFC79C5E),
          radius: 45,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (hardcover > 0)
        PieChartSectionData(
          value: hardcover.toDouble(),
          title: '${((hardcover / total) * 100).round()}%',
          color: const Color(0xFF2C3E50),
          radius: 45,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (ebook > 0)
        PieChartSectionData(
          value: ebook.toDouble(),
          title: '${((ebook / total) * 100).round()}%',
          color: const Color(0xFF1E8449),
          radius: 45,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (audiobook > 0)
        PieChartSectionData(
          value: audiobook.toDouble(),
          title: '${((audiobook / total) * 100).round()}%',
          color: const Color(0xFF8B0000),
          radius: 45,
          titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Format Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (books.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No books in library yet'),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    height: 140,
                    width: 140,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 28,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Paperback', '$paperback', const Color(0xFFC79C5E)),
                        _buildLegendItem('Hardcover', '$hardcover', const Color(0xFF2C3E50)),
                        _buildLegendItem('eBook', '$ebook', const Color(0xFF1E8449)),
                        _buildLegendItem('Audiobook', '$audiobook', const Color(0xFF8B0000)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, String count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
