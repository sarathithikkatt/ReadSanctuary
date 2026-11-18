import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../data/services/custom_props_service.dart';

/// Interactive modal allowing users to create their own custom decorative shelf props
/// by uploading an image from their gallery or camera with custom sizing and shelf preview.
class AddCustomPropDialog extends ConsumerStatefulWidget {
  const AddCustomPropDialog({super.key});

  static Future<CustomPropItem?> show(BuildContext context) {
    return showDialog<CustomPropItem>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AddCustomPropDialog(),
    );
  }

  @override
  ConsumerState<AddCustomPropDialog> createState() =>
      _AddCustomPropDialogState();
}

class _AddCustomPropDialogState extends ConsumerState<AddCustomPropDialog> {
  final TextEditingController _nameCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  String _extension = 'png';
  double _selectedHeight = 80.0;
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 90,
      );

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final ext = picked.name.split('.').last.toLowerCase();
        setState(() {
          _imageBytes = bytes;
          _extension = (ext == 'jpg' || ext == 'jpeg') ? 'jpg' : 'png';
          _error = null;
          if (_nameCtrl.text.trim().isEmpty) {
            final baseName = picked.name.split('.').first;
            _nameCtrl.text = _cleanFileName(baseName);
          }
        });
      }
    } catch (e) {
      setState(() => _error = 'Could not load image: $e');
    }
  }

  String _cleanFileName(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[-_]'), ' ').trim();
    if (cleaned.isEmpty) return 'Custom Prop';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  Future<void> _saveProp() async {
    if (_imageBytes == null) {
      setState(() => _error = 'Please pick an image for your prop.');
      return;
    }

    final name = _nameCtrl.text.trim().isEmpty
        ? 'Custom Prop'
        : _nameCtrl.text.trim();

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final prop = await ref.read(customPropsProvider.notifier).addProp(
            name: name,
            imageBytes: _imageBytes!,
            extension: _extension,
            height: _selectedHeight,
          );

      if (mounted) {
        Navigator.of(context).pop(prop);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _error = 'Failed to save prop: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.add_photo_alternate,
                color: Colors.amber, size: 26),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add Custom Shelf Prop',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bring your shelves to life! Choose any figurine, plant, photo, or transparent PNG from your device.',
              style: TextStyle(fontSize: 12.5, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Shelf Preview Area
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Wooden Shelf Surface Preview
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Color(0xFF986F35),
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(11),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Display image or placeholder
                  if (_imageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Ambient contact shadow
                          Positioned(
                            bottom: 0,
                            child: Container(
                              width: _selectedHeight * 0.55,
                              height: 4.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 4.0,
                                    spreadRadius: 1.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Image.memory(
                            _imageBytes!,
                            height: _selectedHeight,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    )
                  else
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 6),
                          Text(
                            'No image selected yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Image Picker Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('From Gallery'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Prop Name Field
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Prop Name',
                hintText: 'e.g. My Figurine, Ceramic Mug',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Size Selector
            const Text(
              'Shelf Height Preset',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(
                  value: 55.0,
                  label: Text('Small\n(55dp)', textAlign: TextAlign.center),
                ),
                ButtonSegment(
                  value: 80.0,
                  label: Text('Medium\n(80dp)', textAlign: TextAlign.center),
                ),
                ButtonSegment(
                  value: 110.0,
                  label: Text('Large\n(110dp)', textAlign: TextAlign.center),
                ),
              ],
              selected: {_selectedHeight},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) {
                  setState(() => _selectedHeight = set.first);
                }
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSaving ? null : _saveProp,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Add to Shelf'),
        ),
      ],
    );
  }
}
