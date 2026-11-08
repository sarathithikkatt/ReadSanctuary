import 'dart:io';
import 'dart:math' as math;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/book_formats.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/local/database.dart';
import '../../book_detail/book_detail_screen.dart';
import '../../pdf_reader/pdf_reader_screen.dart';
import 'book_spine_25d_widget.dart';

/// Interactive 3D Model of a book supporting real-time 360° touch rotation,
/// dynamic thickness and height based on page count and format, realistic page-edge
/// texturing, spine typography, and direct reading/detail action shortcuts.
class Interactive3dBookViewer extends StatefulWidget {
  final Book book;

  const Interactive3dBookViewer({
    super.key,
    required this.book,
  });

  /// Opens the 3D book inspection dialog.
  static Future<void> show(BuildContext context, {required Book book}) async {
    HapticFeedback.mediumImpact();
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss 3D Viewer',
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => Interactive3dBookViewer(book: book),
      transitionBuilder: (context, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return ScaleTransition(
          scale: curved,
          child: FadeTransition(opacity: anim, child: child),
        );
      },
    );
  }

  @override
  State<Interactive3dBookViewer> createState() =>
      _Interactive3dBookViewerState();
}

class _Interactive3dBookViewerState extends State<Interactive3dBookViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Animation<double>? _rotXAnim;
  Animation<double>? _rotYAnim;

  double _rotationY = 0.45; // Start with attractive 3D angle
  double _rotationX = -0.12;

  String? _resolvedCoverAbsPath;
  String? _resolvedSpineAbsPath;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
        setState(() {
          if (_rotXAnim != null) _rotationX = _rotXAnim!.value;
          if (_rotYAnim != null) _rotationY = _rotYAnim!.value;
        });
      });
    _resolveImages();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _resolveImages() async {
    final storage = ImageStorageHelper();
    if (widget.book.coverPath != null) {
      final abs = await storage.resolveAbsolutePath(widget.book.coverPath!);
      if (mounted) setState(() => _resolvedCoverAbsPath = abs);
    }
    if (widget.book.customSpinePath != null) {
      final abs =
          await storage.resolveAbsolutePath(widget.book.customSpinePath!);
      if (mounted) setState(() => _resolvedSpineAbsPath = abs);
    }
  }

  void _animateTo(double targetX, double targetY) {
    _rotXAnim = Tween<double>(begin: _rotationX, end: targetX).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _rotYAnim = Tween<double>(begin: _rotationY, end: targetY).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate realistic dimensions
    final baseHeight = BookFormat.calculateSpineHeight(widget.book.format);
    final bookHeight = (baseHeight * 1.55).clamp(240.0, 290.0);
    final bookWidth = bookHeight * 0.67;
    // Dynamic thickness derived from page count
    final bookThickness =
        BookSpine25DWidget.calculateSpineWidth(widget.book.pageCount) * 1.35;

    final hasPdf =
        widget.book.pdfPath != null && widget.book.pdfPath!.isNotEmpty;
    final authorsList = Formatters.parseAuthors(widget.book.authors);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Title & Close Button
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${authorsList.join(', ')} • ${widget.book.pageCount} pages (${widget.book.format.toUpperCase()})',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Close 3D View',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Camera Angle Preset Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  _buildAngleChip('3D View', -0.12, 0.45),
                  const SizedBox(width: 8),
                  _buildAngleChip('Front Cover', 0.0, 0.0),
                  const SizedBox(width: 8),
                  _buildAngleChip('Spine', 0.0, math.pi / 2),
                  const SizedBox(width: 8),
                  _buildAngleChip('Page Edges', 0.0, -math.pi / 2),
                  const SizedBox(width: 8),
                  _buildAngleChip('Back Cover', 0.0, math.pi),
                ],
              ),
            ),

            // 3D Canvas Area with Interactive Pan Gestures
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (details) {
                  setState(() {
                    _rotationY += details.delta.dx * 0.013;
                    _rotationX = (_rotationX - details.delta.dy * 0.013)
                        .clamp(-0.85, 0.85);
                  });
                },
                child: Center(
                  child: _build3DBookObject(
                    width: bookWidth,
                    height: bookHeight,
                    thickness: bookThickness,
                  ),
                ),
              ),
            ),

            // Interaction Hint
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                'Drag anywhere to rotate book in 360°',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 12),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade900.withOpacity(0.9),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20.0)),
              ),
              child: Row(
                children: [
                  if (hasPdf)
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.auto_stories),
                        label: Text(
                          widget.book.lastReadPage > 1
                              ? 'Read (Pg ${widget.book.lastReadPage})'
                              : 'Read Book (PDF)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PdfReaderScreen(book: widget.book),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload PDF'),
                        onPressed: () async {
                          final storage = ImageStorageHelper();
                          final path = await storage.pickAndSavePdf(
                              bookId: widget.book.id);
                          if (path != null && context.mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookDetailScreen(bookId: widget.book.id),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BookDetailScreen(bookId: widget.book.id),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngleChip(String label, double x, double y) {
    return ActionChip(
      backgroundColor: Colors.white.withOpacity(0.15),
      label: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
      onPressed: () => _animateTo(x, y),
    );
  }

  /// Constructs the 3D book cuboid with front, back, spine, and striated paper block edges.
  Widget _build3DBookObject({
    required double width,
    required double height,
    required double thickness,
  }) {
    final hx = width / 2;
    final hy = height / 2;
    final hz = thickness / 2;

    // Determine front/back facing direction using cosine of Y rotation
    final cosY = math.cos(_rotationY);
    final isFrontVisible = cosY >= 0;

    final spineColor = Color(widget.book.spineColorHex);
    final spineTextColor = Color(widget.book.spineTextHex);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0013) // Tangible 3D perspective
        ..rotateX(_rotationX)
        ..rotateY(_rotationY),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. Back Cover Face (rendered behind when front is visible)
          if (!isFrontVisible)
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(0.0, 0.0, -hz)
                ..rotateY(math.pi),
              child: _buildBackCover(width, height, spineColor),
            ),

          // 2. Page Block Top (Head Edge)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, -hy, 0.0)
              ..rotateX(-math.pi / 2),
            child: _buildPaperEdge(width, thickness),
          ),

          // 3. Page Block Bottom (Tail Edge)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, hy, 0.0)
              ..rotateX(math.pi / 2),
            child: _buildPaperEdge(width, thickness),
          ),

          // 4. Spine Face (Left)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(-hx, 0.0, 0.0)
              ..rotateY(-math.pi / 2),
            child: _buildSpineFace(thickness, height, spineColor, spineTextColor),
          ),

          // 5. Page Block Right Edge (Fore-Edge with page striations)
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(hx, 0.0, 0.0)
              ..rotateY(math.pi / 2),
            child: _buildForeEdge(thickness, height),
          ),

          // 6. Front Cover Face
          if (isFrontVisible)
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..translate(0.0, 0.0, hz),
              child: _buildFrontCover(width, height, spineColor),
            )
          else
            // Render back cover on top when rotated around
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..translate(0.0, 0.0, -hz)
                ..rotateY(math.pi),
              child: _buildBackCover(width, height, spineColor),
            ),
        ],
      ),
    );
  }

  Widget _buildFrontCover(double w, double h, Color baseColor) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: const BorderRadius.horizontal(right: Radius.circular(5.0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16.0,
            spreadRadius: 2.0,
            offset: Offset(4.0, 8.0),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            const BorderRadius.horizontal(right: Radius.circular(5.0)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image cover (Local or Network)
            if (_resolvedCoverAbsPath != null &&
                File(_resolvedCoverAbsPath!).existsSync())
              Image.file(File(_resolvedCoverAbsPath!), fit: BoxFit.cover)
            else if (widget.book.coverPath != null &&
                widget.book.coverPath!.startsWith('http'))
              CachedNetworkImage(
                imageUrl: widget.book.coverPath!,
                fit: BoxFit.cover,
              )
            else
              _buildProceduralCoverArt(baseColor),

            // Spine hinge / crease groove shadow on the left edge
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 14.0,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduralCoverArt(Color baseColor) {
    final textColor = Color(widget.book.spineTextHex);
    final authorsList = Formatters.parseAuthors(widget.book.authors);

    return Container(
      color: baseColor,
      padding: const EdgeInsets.all(20.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: textColor.withOpacity(0.35), width: 1.5),
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              authorsList.isNotEmpty
                  ? authorsList.first.toUpperCase()
                  : 'AUTHOR',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 12,
                letterSpacing: 2.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            Column(
              children: [
                Icon(Icons.auto_stories,
                    size: 40, color: textColor.withOpacity(0.4)),
                const SizedBox(height: 12),
                Text(
                  widget.book.title,
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Text(
              'S H E L F C R A F T',
              style: TextStyle(
                color: textColor.withOpacity(0.5),
                fontSize: 9,
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpineFace(double thickness, double h, Color baseColor, Color textColor) {
    return Container(
      width: thickness,
      height: h,
      decoration: BoxDecoration(
        color: baseColor,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4.0),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_resolvedSpineAbsPath != null &&
              File(_resolvedSpineAbsPath!).existsSync())
            Image.file(File(_resolvedSpineAbsPath!), fit: BoxFit.cover)
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 2.0,
                    width: thickness * 0.7,
                    color: textColor.withOpacity(0.5),
                  ),
                  Expanded(
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 2.0,
                    width: thickness * 0.7,
                    color: textColor.withOpacity(0.5),
                  ),
                ],
              ),
            ),

          // Cylindrical lighting shader overlay
          Container(
            decoration: const BoxDecoration(
              gradient: BookSpine25DWidget.cylindricalLightingGradient,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCover(double w, double h, Color baseColor) {
    final textColor = Color(widget.book.spineTextHex);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(5.0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 16.0,
            offset: Offset(-4.0, 8.0),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.book.format.toUpperCase(),
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.bookmark_border,
                  size: 16, color: textColor.withOpacity(0.5)),
            ],
          ),
          Center(
            child: Text(
              widget.book.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                color: textColor.withOpacity(0.85),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Barcode Simulation
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              color: Colors.white,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  18,
                  (i) => Container(
                    width: (i % 3 == 0) ? 2.5 : 1.2,
                    height: 22,
                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForeEdge(double thickness, double h) {
    return Container(
      width: thickness,
      height: h,
      color: const Color(0xFFFAF6E9), // Realistic cream deckle paper
      child: CustomPaint(
        painter: _PaperEdgePainter(),
      ),
    );
  }

  Widget _buildPaperEdge(double width, double thickness) {
    return Container(
      width: width,
      height: thickness,
      color: const Color(0xFFF3EEDC),
      child: CustomPaint(
        painter: _PaperEdgePainter(),
      ),
    );
  }
}

/// Draws fine horizontal striations simulating layered paper pages
class _PaperEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.06)
      ..strokeWidth = 1.0;

    const step = 3.5;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
