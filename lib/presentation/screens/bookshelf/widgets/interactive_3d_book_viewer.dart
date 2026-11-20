import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/book_formats.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/local/database.dart';
import '../../book_detail/book_detail_screen.dart';
import '../../epub_reader/epub_reader_screen.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late AnimationController _turntableController;
  late AnimationController _inertiaController;

  Animation<double>? _rotXAnim;
  Animation<double>? _rotYAnim;
  Animation<double>? _scaleAnim;

  Animation<double>? _inertiaAnimX;
  Animation<double>? _inertiaAnimY;

  double _rotationY = 0.52; // Start with attractive 3D angle (~30°)
  double _rotationX =
      -0.18; // Downward pitch (~10°) cleanly revealing top paper block
  double _scale = 1.0;
  double _baseScale = 1.0;
  bool _isAutoOrbiting = false;
  double _lastHapticAngle = 0.52;
  DateTime? _lastTapTime;

  String? _resolvedCoverAbsPath;
  String? _resolvedBackCoverAbsPath;
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
          if (_scaleAnim != null) _scale = _scaleAnim!.value;
        });
      });

    _turntableController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..addListener(() {
        if (_isAutoOrbiting) {
          setState(() {
            _rotationY += 0.008;
            _checkHapticDetents();
          });
        }
      });

    _inertiaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(() {
        setState(() {
          if (_inertiaAnimX != null) _rotationX = _inertiaAnimX!.value;
          if (_inertiaAnimY != null) _rotationY = _inertiaAnimY!.value;
          _checkHapticDetents();
        });
      });

    _resolveImages();
  }

  @override
  void dispose() {
    _animController.dispose();
    _turntableController.dispose();
    _inertiaController.dispose();
    super.dispose();
  }

  Future<void> _resolveImages() async {
    final storage = ImageStorageHelper();
    if (widget.book.coverPath != null) {
      final abs = await storage.resolveAbsolutePath(widget.book.coverPath!);
      if (mounted) setState(() => _resolvedCoverAbsPath = abs);
    }
    if (widget.book.backCoverPath != null) {
      final abs = await storage.resolveAbsolutePath(widget.book.backCoverPath!);
      if (mounted) setState(() => _resolvedBackCoverAbsPath = abs);
    }
    if (widget.book.customSpinePath != null) {
      final abs =
          await storage.resolveAbsolutePath(widget.book.customSpinePath!);
      if (mounted) setState(() => _resolvedSpineAbsPath = abs);
    }
  }

  void _stopMotion() {
    if (_isAutoOrbiting) {
      setState(() => _isAutoOrbiting = false);
      _turntableController.stop();
    }
    _inertiaController.stop();
    _animController.stop();
  }

  void _animateTo(double targetX, double targetY, {double? targetScale}) {
    _stopMotion();
    _rotXAnim = Tween<double>(begin: _rotationX, end: targetX).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _rotYAnim = Tween<double>(begin: _rotationY, end: targetY).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    if (targetScale != null) {
      _scaleAnim = Tween<double>(begin: _scale, end: targetScale).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
      );
    } else {
      _scaleAnim = null;
    }
    _animController.forward(from: 0.0);
  }

  void _checkHapticDetents() {
    final normY = ((_rotationY % (2 * math.pi)) + 2 * math.pi) % (2 * math.pi);
    const cardinals = [0.0, math.pi / 2, math.pi, 3 * math.pi / 2, 2 * math.pi];
    for (final c in cardinals) {
      if ((normY - c).abs() < 0.035) {
        if ((normY - _lastHapticAngle).abs() > 0.12) {
          _lastHapticAngle = normY;
          HapticFeedback.selectionClick();
        }
        break;
      }
    }
  }

  void _startInertia(double vx, double vy) {
    _inertiaController.stop();
    final startX = _rotationX;
    final startY = _rotationY;
    final targetY = startY + (vx * 0.0016).clamp(-1.8, 1.8);
    final targetX = (startX - (vy * 0.0014)).clamp(-0.85, 0.85);

    _inertiaAnimX = Tween<double>(begin: startX, end: targetX).animate(
      CurvedAnimation(parent: _inertiaController, curve: Curves.easeOutCubic),
    );
    _inertiaAnimY = Tween<double>(begin: startY, end: targetY).animate(
      CurvedAnimation(parent: _inertiaController, curve: Curves.easeOutCubic),
    );
    _inertiaController.forward(from: 0.0);
  }

  String _getActivePresetLabel() {
    if ((_rotationX - (-0.18)).abs() < 0.18 &&
        (_rotationY - 0.52).abs() < 0.28) {
      return '3D View';
    }
    final normY = ((_rotationY % (2 * math.pi)) + 2 * math.pi) % (2 * math.pi);
    if (_rotationX.abs() < 0.25) {
      if (normY < 0.28 || normY > (2 * math.pi - 0.28)) return 'Front Cover';
      if ((normY - math.pi / 2).abs() < 0.28) return 'Spine';
      if ((normY - math.pi).abs() < 0.28) return 'Back Cover';
      if ((normY - 3 * math.pi / 2).abs() < 0.28) return 'Page Edges';
    }
    return '';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.25,
            colors: [
              Color(0xFF262A32),
              Color(0xFF14161A),
              Color(0xFF090A0D),
            ],
            stops: [0.0, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
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
                              letterSpacing: 0.2,
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

              // Camera Angle Preset Chips with Active Highlight
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildAngleChip('3D View', -0.18, 0.52),
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

              // 3D Canvas Area with Interactive Pan & Scale Gestures
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    _stopMotion();
                    _baseScale = _scale;
                    final now = DateTime.now();
                    if (_lastTapTime != null &&
                        now.difference(_lastTapTime!) <
                            const Duration(milliseconds: 300)) {
                      _lastTapTime = null;
                      HapticFeedback.mediumImpact();
                      _animateTo(-0.18, 0.52, targetScale: 1.0);
                    } else {
                      _lastTapTime = now;
                    }
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      if (details.pointerCount >= 2) {
                        _scale = (_baseScale * details.scale).clamp(0.75, 2.3);
                      }
                      _rotationY += details.focalPointDelta.dx * 0.013;
                      _rotationX =
                          (_rotationX - details.focalPointDelta.dy * 0.013)
                              .clamp(-0.85, 0.85);
                      _checkHapticDetents();
                    });
                  },
                  onScaleEnd: (details) {
                    final vx = details.velocity.pixelsPerSecond.dx;
                    final vy = details.velocity.pixelsPerSecond.dy;
                    if (vx.abs() > 220 || vy.abs() > 220) {
                      _startInertia(vx, vy);
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ground contact shadow scaled with perspective
                      Transform.translate(
                        offset: Offset(0, bookHeight * 0.58 * _scale),
                        child: Container(
                          width: bookWidth * 0.95 * _scale,
                          height: 22.0 * _scale,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.55),
                                blurRadius: 28.0 * _scale,
                                spreadRadius: 4.0 * _scale,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: _scale,
                        child: _build3DBookObject(
                          width: bookWidth,
                          height: bookHeight,
                          thickness: bookThickness,
                        ),
                      ),
                      // Floating Showcase Controls (Auto-Orbit & Reset)
                      Positioned(
                        top: 10,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFloatingGlassPill(
                              icon: _isAutoOrbiting
                                  ? Icons.pause
                                  : Icons.rotate_right,
                              label: _isAutoOrbiting ? 'Pause' : 'Auto Orbit',
                              isActive: _isAutoOrbiting,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  _isAutoOrbiting = !_isAutoOrbiting;
                                  if (_isAutoOrbiting) {
                                    _turntableController.repeat();
                                  } else {
                                    _turntableController.stop();
                                  }
                                });
                              },
                            ),
                            if (_scale != 1.0 ||
                                (_rotationX - (-0.18)).abs() > 0.05 ||
                                (_rotationY - 0.52).abs() > 0.05) ...[
                              const SizedBox(height: 8),
                              _buildFloatingGlassPill(
                                icon: Icons.restart_alt,
                                label: 'Reset',
                                isActive: false,
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _animateTo(-0.18, 0.52, targetScale: 1.0);
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Interaction Hint
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Drag to rotate 360° • Pinch to zoom • Double-tap to reset',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              // Bottom Actions Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF16191E).withOpacity(0.92),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24.0)),
                  border: Border(
                    top: BorderSide(
                        color: Colors.white.withOpacity(0.1), width: 1.0),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 20.0,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (hasPdf)
                      Builder(
                        builder: (ctx) {
                          final isEpub = widget.book.pdfPath != null &&
                              (widget.book.pdfPath!
                                      .toLowerCase()
                                      .endsWith('.epub') ||
                                  widget.book.pdfPath!
                                      .toLowerCase()
                                      .endsWith('.epub3'));
                          return Expanded(
                            flex: 3,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                              ),
                              icon: const Icon(Icons.auto_stories),
                              label: Text(
                                isEpub
                                    ? (widget.book.lastReadPage > 1
                                        ? 'Read (Ch ${widget.book.lastReadPage})'
                                        : 'Read (EPUB)')
                                    : (widget.book.lastReadPage > 1
                                        ? 'Read (Pg ${widget.book.lastReadPage})'
                                        : 'Read Book (PDF)'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => isEpub
                                        ? EpubReaderScreen(book: widget.book)
                                        : PdfReaderScreen(book: widget.book),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      )
                    else
                      Expanded(
                        flex: 3,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
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
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.0),
                          ),
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
      ),
    );
  }

  Widget _buildAngleChip(String label, double x, double y) {
    final isActive = _getActivePresetLabel() == label;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _animateTo(x, y);
        },
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
          decoration: BoxDecoration(
            color: isActive ? primary : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isActive
                  ? primary.withOpacity(0.8)
                  : Colors.white.withOpacity(0.22),
              width: isActive ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingGlassPill({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7.0),
              decoration: BoxDecoration(
                color: isActive
                    ? primary.withOpacity(0.85)
                    : Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color:
                      isActive ? Colors.white38 : Colors.white.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _applyLighting(Widget child, double brightness) {
    return Stack(
      fit: StackFit.passthrough,
      children: [
        child,
        if (brightness < 0.96)
          Positioned.fill(
            child: Container(
              color: Colors.black
                  .withOpacity(((1.0 - brightness) * 0.65).clamp(0.0, 0.7)),
            ),
          )
        else if (brightness > 0.88)
          Positioned.fill(
            child: Container(
              color: Colors.white
                  .withOpacity(((brightness - 0.88) * 0.25).clamp(0.0, 0.2)),
            ),
          ),
      ],
    );
  }

  /// Constructs the 3D book cuboid with front, back, spine, and striated paper block edges.
  /// Uses depth-sorted painter's algorithm, outward face normals, backface culling,
  /// dynamic directional lighting, hardcover board overhangs, and reading silk ribbon.
  Widget _build3DBookObject({
    required double width,
    required double height,
    required double thickness,
  }) {
    final hx = width / 2;
    final hy = height / 2;
    final hz = thickness / 2;

    final isHardcover = widget.book.format.toLowerCase() == 'hardcover';
    final overhang = isHardcover ? 2.5 : 0.0;
    final coverWidth = width + overhang;
    final coverHeight = height + overhang * 2;

    final spineColor = Color(widget.book.spineColorHex);
    final spineTextColor = Color(widget.book.spineTextHex);

    final rx = _rotationX;
    final ry = _rotationY;

    final cosX = math.cos(rx);
    final sinX = math.sin(rx);
    final cosY = math.cos(ry);
    final sinY = math.sin(ry);

    // Directional light vector (top-right-front) in view space for natural studio key light
    const lx = 0.351;
    const ly = -0.652;
    const lz = 0.672;

    // 1. Front Face (+Z)
    final frontCz = hz * cosY * cosX;
    final frontNx = sinY;
    final frontNy = -cosY * sinX;
    final frontNz = cosY * cosX;
    final isFrontVis = frontNz > -0.05;
    final frontLight =
        (frontNx * lx + frontNy * ly + frontNz * lz).clamp(0.0, 1.0);
    final frontBrightness = (0.55 + 0.45 * frontLight).clamp(0.4, 1.0);

    // 2. Back Face (-Z)
    final backCz = -frontCz;
    final backNx = -frontNx;
    final backNy = -frontNy;
    final backNz = -frontNz;
    final isBackVis = backNz > -0.05;
    final backLight = (backNx * lx + backNy * ly + backNz * lz).clamp(0.0, 1.0);
    final backBrightness = (0.55 + 0.45 * backLight).clamp(0.4, 1.0);

    // 3. Spine Face (-X)
    final spineCz = hx * sinY * cosX;
    final spineNx = -cosY;
    final spineNy = -sinY * sinX;
    final spineNz = sinY * cosX;
    final isSpineVis = spineNz > -0.05;
    final spineLight =
        (spineNx * lx + spineNy * ly + spineNz * lz).clamp(0.0, 1.0);
    final spineBrightness = (0.55 + 0.45 * spineLight).clamp(0.4, 1.0);

    // 4. Fore-Edge Face (+X)
    final foreCz = -spineCz;
    final foreNx = -spineNx;
    final foreNy = -spineNy;
    final foreNz = -spineNz;
    final isForeVis = foreNz > -0.05;
    final foreLight = (foreNx * lx + foreNy * ly + foreNz * lz).clamp(0.0, 1.0);
    final foreBrightness = (0.55 + 0.45 * foreLight).clamp(0.4, 1.0);

    // 5. Top Edge Face (-Y)
    final topCz = -hy * sinX;
    final topNy = -cosX;
    final topNz = -sinX;
    final isTopVis = topNz > -0.02 || rx < 0.05;
    final topLight = (topNy * ly + topNz * lz).clamp(0.0, 1.0);
    final topBrightness = (0.55 + 0.45 * topLight).clamp(0.4, 1.0);

    // 6. Bottom Edge Face (+Y)
    final bottomCz = -topCz;
    final bottomNy = -topNy;
    final bottomNz = -topNz;
    final isBottomVis = bottomNz > -0.02 || rx > -0.05;
    final bottomLight = (bottomNy * ly + bottomNz * lz).clamp(0.0, 1.0);
    final bottomBrightness = (0.55 + 0.45 * bottomLight).clamp(0.4, 1.0);

    final faces = <_FaceRenderData>[];

    if (isFrontVis) {
      faces.add(
        _FaceRenderData(
          depth: frontCz,
          widget: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..translate(overhang / 2, 0.0, hz),
            child: SizedBox(
              width: coverWidth,
              height: coverHeight,
              child: _applyLighting(
                _buildFrontCover(coverWidth, coverHeight, spineColor),
                frontBrightness,
              ),
            ),
          ),
        ),
      );
    }

    if (isBackVis) {
      faces.add(
        _FaceRenderData(
          depth: backCz,
          widget: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(overhang / 2, 0.0, -hz)
              ..rotateY(math.pi),
            child: SizedBox(
              width: coverWidth,
              height: coverHeight,
              child: _applyLighting(
                _buildBackCover(coverWidth, coverHeight, spineColor),
                backBrightness,
              ),
            ),
          ),
        ),
      );
    }

    if (isSpineVis) {
      faces.add(
        _FaceRenderData(
          depth: spineCz,
          widget: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(-hx, 0.0, 0.0)
              ..rotateY(-math.pi / 2),
            child: SizedBox(
              width: thickness,
              height: coverHeight,
              child: _applyLighting(
                _buildSpineFace(
                    thickness, coverHeight, spineColor, spineTextColor),
                spineBrightness,
              ),
            ),
          ),
        ),
      );
    }

    if (isForeVis) {
      faces.add(
        _FaceRenderData(
          depth: foreCz,
          widget: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(hx, 0.0, 0.0)
              ..rotateY(math.pi / 2),
            child: SizedBox(
              width: thickness,
              height: height,
              child: _applyLighting(
                _buildForeEdge(thickness, height),
                foreBrightness,
              ),
            ),
          ),
        ),
      );
    }

    if (isTopVis) {
      faces.add(
        _FaceRenderData(
          depth: topCz,
          widget: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, -hy, 0.0)
              ..rotateX(math.pi / 2),
            child: SizedBox(
              width: width,
              height: thickness,
              child: _applyLighting(
                _buildPaperEdge(width, thickness),
                topBrightness,
              ),
            ),
          ),
        ),
      );
    }

    if (isBottomVis) {
      faces.add(
        _FaceRenderData(
          depth: bottomCz,
          widget: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..translate(0.0, hy, 0.0)
              ..rotateX(-math.pi / 2),
            child: SizedBox(
              width: width,
              height: thickness,
              child: _applyLighting(
                _buildPaperEdge(width, thickness),
                bottomBrightness,
              ),
            ),
          ),
        ),
      );
    }

    // Silk Ribbon Bookmark hanging from bottom page block
    final hasProgress =
        widget.book.lastReadPage > 1 && widget.book.pageCount > 0;
    if (hasProgress) {
      final ratio =
          (widget.book.lastReadPage / widget.book.pageCount).clamp(0.06, 0.94);
      final ribbonZ = hz - (ratio * thickness);
      final ribbonCz = hy * (-sinX) + ribbonZ * cosY * cosX;
      faces.add(
        _FaceRenderData(
          depth: ribbonCz + 2.0,
          widget: _applyLighting(
            _buildSilkRibbon(ribbonZ, hy),
            bottomBrightness.clamp(0.65, 1.0),
          ),
        ),
      );
    }

    // Depth sorting: lowest Z (furthest from camera) paints first!
    faces.sort((a, b) => a.depth.compareTo(b.depth));

    return SizedBox(
      width: coverWidth,
      height: coverHeight,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2,
              -0.0013) // Perspective (negative for true camera-space depth)
          ..rotateX(_rotationX)
          ..rotateY(_rotationY),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: faces.map((f) => f.widget).toList(),
        ),
      ),
    );
  }

  Widget _buildSilkRibbon(double ribbonZ, double hy) {
    return Transform(
      alignment: Alignment.topCenter,
      transform: Matrix4.identity()
        ..translate(0.0, hy, ribbonZ)
        ..rotateX(0.12),
      child: ClipPath(
        clipper: _RibbonClipper(),
        child: Container(
          width: 7.5,
          height: 38.0,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF7F0000), // Dark ruby edge
                Color(0xFFE53935), // Satin highlight
                Color(0xFFB71C1C), // Deep crimson
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 4.0,
                offset: Offset(1.0, 3.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCover(double w, double h, Color baseColor) {
    return Container(
      width: w,
      height: h,
      color: baseColor,
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
    );
  }

  Widget _buildProceduralCoverArt(Color baseColor) {
    final textColor = Color(widget.book.spineTextHex);
    final authorsList = Formatters.parseAuthors(widget.book.authors);
    final authorStr =
        authorsList.isNotEmpty ? authorsList.first.toUpperCase() : 'AUTHOR';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Realistic embossed leather book texture
        Image.asset(
          'assets/images/placeholders/default_book_cover.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: baseColor),
        ),
        // Tint overlay colored with the book's extracted spine/cover color
        Container(
          color: baseColor.withOpacity(0.6),
        ),
        // Content container with ornamental frame
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: textColor.withOpacity(0.38),
                width: 1.2,
              ),
              borderRadius: BorderRadius.circular(3.0),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Author
                Text(
                  authorStr,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withOpacity(0.85),
                    fontSize: 10.5,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Center emblem + Title
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories,
                        size: 28,
                        color: textColor.withOpacity(0.55),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Text(
                          widget.book.title,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.55),
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Text(
                  'S H E L F C R A F T',
                  style: TextStyle(
                    color: textColor.withOpacity(0.55),
                    fontSize: 8,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpineFace(
      double thickness, double h, Color baseColor, Color textColor) {
    return SizedBox(
      width: thickness,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Embossed leather texture matching front & back cover
          Image.asset(
            'assets/images/placeholders/default_book_cover.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: baseColor),
          ),
          Container(
            color: baseColor.withOpacity(0.65),
          ),
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
                    color: textColor.withOpacity(0.65),
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
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.55),
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 2.0,
                    width: thickness * 0.7,
                    color: textColor.withOpacity(0.65),
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
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_resolvedBackCoverAbsPath != null &&
              File(_resolvedBackCoverAbsPath!).existsSync())
            Image.file(File(_resolvedBackCoverAbsPath!), fit: BoxFit.cover)
          else if (widget.book.backCoverPath != null &&
              widget.book.backCoverPath!.startsWith('http'))
            CachedNetworkImage(
              imageUrl: widget.book.backCoverPath!,
              fit: BoxFit.cover,
            )
          else
            _buildProceduralBackCover(baseColor),

          // Spine hinge groove shadow on the right edge of back cover
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 14.0,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProceduralBackCover(Color baseColor) {
    final textColor = Color(widget.book.spineTextHex);
    final authorsList = Formatters.parseAuthors(widget.book.authors);
    final isReading = widget.book.status == 'reading';
    final hasRating = widget.book.rating != null && widget.book.rating! > 0;
    final hasSeries =
        widget.book.seriesName != null && widget.book.seriesName!.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Embossed leather texture matching front cover
        Image.asset(
          'assets/images/placeholders/default_book_cover.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: baseColor),
        ),
        Container(
          color: baseColor.withOpacity(0.65),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row on Back
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

              // Center Synopsis / Series / Rating
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSeries) ...[
                      Text(
                        '${widget.book.seriesName!} #${widget.book.seriesIndex != null ? (widget.book.seriesIndex! % 1 == 0 ? widget.book.seriesIndex!.toInt() : widget.book.seriesIndex) : 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withOpacity(0.75),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      widget.book.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (authorsList.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        authorsList.join(', '),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (isReading) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Page ${widget.book.lastReadPage} of ${widget.book.pageCount}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor.withOpacity(0.65),
                          fontSize: 10,
                        ),
                      ),
                    ],
                    if (hasRating) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(5, (i) {
                            final starVal = i + 1;
                            final r = widget.book.rating!;
                            IconData iconData = Icons.star_border;
                            if (r >= starVal) {
                              iconData = Icons.star;
                            } else if (r >= starVal - 0.5) {
                              iconData = Icons.star_half;
                            }
                            return Icon(iconData,
                                size: 14, color: const Color(0xFFFFB300));
                          }),
                          const SizedBox(width: 4),
                          Text(
                            widget.book.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: textColor.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Barcode Simulation with Real ISBN
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          20,
                          (i) => Container(
                            width:
                                (i % 4 == 0) ? 2.5 : (i % 2 == 0 ? 1.5 : 1.0),
                            height: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 0.6),
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.book.isbn13 != null &&
                                widget.book.isbn13!.isNotEmpty
                            ? 'ISBN ${widget.book.isbn13}'
                            : 'SHELF CRAFT',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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

/// Realistic silk ribbon bookmark with swallowtail notch
class _RibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width / 2, size.height - 8);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Internal holder for face sorting based on view-space depth
class _FaceRenderData {
  final Widget widget;
  final double depth;

  const _FaceRenderData({
    required this.widget,
    required this.depth,
  });
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
