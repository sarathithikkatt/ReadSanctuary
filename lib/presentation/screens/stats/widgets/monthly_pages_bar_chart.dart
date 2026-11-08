import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/local/database.dart';

/// Bar chart illustrating pages read aggregated by the last 6 months.
class MonthlyPagesBarChart extends StatelessWidget {
  final List<ReadingSession> sessions;

  const MonthlyPagesBarChart({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    final maxPages = monthsData.values.fold(0, (max, v) => v > max ? v : max);
    final calculatedMaxY = maxPages > 0 ? (maxPages * 1.25) : 10.0;

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
                  minY: 0.0,
                  maxY: calculatedMaxY,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final slot = value.toInt();
                          if (slot < 0 || slot > 5) {
                            return const SizedBox.shrink();
                          }
                          final dt = DateTime(now.year, now.month - (5 - slot));
                          final label = DateFormat('MMM').format(dt);
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(label,
                                style: const TextStyle(fontSize: 11)),
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
}
