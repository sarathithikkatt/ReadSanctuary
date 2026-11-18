import 'dart:io';
import 'package:flutter/material.dart';

import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/services/custom_props_service.dart';

/// Renders decorative props (plants, candles, bookends, coffee mug, cat, clock,
/// vector decor items, and user-uploaded custom props) and gap spacers on 2.5D wooden shelves.
class ShelfPropWidget extends StatelessWidget {
  final String propAssetId;
  final double? customWidth;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ShelfPropWidget({
    super.key,
    required this.propAssetId,
    this.customWidth,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (propAssetId == 'gap') {
      content = SizedBox(width: customWidth ?? 28.0);
    } else {
      // 1. Built-in asset props
      final propConfig = _propMetadata[propAssetId];
      if (propConfig != null) {
        content = _buildImageProp(
          assetPath: propConfig.assetPath,
          height: propConfig.height,
          semanticLabel: propConfig.label,
          fallbackWidget: propConfig.fallbackBuilder(context),
        );
      } else {
        // 2. Built-in vector props
        final vectorConfig = _vectorPropMetadata[propAssetId];
        if (vectorConfig != null) {
          content = _buildVectorProp(
            icon: vectorConfig.icon,
            primaryColor: vectorConfig.primaryColor,
            secondaryColor: vectorConfig.secondaryColor,
            height: vectorConfig.height,
            label: vectorConfig.label,
          );
        } else if (propAssetId.startsWith('custom_') ||
            propAssetId.startsWith('custom:') ||
            propAssetId.contains('props/')) {
          // 3. User-created custom props
          content = _buildCustomUserProp(context);
        } else {
          content = SizedBox(width: customWidth ?? 20.0);
        }
      }
    }

    if (onTap != null || onLongPress != null) {
      return GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }

  Widget _buildCustomUserProp(BuildContext context) {
    String cleanId = propAssetId;
    if (cleanId.startsWith('custom:')) {
      cleanId = cleanId.substring(7);
    }

    // Look up cached custom prop item
    final customItem = CustomPropsNotifier.getCached(cleanId);
    final relativePath = customItem?.relativeImagePath ??
        (cleanId.contains('props/') ? cleanId : 'props/$cleanId.png');
    final propHeight = customItem?.height ?? 80.0;
    final propLabel = customItem?.name ?? 'Custom Prop';

    final syncPath = ImageStorageHelper.resolvePathSync(relativePath);
    if (syncPath != null) {
      final file = File(syncPath);
      if (file.existsSync()) {
        return _buildFileProp(
          file: file,
          height: propHeight,
          semanticLabel: propLabel,
          fallbackWidget: _fallbackIcon(Icons.palette, Colors.amber.shade800),
        );
      }
    }

    // Fallback to async path resolution if sync path is not yet available
    return FutureBuilder<String>(
      future: ImageStorageHelper().resolveAbsolutePath(relativePath),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final file = File(snapshot.data!);
          if (file.existsSync()) {
            return _buildFileProp(
              file: file,
              height: propHeight,
              semanticLabel: propLabel,
              fallbackWidget: _fallbackIcon(Icons.palette, Colors.amber.shade800),
            );
          }
        }
        return _fallbackIcon(Icons.palette_outlined, Colors.amber.shade700);
      },
    );
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

  Widget _buildFileProp({
    required File file,
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
          // High-resolution custom prop image with smooth scaling
          Image.file(
            file,
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

  Widget _buildVectorProp({
    required IconData icon,
    required Color primaryColor,
    required Color secondaryColor,
    required double height,
    required String label,
  }) {
    final iconSize = height * 0.58;
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
              width: height * 0.5,
              height: 4.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          // Stylized Vector Prop Body
          Semantics(
            label: label,
            child: Container(
              width: height * 0.72,
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    secondaryColor.withOpacity(0.18),
                    primaryColor.withOpacity(0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.35),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: iconSize,
                  color: primaryColor,
                ),
              ),
            ),
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

  static final Map<String, _VectorPropDef> _vectorPropMetadata = {
    'reading_glasses': const _VectorPropDef(
      icon: Icons.auto_stories,
      primaryColor: Color(0xFF8D6E63),
      secondaryColor: Color(0xFFD7CCC8),
      height: 60.0,
      label: 'Vintage Reading Glasses',
    ),
    'globe_antique': const _VectorPropDef(
      icon: Icons.public,
      primaryColor: Color(0xFF00796B),
      secondaryColor: Color(0xFF80CBC4),
      height: 78.0,
      label: 'Antique Desktop Globe',
    ),
    'quill_inkpot': const _VectorPropDef(
      icon: Icons.history_edu,
      primaryColor: Color(0xFF5D4037),
      secondaryColor: Color(0xFFBCAAA4),
      height: 72.0,
      label: 'Feather Quill & Inkwell',
    ),
    'crystal_prism': const _VectorPropDef(
      icon: Icons.diamond_outlined,
      primaryColor: Color(0xFF7B1FA2),
      secondaryColor: Color(0xFFCE93D8),
      height: 65.0,
      label: 'Amethyst Crystal Geode',
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

class _VectorPropDef {
  final IconData icon;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;
  final String label;

  const _VectorPropDef({
    required this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.height,
    required this.label,
  });
}
