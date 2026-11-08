import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/core/utils/image_storage_helper.dart';

void main() {
  late Directory tempDir;
  late ImageStorageHelper storageHelper;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('shelfcraft_test_media_');
    storageHelper = ImageStorageHelper(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ImageStorageHelper Tests', () {
    test('Saves cover bytes and returns relative path', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final relativePath =
          await storageHelper.saveCoverBytes(bytes, filename: 'test_cover.jpg');

      expect(relativePath, 'covers/test_cover.jpg');
      expect(await storageHelper.fileExists(relativePath), isTrue);

      final absPath = await storageHelper.resolveAbsolutePath(relativePath);
      final file = File(absPath);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('Saves spine bytes and returns relative path', () async {
      final bytes = Uint8List.fromList([10, 20, 30]);
      final relativePath =
          await storageHelper.saveSpineBytes(bytes, filename: 'test_spine.jpg');

      expect(relativePath, 'spines/test_spine.jpg');
      expect(await storageHelper.fileExists(relativePath), isTrue);
    });

    test('Saves PDF bytes and returns relative path', () async {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
      final relativePath =
          await storageHelper.savePdfBytes(pdfBytes, filename: 'sample_book.pdf');

      expect(relativePath, 'pdfs/sample_book.pdf');
      expect(await storageHelper.fileExists(relativePath), isTrue);

      final absPath = await storageHelper.resolveAbsolutePath(relativePath);
      final file = File(absPath);
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), pdfBytes);
    });

    test('Deletes file by relative path', () async {
      final bytes = Uint8List.fromList([42]);
      final relativePath = await storageHelper.saveCoverBytes(bytes);
      expect(await storageHelper.fileExists(relativePath), isTrue);

      await storageHelper.deleteFile(relativePath);
      expect(await storageHelper.fileExists(relativePath), isFalse);
    });
  });
}
