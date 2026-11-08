import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import '../../../../core/constants/book_formats.dart';
import '../../../../core/constants/reading_statuses.dart';
import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/local/database.dart';

/// Modal dialog for editing book metadata: title, subtitle/borrower, page count, format, status, series, rating.
class EditBookDialog extends StatefulWidget {
  final Book book;
  final BookDao bookDao;

  const EditBookDialog({
    super.key,
    required this.book,
    required this.bookDao,
  });

  static Future<void> show(BuildContext context, Book book, BookDao bookDao) {
    return showDialog(
      context: context,
      builder: (context) => EditBookDialog(book: book, bookDao: bookDao),
    );
  }

  @override
  State<EditBookDialog> createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<EditBookDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _pageCtrl;
  late final TextEditingController _seriesNameCtrl;
  late final TextEditingController _seriesIdxCtrl;

  late double _rating;
  late double _ratingPlot;
  late double _ratingCharacters;
  late double _ratingWriting;
  late double _ratingPacing;
  bool _showSubRatings = false;

  late String _status;
  late String _format;
  String? _pdfPath;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.book.title);
    _subtitleCtrl = TextEditingController(text: widget.book.subtitle ?? '');
    _pageCtrl = TextEditingController(text: '${widget.book.pageCount}');
    _seriesNameCtrl = TextEditingController(text: widget.book.seriesName ?? '');
    _seriesIdxCtrl = TextEditingController(
      text: widget.book.seriesIndex != null ? '${widget.book.seriesIndex}' : '',
    );
    _rating = widget.book.rating ?? 0.0;
    _ratingPlot = widget.book.ratingPlot ?? 0.0;
    _ratingCharacters = widget.book.ratingCharacters ?? 0.0;
    _ratingWriting = widget.book.ratingWriting ?? 0.0;
    _ratingPacing = widget.book.ratingPacing ?? 0.0;
    _showSubRatings = (_ratingPlot > 0 ||
        _ratingCharacters > 0 ||
        _ratingWriting > 0 ||
        _ratingPacing > 0);
    _status = widget.book.status;
    _format = widget.book.format;
    _pdfPath = widget.book.pdfPath;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _pageCtrl.dispose();
    _seriesNameCtrl.dispose();
    _seriesIdxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pages = int.tryParse(_pageCtrl.text.trim()) ?? widget.book.pageCount;
    final seriesIdx = double.tryParse(_seriesIdxCtrl.text.trim());

    await widget.bookDao.updateBook(
      widget.book.copyWith(
        title: _titleCtrl.text.trim().isNotEmpty
            ? _titleCtrl.text.trim()
            : widget.book.title,
        subtitle: drift.Value(
          _subtitleCtrl.text.trim().isNotEmpty
              ? _subtitleCtrl.text.trim()
              : null,
        ),
        pageCount: pages,
        format: _format,
        status: _status,
        rating: drift.Value(_rating > 0 ? _rating : null),
        ratingPlot: drift.Value(_ratingPlot > 0 ? _ratingPlot : null),
        ratingCharacters:
            drift.Value(_ratingCharacters > 0 ? _ratingCharacters : null),
        ratingWriting: drift.Value(_ratingWriting > 0 ? _ratingWriting : null),
        ratingPacing: drift.Value(_ratingPacing > 0 ? _ratingPacing : null),
        seriesName: drift.Value(
          _seriesNameCtrl.text.trim().isNotEmpty
              ? _seriesNameCtrl.text.trim()
              : null,
        ),
        seriesIndex: drift.Value(seriesIdx),
        pdfPath: drift.Value(_pdfPath),
        updatedAt: now,
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  void _calculateAverageRating() {
    final values = [
      _ratingPlot,
      _ratingCharacters,
      _ratingWriting,
      _ratingPacing,
    ].where((v) => v > 0).toList();

    if (values.isNotEmpty) {
      final avg = values.reduce((a, b) => a + b) / values.length;
      // Round to nearest 0.25 increment
      final rounded = (avg * 4).round() / 4.0;
      setState(() {
        _rating = rounded.clamp(0.0, 5.0);
      });
    }
  }

  Widget _buildSubRatingSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 13)),
            Text(
              value > 0 ? '${value.toStringAsFixed(2)} ★' : '—',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: value > 0 ? Colors.amber.shade800 : Colors.grey,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 5.0,
          divisions: 20, // 0.25 steps
          label: value > 0 ? value.toStringAsFixed(2) : 'None',
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Book Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Page Count'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _seriesNameCtrl,
                    decoration: const InputDecoration(labelText: 'Series Name'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextField(
                    controller: _seriesIdxCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: 'Vol # (e.g. 1.5)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _format,
              decoration: const InputDecoration(labelText: 'Format'),
              items: BookFormat.values
                  .map((f) =>
                      DropdownMenuItem(value: f.id, child: Text(f.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _format = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Reading Status'),
              items: ReadingStatus.values
                  .map((s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            if (_status == ReadingStatus.lent.id) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _subtitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lent to (Borrower Name / Date)',
                  hintText: 'e.g. Alex (Oct 15)',
                  prefixIcon: Icon(Icons.handshake_outlined),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final isEpub = _pdfPath != null &&
                    (_pdfPath!.toLowerCase().endsWith('.epub') ||
                        _pdfPath!.toLowerCase().endsWith('.epub3'));
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(_pdfPath != null
                        ? (isEpub ? Icons.auto_stories : Icons.picture_as_pdf)
                        : Icons.upload_file),
                    label: Text(
                      _pdfPath != null
                          ? '${isEpub ? "eBook" : "PDF"}: ${_pdfPath!.split('/').last}'
                          : 'Attach / Upload Book (PDF / EPUB)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: () async {
                      final storage = ImageStorageHelper();
                      final path =
                          await storage.pickAndSavePdf(bookId: widget.book.id);
                      if (path != null && mounted) {
                        setState(() {
                          _pdfPath = path;
                          _format = BookFormat.ebook.id;
                        });
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overall Rating:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  _rating > 0 ? '${_rating.toStringAsFixed(2)} ★' : 'No rating',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ],
            ),
            Slider(
              value: _rating,
              min: 0.0,
              max: 5.0,
              divisions: 20, // 0.25 steps
              label: _rating > 0 ? _rating.toStringAsFixed(2) : '0.0',
              onChanged: (val) => setState(() => _rating = val),
            ),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _showSubRatings = !_showSubRatings),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.tune, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Sub-Ratings Breakdown',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      _showSubRatings
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_showSubRatings) ...[
              const SizedBox(height: 8),
              _buildSubRatingSlider('📖 Plot', _ratingPlot,
                  (val) => setState(() => _ratingPlot = val)),
              _buildSubRatingSlider('🎭 Characters', _ratingCharacters,
                  (val) => setState(() => _ratingCharacters = val)),
              _buildSubRatingSlider('✍️ Writing', _ratingWriting,
                  (val) => setState(() => _ratingWriting = val)),
              _buildSubRatingSlider('⚡ Pacing', _ratingPacing,
                  (val) => setState(() => _ratingPacing = val)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.auto_awesome, size: 15),
                  label: const Text('Auto-Average to Overall',
                      style: TextStyle(fontSize: 12)),
                  onPressed: _calculateAverageRating,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
