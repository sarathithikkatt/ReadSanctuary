import 'package:flutter/material.dart';

/// Renders decorative props (plants, candles, bookends, coffee mug, cat, clock)
/// and gap spacers on 2.5D wooden shelves.
class ShelfPropWidget extends StatelessWidget {
  final String propAssetId;
  final double? customWidth;

  const ShelfPropWidget({
    super.key,
    required this.propAssetId,
    this.customWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (propAssetId == 'gap') {
      return SizedBox(width: customWidth ?? 28.0);
    }

    final propConfig = _propMetadata[propAssetId];
    if (propConfig != null) {
      return _buildImageProp(
        assetPath: propConfig.assetPath,
        height: propConfig.height,
        semanticLabel: propConfig.label,
        fallbackWidget: propConfig.fallbackBuilder(context),
      );
    }

    return SizedBox(width: customWidth ?? 20.0);
  }

  Widget _buildImageProp({
    required String assetPath,
    required double height,
    required String semanticLabel,
    required Widget fallbackWidget,
  }) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Ambient shelf contact shadow
          Positioned(
            bottom: 0,
            child: Container(
              width: height * 0.55,
              height: 4.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 5.0,
                    spreadRadius: 1.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // High-resolution prop asset with smooth scaling
          Image.asset(
            assetPath,
            height: height,
            fit: BoxFit.contain,
            semanticLabel: semanticLabel,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => fallbackWidget,
          ),
        ],
      ),
    );
  }

  static final Map<String, _PropDef> _propMetadata = {
    'plant_monstera': _PropDef(
      assetPath: 'assets/images/props/plant_monstera.png',
      height: 125.0,
      label: 'Potted Monstera Deliciosa',
      fallbackBuilder: (_) => _fallbackIcon(Icons.eco, Colors.green.shade800),
    ),
    'plant_succulent': _PropDef(
      assetPath: 'assets/images/props/plant_succulent.png',
      height: 75.0,
      label: 'Potted Succulent',
      fallbackBuilder: (_) => _fallbackIcon(Icons.spa, Colors.teal.shade700),
    ),
    'candle_amber': _PropDef(
      assetPath: 'assets/images/props/candle_amber.png',
      height: 70.0,
      label: 'Amber Scented Candle',
      fallbackBuilder: (_) =>
          _fallbackIcon(Icons.local_fire_department, Colors.amber.shade800),
    ),
    'cup_coffee': _PropDef(
      assetPath: 'assets/images/props/cup_coffee.png',
      height: 55.0,
      label: 'Ceramic Coffee Mug',
      fallbackBuilder: (_) =>
          _fallbackIcon(Icons.coffee, Colors.brown.shade700),
    ),
    'bookend_brass': _PropDef(
      assetPath: 'assets/images/props/bookend_brass.png',
      height: 95.0,
      label: 'Vintage Brass Bookend',
      fallbackBuilder: (_) =>
          _fallbackIcon(Icons.crop_portrait, const Color(0xFFB8860B)),
    ),
    'cat_sleeping': _PropDef(
      assetPath: 'assets/images/props/cat_sleeping.png',
      height: 52.0,
      label: 'Curled Sleeping Cat',
      fallbackBuilder: (_) => _fallbackIcon(Icons.pets, Colors.orange.shade800),
    ),
    'clock_vintage': _PropDef(
      assetPath: 'assets/images/props/clock_vintage.png',
      height: 78.0,
      label: 'Vintage Desk Clock',
      fallbackBuilder: (_) =>
          _fallbackIcon(Icons.access_time, Colors.amber.shade900),
    ),
  };

  static Widget _fallbackIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, size: 36.0, color: color),
    );
  }
}

class _PropDef {
  final String assetPath;
  final double height;
  final String label;
  final Widget Function(BuildContext) fallbackBuilder;

  const _PropDef({
    required this.assetPath,
    required this.height,
    required this.label,
    required this.fallbackBuilder,
  });
}
