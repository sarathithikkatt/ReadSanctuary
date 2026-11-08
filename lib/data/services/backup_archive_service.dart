import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// Metadata manifest stored inside every ShelfCraft backup archive (.zip).
class BackupManifest {
  final String appName;
  final int schemaVersion;
  final int timestamp;
  final int bookCount;
  final int mediaFilesCount;

  const BackupManifest({
    this.appName = 'ShelfCraft',
    required this.schemaVersion,
    required this.timestamp,
    required this.bookCount,
    required this.mediaFilesCount,
  });

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'schemaVersion': schemaVersion,
        'timestamp': timestamp,
        'bookCount': bookCount,
        'mediaFilesCount': mediaFilesCount,
      };

  factory BackupManifest.fromJson(Map<String, dynamic> json) => BackupManifest(
        appName: json['appName']?.toString() ?? 'ShelfCraft',
        schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
        timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
        bookCount: (json['bookCount'] as num?)?.toInt() ?? 0,
        mediaFilesCount: (json['mediaFilesCount'] as num?)?.toInt() ?? 0,
      );
}

/// Service that packages the local SQLite database, media folder, and manifest into a ZIP,
/// and restores them with strict manifest validation.
class BackupArchiveService {
  static const int currentSchemaVersion = 1;
  static const String manifestFileName = 'backup_manifest.json';
  static const String dbFileName = 'app_database.sqlite';

  /// Bundles [dbFile], [mediaDir], and a generated manifest into [outputZipFile].
  Future<File> createBackupArchive({
    required File dbFile,
    required Directory mediaDir,
    required File outputZipFile,
    int bookCount = 0,
  }) async {
    final archive = Archive();

    // 1. Add SQLite database file
    if (await dbFile.exists()) {
      final dbBytes = await dbFile.readAsBytes();
      archive.addFile(ArchiveFile(dbFileName, dbBytes.length, dbBytes));
    } else {
      throw StateError('Database file does not exist at ${dbFile.path}');
    }

    // 2. Add media files (covers and spines)
    int mediaCount = 0;
    if (await mediaDir.exists()) {
      final mediaEntities = mediaDir.listSync(recursive: true);
      for (final entity in mediaEntities) {
        if (entity is File) {
          final relativePath =
              p.relative(entity.path, from: mediaDir.parent.path);
          // Normalize slashes for ZIP format portability
          final normalizedPath = relativePath.replaceAll(r'\', '/');
          final bytes = await entity.readAsBytes();
          archive.addFile(ArchiveFile(normalizedPath, bytes.length, bytes));
          mediaCount++;
        }
      }
    }

    // 3. Create and add manifest
    final manifest = BackupManifest(
      schemaVersion: currentSchemaVersion,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      bookCount: bookCount,
      mediaFilesCount: mediaCount,
    );
    final manifestBytes = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(
        ArchiveFile(manifestFileName, manifestBytes.length, manifestBytes));

    // 4. Encode to ZIP and write to output file
    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);

    await outputZipFile.parent.create(recursive: true);
    await outputZipFile.writeAsBytes(zipBytes);
    return outputZipFile;
  }

  /// Verifies the archive manifest before extracting.
  /// Throws [FormatException] if manifest is missing or invalid.
  BackupManifest inspectAndVerifyArchive(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final manifestFile = archive.findFile(manifestFileName);
    if (manifestFile == null) {
      throw const FormatException(
          'Corrupt backup: missing backup_manifest.json');
    }

    final manifestContent = utf8.decode(manifestFile.content as List<int>);
    final manifestJson = jsonDecode(manifestContent) as Map<String, dynamic>;
    final manifest = BackupManifest.fromJson(manifestJson);

    if (manifest.appName != 'ShelfCraft') {
      throw FormatException(
          'Incompatible backup from application: ${manifest.appName}');
    }

    if (manifest.schemaVersion > currentSchemaVersion) {
      throw FormatException(
        'Backup schema version ${manifest.schemaVersion} is newer than current app version $currentSchemaVersion. Please update the app.',
      );
    }

    return manifest;
  }

  /// Restores database and media files from [backupZipFile] into [targetDirectory].
  /// Validates manifest integrity before overwriting any local files.
  Future<BackupManifest> restoreBackupArchive({
    required File backupZipFile,
    required Directory targetDirectory,
  }) async {
    final zipBytes = await backupZipFile.readAsBytes();
    final manifest = inspectAndVerifyArchive(zipBytes);

    final archive = ZipDecoder().decodeBytes(zipBytes);

    for (final file in archive) {
      if (file.isFile) {
        // Skip manifest during filesystem extraction or keep it
        final outPath = p.join(targetDirectory.path, file.name);
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    return manifest;
  }
}
