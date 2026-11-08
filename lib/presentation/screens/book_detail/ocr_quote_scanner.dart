import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';

/// Screen using Google ML Kit Text Recognition to scan book pages,
/// extract notable quotes, and save them to `BookNotes`.
class OcrQuoteScanner extends ConsumerStatefulWidget {
  final String bookId;
  final String bookTitle;

  const OcrQuoteScanner({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  ConsumerState<OcrQuoteScanner> createState() => _OcrQuoteScannerState();
}

class _OcrQuoteScannerState extends ConsumerState<OcrQuoteScanner> {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();
  static const _uuid = Uuid();

  bool _isRecognizing = false;
  String _recognizedText = '';
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _pageController = TextEditingController();
  String _noteType = 'quote'; // 'quote', 'thought', 'character'

  @override
  void dispose() {
    _textRecognizer.close();
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _captureAndRecognize(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 90,
      );

      if (file == null) return;

      setState(() => _isRecognizing = true);

      final inputImage = InputImage.fromFilePath(file.path);
      final RecognizedText recognized =
          await _textRecognizer.processImage(inputImage);

      setState(() {
        _isRecognizing = false;
        _recognizedText = recognized.text;
        _contentController.text = recognized.text;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isRecognizing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to recognize text: $e')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote content cannot be empty.')),
      );
      return;
    }

    final pageNumber = int.tryParse(_pageController.text.trim());
    final db = ref.read(appDatabaseProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.sessionDao.insertNote(
      BookNotesCompanion.insert(
        id: _uuid.v4(),
        bookId: widget.bookId,
        noteType: _noteType,
        content: content,
        pageNumber: drift.Value(pageNumber),
        createdAt: now,
      ),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote saved to notes! ✍️')),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Quote (OCR)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Note',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: _isRecognizing
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Recognizing text on page...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Book Title Header
                  if (widget.bookTitle.isNotEmpty) ...[
                    Text(
                      widget.bookTitle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Capture Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          onPressed: () =>
                              _captureAndRecognize(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Pick Image'),
                          onPressed: () =>
                              _captureAndRecognize(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Note Type Selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'quote', label: Text('Quote')),
                      ButtonSegment(value: 'thought', label: Text('Thought')),
                      ButtonSegment(
                          value: 'character', label: Text('Character')),
                    ],
                    selected: {_noteType},
                    onSelectionChanged: (set) =>
                        setState(() => _noteType = set.first),
                  ),
                  const SizedBox(height: 16),

                  // Page Number Input
                  TextField(
                    controller: _pageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Page Number (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.bookmark_border),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_recognizedText.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          'Text extracted via OCR • Edit if needed',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Editable Quote Content Field
                  TextField(
                    controller: _contentController,
                    maxLines: 6,
                    decoration: InputDecoration(
                      labelText: 'Quote or Note Content',
                      hintText:
                          'Type quote manually or tap Scan Page to extract from camera...',
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                      suffixIcon: _contentController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _contentController.clear();
                                  _recognizedText = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save to Book Notes'),
                    onPressed: _saveNote,
                  ),
                ],
              ),
            ),
    );
  }
}
