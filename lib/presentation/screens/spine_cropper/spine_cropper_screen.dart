import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/utils/image_storage_helper.dart';

/// Screen allowing the user to pick/take a book spine or sprayed-edge photo,
/// crop it to a narrow spine aspect ratio using [crop_your_image], and save it
/// into `<AppDocs>/media/spines/{bookId}.jpg`.
class SpineCropperScreen extends StatefulWidget {
  final String bookId;
  final ImageStorageHelper? storageHelper;
  final Uint8List? initialImageBytes;

  const SpineCropperScreen({
    super.key,
    required this.bookId,
    this.storageHelper,
    this.initialImageBytes,
  });

  @override
  State<SpineCropperScreen> createState() => _SpineCropperScreenState();
}

class _SpineCropperScreenState extends State<SpineCropperScreen> {
  final CropController _cropController = CropController();
  final ImagePicker _picker = ImagePicker();
  late final ImageStorageHelper _storageHelper;

  Uint8List? _imageData;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _storageHelper = widget.storageHelper ?? ImageStorageHelper();
    if (widget.initialImageBytes != null) {
      _imageData = widget.initialImageBytes;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file != null) {
        final bytes = await File(file.path).readAsBytes();
        setState(() {
          _imageData = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _onCropped(CropResult result) async {
    setState(() => _isProcessing = true);
    try {
      final Uint8List croppedBytes;
      if (result is CropSuccess) {
        croppedBytes = result.croppedImage;
      } else {
        throw StateError('Crop was not successful');
      }

      final filename = '${widget.bookId}.jpg';
      final relativePath = await _storageHelper.saveSpineBytes(
        croppedBytes,
        filename: filename,
      );

      if (mounted) {
        Navigator.of(context).pop(relativePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save cropped spine: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop Book Spine'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_imageData != null)
            IconButton(
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.check),
              onPressed: _isProcessing ? null : () => _cropController.crop(),
            ),
        ],
      ),
      body: _imageData == null
          ? _buildPickerPrompt()
          : Stack(
              children: [
                Crop(
                  image: _imageData!,
                  controller: _cropController,
                  onCropped: _onCropped,
                  aspectRatio: 1.0 / 4.8, // Tall narrow physical spine ratio
                  withCircleUi: false,
                  baseColor: Colors.black,
                  maskColor: Colors.black.withOpacity(0.7),
                  cornerDotBuilder: (size, edgeAlignment) => const SizedBox.shrink(),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: _imageData == null ? null : _buildBottomActions(),
    );
  }

  Widget _buildPickerPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.crop_original, size: 72, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            'Take or choose a photo of the book spine',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                onPressed: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              icon: const Icon(Icons.refresh, color: Colors.white70),
              label: const Text('Retake', style: TextStyle(color: Colors.white70)),
              onPressed: () => setState(() => _imageData = null),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.crop),
              label: const Text('Crop & Save'),
              onPressed: _isProcessing ? null : () => _cropController.crop(),
            ),
          ],
        ),
      ),
    );
  }
}
