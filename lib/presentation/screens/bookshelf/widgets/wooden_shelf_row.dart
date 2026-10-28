import 'package:flutter/material.dart';

/// Wood theme definition containing colors for top perspective surface, fascia, and bevels.
class ShelfWoodTheme {
  final String id;
  final String name;
  final Color topSurfaceFront;
  final Color topSurfaceBack;
  final Color fasciaColor;
  final Color fasciaHighlight;
  final Color fasciaShadow;

  const ShelfWoodTheme({
    required this.id,
    required this.name,
    required this.topSurfaceFront,
    required this.topSurfaceBack,
    required this.fasciaColor,
    required this.fasciaHighlight,
    required this.fasciaShadow,
  });

  static const oak = ShelfWoodTheme(
    id: 'oak',
    name: 'Classic Oak',
    topSurfaceFront: Color(0xFFC79C5E),
    topSurfaceBack: Color(0xFFA87E42),
    fasciaColor: Color(0xFF986F35),
    fasciaHighlight: Color(0xFFDEBA82),
    fasciaShadow: Color(0xFF6B4C20),
  );

  static const walnut = ShelfWoodTheme(
    id: 'walnut',
    name: 'Dark Walnut',
    topSurfaceFront: Color(0xFF5D4332),
    topSurfaceBack: Color(0xFF453023),
    fasciaColor: Color(0xFF38261B),
    fasciaHighlight: Color(0xFF785B46),
    fasciaShadow: Color(0xFF241710),
  );

  static const mahogany = ShelfWoodTheme(
    id: 'mahogany',
    name: 'Rich Mahogany',
    topSurfaceFront: Color(0xFF753B35),
    topSurfaceBack: Color(0xFF582823),
    fasciaColor: Color(0xFF4B1F1B),
    fasciaHighlight: Color(0xFF96524B),
    fasciaShadow: Color(0xFF311310),
  );

  static const birch = ShelfWoodTheme(
    id: 'birch',
    name: 'Light Birch',
    topSurfaceFront: Color(0xFFE5D7C2),
    topSurfaceBack: Color(0xFFCFC0A8),
    fasciaColor: Color(0xFFBAAA91),
    fasciaHighlight: Color(0xFFF5EFE4),
    fasciaShadow: Color(0xFF968770),
  );

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

/// CustomPainter rendering the 2.5D wooden shelf:
/// 1. Top perspective trapezoid surface.
/// 2. Front wooden fascia with top bevel highlight and bottom shadow.
/// 3. Soft bottom drop shadow cast onto the wall below.
class WoodenShelfPainter extends CustomPainter {
  final ShelfWoodTheme woodTheme;
  final double topSurfaceDepth;
  final double fasciaHeight;
  final double shadowDepth;

  WoodenShelfPainter({
    required this.woodTheme,
    this.topSurfaceDepth = 14.0,
    this.fasciaHeight = 18.0,
    this.shadowDepth = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // 1. Top Surface Perspective Trapezoid
    final topSurfacePath = Path()
      ..moveTo(0, topSurfaceDepth)
      ..lineTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w, topSurfaceDepth)
      ..close();

    final topSurfacePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          woodTheme.topSurfaceBack,
          woodTheme.topSurfaceFront,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, topSurfaceDepth));

    canvas.drawPath(topSurfacePath, topSurfacePaint);

    // Subtle contact shadow where books meet shelf back edge
    final backEdgePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(w, 0), backEdgePaint);

    // 2. Front Fascia
    final fasciaRect = Rect.fromLTWH(0, topSurfaceDepth, w, fasciaHeight);
    final fasciaPaint = Paint()..color = woodTheme.fasciaColor;
    canvas.drawRect(fasciaRect, fasciaPaint);

    // Top Bevel Highlight Line
    final highlightPaint = Paint()
      ..color = woodTheme.fasciaHighlight
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, topSurfaceDepth),
      Offset(w, topSurfaceDepth),
      highlightPaint,
    );

    // Bottom Fascia Groove Shadow Line
    final bottomGroovePaint = Paint()
      ..color = woodTheme.fasciaShadow
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, topSurfaceDepth + fasciaHeight),
      Offset(w, topSurfaceDepth + fasciaHeight),
      bottomGroovePaint,
    );

    // 3. Soft Drop Shadow below the fascia onto the wall
    final shadowRect = Rect.fromLTWH(
      0,
      topSurfaceDepth + fasciaHeight,
      w,
      shadowDepth,
    );
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.black.withOpacity(0.35),
          Colors.black.withOpacity(0.12),
          Colors.transparent,
        ],
      ).createShader(shadowRect);

    canvas.drawRect(shadowRect, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant WoodenShelfPainter oldDelegate) {
    return oldDelegate.woodTheme != woodTheme ||
        oldDelegate.topSurfaceDepth != topSurfaceDepth ||
        oldDelegate.fasciaHeight != fasciaHeight;
  }
}

/// A complete 2.5D Wooden Shelf Row containing books and props.
/// Supports horizontal scrolling and optional drag-and-drop reordering.
class WoodenShelfRow extends StatelessWidget {
  final String shelfId;
  final String shelfName;
  final String woodThemeId;
  final Color wallColor;
  final List<Widget> items;
  final bool isReorderable;
  final ReorderCallback? onReorder;
  final double shelfHeight;

  const WoodenShelfRow({
    super.key,
    required this.shelfId,
    required this.shelfName,
    this.woodThemeId = 'oak',
    this.wallColor = const Color(0xFFF7F2EC),
    required this.items,
    this.isReorderable = false,
    this.onReorder,
    this.shelfHeight = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final woodTheme = ShelfWoodTheme.fromId(woodThemeId);
    const topSurfaceDepth = 14.0;
    const fasciaHeight = 18.0;
    const shadowDepth = 10.0;
    const woodStructureHeight = topSurfaceDepth + fasciaHeight + shadowDepth;

    return RepaintBoundary(
      child: Container(
        color: wallColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Shelf Content Area (Books & Props rest bottom-aligned on the shelf)
            SizedBox(
              height: shelfHeight,
              child: isReorderable && onReorder != null
                  ? ReorderableListView(
                      scrollDirection: Axis.horizontal,
                      onReorder: onReorder!,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        for (int i = 0; i < items.length; i++)
                          KeyedSubtree(
                            key: items[i].key ?? ValueKey('$shelfId-item-$i'),
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: items[i],
                            ),
                          ),
                      ],
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: items,
                      ),
                    ),
            ),

            // Wooden Shelf Structure (Top Surface, Bevel Fascia, Drop Shadow)
            CustomPaint(
              size: const Size(double.infinity, woodStructureHeight),
              painter: WoodenShelfPainter(
                woodTheme: woodTheme,
                topSurfaceDepth: topSurfaceDepth,
                fasciaHeight: fasciaHeight,
                shadowDepth: shadowDepth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
