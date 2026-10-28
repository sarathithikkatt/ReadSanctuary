import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/color_extractor.dart';
import '../../../data/local/database.dart';
import '../../../data/remote/book_lookup_service.dart';

/// Barcode scanner screen using mobile_scanner with an ISBN-13 cutout overlay,
/// supporting both Single Scan and Rapid Batch Scan modes.
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  final String? initialShelfId;

  const BarcodeScannerScreen({
    super.key,
    this.initialShelfId,
  });

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  bool _isBatchMode = false;
  bool _isTorchOn = false;
  String? _selectedShelfId;
  final Set<String> _scannedIsbns = {};
  int _batchCount = 0;
  bool _isProcessingSingle = false;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _selectedShelfId = widget.initialShelfId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final isbn = rawValue.replaceAll(RegExp(r'[^0-9Xx]'), '');
    if (isbn.length != 10 && isbn.length != 13) return;

    if (_isBatchMode) {
      if (_scannedIsbns.contains(isbn)) return; // Prevent duplicate rapid scan
      _scannedIsbns.add(isbn);
      HapticFeedback.mediumImpact();

      setState(() {
        _batchCount++;
      });

      // Queue background lookup and insertion
      unawaited(_processBackgroundBookInsert(isbn));
    } else {
      if (_isProcessingSingle) return;
      _isProcessingSingle = true;
      HapticFeedback.mediumImpact();

      await _controller.stop();
      if (!mounted) return;

      // Show loading and fetch metadata
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Looking up ISBN...'),
                ],
              ),
            ),
          ),
        ),
      );

      final lookupService = ref.read(bookLookupServiceProvider);
      final metadata = await lookupService.lookupByIsbn(isbn);

      if (!mounted) return;
      Navigator.of(context).pop(); // dismiss loading dialog

      if (metadata != null) {
        final inserted = await _showBookConfirmDialog(isbn, metadata.title, metadata.authors);
        if (inserted && mounted) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${metadata.title}" added to shelf! 📖')),
            );
            _isProcessingSingle = false;
            await _controller.start();
          }
        } else {
          _isProcessingSingle = false;
          await _controller.start();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No book found for ISBN: $isbn')),
        );
        _isProcessingSingle = false;
        await _controller.start();
      }
    }
  }

  Future<void> _processBackgroundBookInsert(String isbn) async {
    try {
      final lookupService = ref.read(bookLookupServiceProvider);
      final metadata = await lookupService.lookupByIsbn(isbn);
      final db = ref.read(appDatabaseProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final bookId = _uuid.v4();

      const spineColors = SpineColors.fallback;
      final title = metadata?.title ?? 'ISBN: $isbn';
      final authors = metadata?.authors ?? ['Unknown'];

      await db.bookDao.insertBook(
        BooksCompanion.insert(
          id: bookId,
          isbn13: drift.Value(isbn),
          title: title,
          authors: '["${authors.join('", "')}"]',
          pageCount: drift.Value(metadata?.pageCount ?? 250),
          format: drift.Value(metadata?.format ?? 'paperback'),
          status: 'tbr',
          spineColorHex: spineColors.spineColorHex,
          spineTextHex: spineColors.spineTextHex,
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Add to shelf (ensure target shelf exists)
      var targetShelfId = _selectedShelfId;
      if (targetShelfId == null) {
        final allShelves = await db.shelfDao.getAllShelves();
        if (allShelves.isNotEmpty) {
          targetShelfId = allShelves.first.id;
        } else {
          targetShelfId = _uuid.v4();
          await db.shelfDao.insertShelf(
            ShelvesCompanion.insert(
              id: targetShelfId,
              name: 'My Bookshelf',
              sortOrder: 0,
            ),
          );
        }
      }

      final existingItems = await db.shelfDao.getItemsForShelf(targetShelfId);
      await db.shelfDao.insertShelfItem(
        ShelfItemsCompanion.insert(
          id: _uuid.v4(),
          shelfId: targetShelfId,
          itemType: 'book',
          bookId: drift.Value(bookId),
          positionIndex: existingItems.length,
        ),
      );
    } catch (_) {}
  }

  Future<bool> _showBookConfirmDialog(String isbn, String title, List<String> authors) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Book Found'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(authors.join(', '), style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                Text('ISBN: $isbn', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _processBackgroundBookInsert(isbn);
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                child: const Text('Add to Shelf'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final shelfDao = ref.watch(shelfDaoProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_isBatchMode ? 'Rapid Batch Scanner' : 'Barcode Scanner'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcodeDetected,
          ),

          // Custom Cutout Overlay
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerOverlayPainter(),
          ),

          // Top Shelf Selection & Mode Controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Mode Toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Single')),
                    ButtonSegment(value: true, label: Text('Batch')),
                  ],
                  selected: {_isBatchMode},
                  onSelectionChanged: (set) {
                    setState(() {
                      _isBatchMode = set.first;
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Target Shelf Dropdown
                StreamBuilder<List<Shelf>>(
                  stream: shelfDao.watchAllShelves(),
                  builder: (context, snapshot) {
                    final shelves = snapshot.data ?? [];
                    if (shelves.isEmpty) return const SizedBox.shrink();
                    _selectedShelfId ??= shelves.first.id;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedShelfId,
                        dropdownColor: Colors.grey.shade900,
                        underline: const SizedBox.shrink(),
                        isExpanded: true,
                        style: const TextStyle(color: Colors.white),
                        items: shelves
                            .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedShelfId = val),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Bottom Batch Count Banner
          if (_isBatchMode)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8.0, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$_batchCount book${_batchCount == 1 ? '' : 's'} added',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade900,
                      ),
                      onPressed: () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added $_batchCount books to shelf! 📚')),
                          );
                          setState(() {
                            _batchCount = 0;
                            _scannedIsbns.clear();
                          });
                        }
                      },
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws a semi-transparent dark mask with a rounded rectangular cutout for ISBN barcodes.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutWidth = 280.0;
    const cutoutHeight = 160.0;
    final left = (size.width - cutoutWidth) / 2;
    final top = (size.height - cutoutHeight) / 2;
    final cutoutRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight),
      const Radius.circular(12.0),
    );

    final bgPaint = Paint()..color = Colors.black.withOpacity(0.55);
    final borderPaint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutoutRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, bgPaint);
    canvas.drawRRect(cutoutRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
