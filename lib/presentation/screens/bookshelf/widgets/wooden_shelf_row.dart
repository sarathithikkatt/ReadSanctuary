import 'package:flutter/material.dart';

import '../../../../core/theme/shelf_themes.dart';

export '../../../../core/theme/shelf_themes.dart';

/// CustomPainter rendering the 2.5D wooden shelf:
/// 1. Top perspective trapezoid surface with wood gradient/highlights.
/// 2. Front wooden fascia with top bevel highlight and bottom shadow groove.
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
  final String wallThemeId;
  final Color? wallColor;
  final List<Widget> items;
  final bool isReorderable;
  final ReorderCallback? onReorder;
  final double shelfHeight;

  const WoodenShelfRow({
    super.key,
    required this.shelfId,
    required this.shelfName,
    this.woodThemeId = 'oak',
    this.wallThemeId = 'warm_cream',
    this.wallColor,
    required this.items,
    this.isReorderable = true,
    this.onReorder,
    this.shelfHeight = 200.0,
  });

  @override
  Widget build(BuildContext context) {
    final woodTheme = ShelfWoodTheme.fromId(woodThemeId);
    final wallTheme = ShelfWallTheme.fromId(wallThemeId);
    const topSurfaceDepth = 14.0;
    const fasciaHeight = 18.0;
    const shadowDepth = 10.0;
    const woodStructureHeight = topSurfaceDepth + fasciaHeight + shadowDepth;

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: wallColor ?? wallTheme.fallbackColor,
          image: wallTheme.assetPath != null
              ? DecorationImage(
                  image: AssetImage(wallTheme.assetPath!),
                  fit: BoxFit.cover,
                  opacity: 0.85,
                )
              : null,
        ),
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
                      proxyDecorator: (Widget child, int index,
                          Animation<double> animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (BuildContext context, Widget? _) {
                            final double animValue = Curves.easeInOut
                                .transform(animation.value);
                            final double scale = 1.0 + (0.05 * animValue);
                            return Transform.scale(
                              scale: scale,
                              alignment: Alignment.bottomCenter,
                              child: Material(
                                color: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                child: child,
                              ),
                            );
                          },
                        );
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        for (int i = 0; i < items.length; i++)
                          KeyedSubtree(
                            key: ValueKey(
                                'shelf_item_${items[i].key ?? '$shelfId-$i'}'),
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
