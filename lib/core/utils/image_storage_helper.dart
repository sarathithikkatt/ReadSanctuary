import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Helper for storing and resolving images relative to `<AppDocuments>/media/`.
/// All paths stored in database are relative to the media folder (e.g., 'covers/abc.jpg' or 'spines/xyz.jpg').
class ImageStorageHelper {
  final Future<Directory> Function()? _baseDirProvider;
  final Dio _dio;
  final Uuid _uuid;

  ImageStorageHelper({
    Future<Directory> Function()? baseDirProvider,
    Dio? dio,
    Uuid? uuid,
  })  : _baseDirProvider = baseDirProvider,
        _dio = dio ?? Dio(),
        _uuid = uuid ?? const Uuid();

  /// The root `media/` directory.
  Future<Directory> getMediaDirectory() async {
    final Directory dir;
    if (_baseDirProvider != null) {
      dir = await _baseDirProvider();
    } else {
      final appDocs = await getApplicationDocumentsDirectory();
      dir = Directory(p.join(appDocs.path, 'media'));
    }

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Subdirectory for book covers: `<media>/covers/`.
  Future<Directory> getCoversDirectory() async {
    final mediaDir = await getMediaDirectory();
    final coversDir = Directory(p.join(mediaDir.path, 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    return coversDir;
  }

  /// Subdirectory for cropped/custom book spines: `<media>/spines/`.
  Future<Directory> getSpinesDirectory() async {
    final mediaDir = await getMediaDirectory();
    final spinesDir = Directory(p.join(mediaDir.path, 'spines'));
    if (!await spinesDir.exists()) {
      await spinesDir.create(recursive: true);
    }
    return spinesDir;
  }

  /// Converts a relative path (e.g., 'covers/123.jpg') into an absolute file system path.
  Future<String> resolveAbsolutePath(String relativePath) async {
    final mediaDir = await getMediaDirectory();
    return p.join(mediaDir.path, relativePath);
  }

  /// Returns a [File] object given a relative path.
  Future<File> getFile(String relativePath) async {
    final absPath = await resolveAbsolutePath(relativePath);
    return File(absPath);
  }

  /// Checks if a relative file exists.
  Future<bool> fileExists(String relativePath) async {
    final file = await getFile(relativePath);
    return file.exists();
  }

  /// Deletes a relative file if it exists.
  Future<void> deleteFile(String relativePath) async {
    final file = await getFile(relativePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Saves raw bytes as a cover image and returns the relative path (e.g. 'covers/{filename}').
  Future<String> saveCoverBytes(
    Uint8List bytes, {
    String? filename,
    String extension = 'jpg',
  }) async {
    final coversDir = await getCoversDirectory();
    final name = filename ?? '${_uuid.v4()}.$extension';
    final file = File(p.join(coversDir.path, name));
    await file.writeAsBytes(bytes);
    return p.join('covers', name).replaceAll(r'\', '/');
  }

  /// Saves raw bytes as a spine image and returns the relative path (e.g. 'spines/{filename}').
  Future<String> saveSpineBytes(
    Uint8List bytes, {
    String? filename,
    String extension = 'jpg',
  }) async {
    final spinesDir = await getSpinesDirectory();
    final name = filename ?? '${_uuid.v4()}.$extension';
    final file = File(p.join(spinesDir.path, name));
    await file.writeAsBytes(bytes);
    return p.join('spines', name).replaceAll(r'\', '/');
  }

  /// Copies an existing file into the covers directory and returns the relative path.
  Future<String> copyCoverFile(File sourceFile, {String? targetFilename}) async {
    final coversDir = await getCoversDirectory();
    final ext = p.extension(sourceFile.path).replaceAll('.', '');
    final name = targetFilename ?? '${_uuid.v4()}.${ext.isEmpty ? "jpg" : ext}';
    final targetFile = File(p.join(coversDir.path, name));
    await sourceFile.copy(targetFile.path);
    return p.join('covers', name).replaceAll(r'\', '/');
  }

  /// Copies an existing file into the spines directory and returns the relative path.
  Future<String> copySpineFile(File sourceFile, {String? targetFilename}) async {
    final spinesDir = await getSpinesDirectory();
    final ext = p.extension(sourceFile.path).replaceAll('.', '');
    final name = targetFilename ?? '${_uuid.v4()}.${ext.isEmpty ? "jpg" : ext}';
    final targetFile = File(p.join(spinesDir.path, name));
    await sourceFile.copy(targetFile.path);
    return p.join('spines', name).replaceAll(r'\', '/');
  }

  /// Downloads an image from [url] and stores it in covers directory.
  /// Returns the relative path (e.g. 'covers/{filename}').
  Future<String> downloadAndSaveCover(
    String url, {
    String? filename,
    String extension = 'jpg',
  }) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    if (response.data == null) {
      throw StateError('Failed to download image from $url: null body');
    }
    return saveCoverBytes(
      Uint8List.fromList(response.data!),
      filename: filename,
      extension: extension,
    );
  }
}

final imageStorageHelperProvider = Provider<ImageStorageHelper>((ref) {
  return ImageStorageHelper();
});
