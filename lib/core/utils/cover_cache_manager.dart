import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'image_storage_helper.dart';

/// Offline-first disk cache manager for book covers and spines, inspired by Mihon's Coil image caching.
class CoverCacheManager {
  final ImageStorageHelper _storageHelper;
  static const int defaultMaxCacheSizeBytes = 200 * 1024 * 1024; // 200 MB

  CoverCacheManager({ImageStorageHelper? storageHelper})
      : _storageHelper = storageHelper ?? ImageStorageHelper();

  /// Downloads remote cover image and caches it locally, returning relative path.
  Future<String?> downloadAndCacheCover({
    required String bookId,
    required String remoteUrl,
  }) async {
    try {
      return await _storageHelper.downloadAndSaveCover(
        remoteUrl,
        filename: 'cover_$bookId.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculates total size in bytes of cached covers.
  Future<int> getCacheSizeBytes() async {
    final coversDir = await _storageHelper.getCoversDirectory();
    if (!await coversDir.exists()) return 0;

    int totalBytes = 0;
    try {
      final entities = coversDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          totalBytes += entity.lengthSync();
        }
      }
    } catch (_) {}
    return totalBytes;
  }

  /// Deletes all files in the covers directory to free disk space.
  Future<void> clearCoverCache() async {
    final coversDir = await _storageHelper.getCoversDirectory();
    if (await coversDir.exists()) {
      final entities = coversDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  /// Resolves relative cover path to absolute File.
  Future<File?> resolveCoverFile(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return null;
    return _storageHelper.getFile(relativePath);
  }
}

final coverCacheManagerProvider = Provider<CoverCacheManager>((ref) {
  return CoverCacheManager(
    storageHelper: ref.watch(imageStorageHelperProvider),
  );
});
