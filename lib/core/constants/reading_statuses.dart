import 'package:flutter/material.dart';

/// Reading progress states for books.
enum ReadingStatus {
  tbr('tbr', 'Want to Read (TBR)', Colors.blueGrey, Icons.bookmark_outline),
  reading('reading', 'Currently Reading', Colors.amber, Icons.auto_stories),
  finished('finished', 'Finished', Colors.green, Icons.check_circle_outline),
  dnf('dnf', 'Did Not Finish (DNF)', Colors.deepOrange, Icons.cancel_outlined),
  lent('lent', 'Lent Out', Colors.purple, Icons.people_outline);

  final String id;
  final String label;
  final Color color;
  final IconData icon;

  const ReadingStatus(this.id, this.label, this.color, this.icon);

  static ReadingStatus fromId(String? id) {
    if (id == null) return ReadingStatus.tbr;
    return ReadingStatus.values.firstWhere(
      (s) => s.id.toLowerCase() == id.toLowerCase(),
      orElse: () => ReadingStatus.tbr,
    );
  }

  static String getLabel(String status) => fromId(status).label;
  static Color getColor(String status) => fromId(status).color;
}
