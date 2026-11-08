import 'package:flutter/material.dart';

/// Physical and digital book formats supported by ShelfCraft.
enum BookFormat {
  paperback('paperback', 'Paperback', Icons.menu_book, 170.0),
  hardcover('hardcover', 'Hardcover', Icons.book, 185.0),
  ebook('ebook', 'eBook', Icons.tablet_android, 160.0),
  audiobook('audiobook', 'Audiobook', Icons.headphones, 165.0);

  final String id;
  final String label;
  final IconData icon;
  final double defaultSpineHeight;

  const BookFormat(this.id, this.label, this.icon, this.defaultSpineHeight);

  static BookFormat fromId(String? id) {
    if (id == null) return BookFormat.paperback;
    return BookFormat.values.firstWhere(
      (f) => f.id.toLowerCase() == id.toLowerCase(),
      orElse: () => BookFormat.paperback,
    );
  }

  static double calculateSpineHeight(String format) {
    return BookFormat.fromId(format).defaultSpineHeight;
  }
}
