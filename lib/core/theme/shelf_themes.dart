import 'package:flutter/material.dart';

/// Wood theme definition containing colors for top perspective surface, fascia, and bevels.
class ShelfWoodTheme {
  final String id;
  final String name;
  final String description;
  final Color topSurfaceFront;
  final Color topSurfaceBack;
  final Color fasciaColor;
  final Color fasciaHighlight;
  final Color fasciaShadow;
  final String? textureAssetPath;

  const ShelfWoodTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.topSurfaceFront,
    required this.topSurfaceBack,
    required this.fasciaColor,
    required this.fasciaHighlight,
    required this.fasciaShadow,
    this.textureAssetPath,
  });

  static const oak = ShelfWoodTheme(
    id: 'oak',
    name: 'Classic Oak',
    description: 'Natural honey oak with warm grain lines',
    topSurfaceFront: Color(0xFFC79C5E),
    topSurfaceBack: Color(0xFFA87E42),
    fasciaColor: Color(0xFF986F35),
    fasciaHighlight: Color(0xFFDEBA82),
    fasciaShadow: Color(0xFF6B4C20),
    textureAssetPath: 'assets/images/textures/wood_oak.png',
  );

  static const walnut = ShelfWoodTheme(
    id: 'walnut',
    name: 'Dark Walnut',
    description: 'Rich espresso finish for home libraries',
    topSurfaceFront: Color(0xFF5D4332),
    topSurfaceBack: Color(0xFF453023),
    fasciaColor: Color(0xFF38261B),
    fasciaHighlight: Color(0xFF785B46),
    fasciaShadow: Color(0xFF241710),
    textureAssetPath: 'assets/images/textures/wood_walnut.png',
  );

  static const mahogany = ShelfWoodTheme(
    id: 'mahogany',
    name: 'Rich Mahogany',
    description: 'Polished antique reddish timber finish',
    topSurfaceFront: Color(0xFF753B35),
    topSurfaceBack: Color(0xFF582823),
    fasciaColor: Color(0xFF4B1F1B),
    fasciaHighlight: Color(0xFF96524B),
    fasciaShadow: Color(0xFF311310),
    textureAssetPath: 'assets/images/textures/wood_mahogany.png',
  );

  static const birch = ShelfWoodTheme(
    id: 'birch',
    name: 'Light Birch',
    description: 'Clean Scandinavian minimalist look',
    topSurfaceFront: Color(0xFFE5D7C2),
    topSurfaceBack: Color(0xFFCFC0A8),
    fasciaColor: Color(0xFFBAAA91),
    fasciaHighlight: Color(0xFFF5EFE4),
    fasciaShadow: Color(0xFF968770),
    textureAssetPath: 'assets/images/textures/wood_birch.png',
  );

  static const List<ShelfWoodTheme> all = [oak, walnut, mahogany, birch];

  static ShelfWoodTheme fromId(String id) {
    switch (id.toLowerCase()) {
      case 'walnut':
        return walnut;
      case 'mahogany':
        return mahogany;
      case 'birch':
        return birch;
      case 'oak':
      default:
        return oak;
    }
  }
}

/// Wall backdrop theme definition for shelf backgrounds.
class ShelfWallTheme {
  final String id;
  final String name;
  final String description;
  final String? assetPath;
  final Color fallbackColor;
  final bool isDark;

  const ShelfWallTheme({
    required this.id,
    required this.name,
    required this.description,
    this.assetPath,
    required this.fallbackColor,
    this.isDark = false,
  });

  static const warmCream = ShelfWallTheme(
    id: 'warm_cream',
    name: 'Warm Cream Plaster',
    description: 'Cozy textured plaster with gentle ambient light',
    assetPath: 'assets/images/textures/wall_warm_cream.png',
    fallbackColor: Color(0xFFF7F2EC),
  );

  static const darkAcademia = ShelfWallTheme(
    id: 'dark_academia',
    name: 'Dark Academia Study',
    description: 'Deep forest green library wall with aged patina',
    assetPath: 'assets/images/textures/wall_dark_academia.png',
    fallbackColor: Color(0xFF1E2822),
    isDark: true,
  );

  static const botanical = ShelfWallTheme(
    id: 'botanical',
    name: 'Vintage Botanical Sage',
    description: 'Subtle foliage and floral wallpaper pattern',
    assetPath: 'assets/images/textures/wall_botanical.png',
    fallbackColor: Color(0xFFD3DDD0),
  );

  static const classicWhite = ShelfWallTheme(
    id: 'classic_white',
    name: 'Clean Minimalist White',
    description: 'Crisp modern studio backdrop',
    fallbackColor: Color(0xFFFAFAFA),
  );

  static const List<ShelfWallTheme> all = [
    warmCream,
    darkAcademia,
    botanical,
    classicWhite
  ];

  static ShelfWallTheme fromId(String id) {
    switch (id.toLowerCase()) {
      case 'dark_academia':
        return darkAcademia;
      case 'botanical':
        return botanical;
      case 'classic_white':
        return classicWhite;
      case 'warm_cream':
      default:
        return warmCream;
    }
  }
}
