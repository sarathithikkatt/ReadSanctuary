import 'dart:convert';
import 'package:intl/intl.dart';

/// General formatting utilities for authors, series strings, and durations.
abstract final class Formatters {
  /// Safely decodes a JSON-encoded authors string or returns a single fallback author.
  static List<String> parseAuthors(String? rawAuthors) {
    if (rawAuthors == null || rawAuthors.trim().isEmpty) {
      return ['Unknown Author'];
    }
    try {
      final decoded = jsonDecode(rawAuthors);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [decoded.toString()];
    } catch (_) {
      return [rawAuthors.trim()];
    }
  }

  /// Formats authors list as a comma-separated string.
  static String formatAuthors(String? rawAuthors) {
    final list = parseAuthors(rawAuthors);
    return list.isEmpty ? 'Unknown Author' : list.join(', ');
  }

  /// Formats a series name and fractional index (e.g. "The Stormlight Archive #1.5").
  static String formatSeries(String? seriesName, double? seriesIndex) {
    if (seriesName == null || seriesName.trim().isEmpty) return '';
    if (seriesIndex != null) {
      final idxStr = seriesIndex % 1 == 0
          ? seriesIndex.toInt().toString()
          : seriesIndex.toString();
      return '$seriesName #$idxStr';
    }
    return seriesName;
  }

  /// Formats duration in seconds into HH:MM:SS or MM:SS.
  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats epoch timestamp into localized date.
  static String formatDate(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return DateFormat.yMMMd().format(date);
  }

  /// Formats epoch timestamp into localized date and time.
  static String formatDateTime(int epochMs) {
    final date = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return DateFormat.yMMMd().add_jm().format(date);
  }
}
