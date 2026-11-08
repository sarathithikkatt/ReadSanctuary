import 'package:flutter/material.dart';

/// Decorative shelf item definition (plants, candles, coffee mugs, spacers, etc.).
class ShelfPropItem {
  final String id;
  final String title;
  final String subtitle;
  final String? assetPath;
  final IconData fallbackIcon;
  final bool isSpacer;

  const ShelfPropItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.assetPath,
    this.fallbackIcon = Icons.eco,
    this.isSpacer = false,
  });

  static const List<ShelfPropItem> all = [
    ShelfPropItem(
      id: 'plant_monstera',
      title: 'Monstera Deliciosa Plant',
      subtitle: 'Lush potted greenery in terracotta pot',
      assetPath: 'assets/images/props/plant_monstera.png',
      fallbackIcon: Icons.eco,
    ),
    ShelfPropItem(
      id: 'plant_succulent',
      title: 'Succulent Plant',
      subtitle: 'Minimalist ceramic potted succulent',
      assetPath: 'assets/images/props/plant_succulent.png',
      fallbackIcon: Icons.yard_outlined,
    ),
    ShelfPropItem(
      id: 'candle_amber',
      title: 'Amber Glow Candle',
      subtitle: 'Warm flickering scented candle in amber glass',
      assetPath: 'assets/images/props/candle_amber.png',
      fallbackIcon: Icons.fireplace,
    ),
    ShelfPropItem(
      id: 'cup_coffee',
      title: 'Artisan Coffee Mug',
      subtitle: 'Steaming latte in handcrafted mug',
      assetPath: 'assets/images/props/cup_coffee.png',
      fallbackIcon: Icons.coffee,
    ),
    ShelfPropItem(
      id: 'bookend_brass',
      title: 'Vintage Brass Bookend',
      subtitle: 'Polished metallic arch bookend',
      assetPath: 'assets/images/props/bookend_brass.png',
      fallbackIcon: Icons.vertical_align_bottom,
    ),
    ShelfPropItem(
      id: 'cat_sleeping',
      title: 'Sleeping Cat',
      subtitle: 'Curled ginger companion resting quietly',
      assetPath: 'assets/images/props/cat_sleeping.png',
      fallbackIcon: Icons.pets,
    ),
    ShelfPropItem(
      id: 'clock_vintage',
      title: 'Vintage Desk Clock',
      subtitle: 'Antique brass analog mantel clock',
      assetPath: 'assets/images/props/clock_vintage.png',
      fallbackIcon: Icons.access_time,
    ),
    ShelfPropItem(
      id: 'gap',
      title: 'Empty Spacer Gap',
      subtitle: '28dp breathing room between books',
      fallbackIcon: Icons.space_bar,
      isSpacer: true,
    ),
  ];

  static ShelfPropItem? findById(String id) {
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
