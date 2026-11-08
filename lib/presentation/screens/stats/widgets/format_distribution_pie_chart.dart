import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../data/local/database.dart';

/// Pie chart displaying format breakdown (Paperback, Hardcover, eBook, Audiobook).
class FormatDistributionPieChart extends StatelessWidget {
  final List<Book> books;

  const FormatDistributionPieChart({
    super.key,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
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
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (hardcover > 0)
        PieChartSectionData(
          value: hardcover.toDouble(),
          title: '${((hardcover / total) * 100).round()}%',
          color: const Color(0xFF2C3E50),
          radius: 45,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (ebook > 0)
        PieChartSectionData(
          value: ebook.toDouble(),
          title: '${((ebook / total) * 100).round()}%',
          color: const Color(0xFF1E8449),
          radius: 45,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      if (audiobook > 0)
        PieChartSectionData(
          value: audiobook.toDouble(),
          title: '${((audiobook / total) * 100).round()}%',
          color: const Color(0xFF8B0000),
          radius: 45,
          titleStyle: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                        _buildLegendItem(
                            'Paperback', '$paperback', const Color(0xFFC79C5E)),
                        _buildLegendItem(
                            'Hardcover', '$hardcover', const Color(0xFF2C3E50)),
                        _buildLegendItem(
                            'eBook', '$ebook', const Color(0xFF1E8449)),
                        _buildLegendItem(
                            'Audiobook', '$audiobook', const Color(0xFF8B0000)),
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
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Text(count,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
