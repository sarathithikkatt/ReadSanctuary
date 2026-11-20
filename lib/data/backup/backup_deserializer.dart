import 'dart:convert';
import 'dart:io';
import '../../core/errors/failures.dart';
import 'models/backup_snapshot_dto.dart';

/// Deserializes and validates a Gzipped .rsbk backup file into a BackupSnapshotDto.
class BackupDeserializer {
  /// Deserializes from compressed Gzip bytes.
  Future<BackupSnapshotDto> deserializeBytes(List<int> gzippedBytes) async {
    if (gzippedBytes.isEmpty) {
      throw const BackupFailure('Backup payload is empty.');
    }

    // 1. Decompress Gzip
    List<int> uncompressedBytes;
    try {
      uncompressedBytes = gzip.decode(gzippedBytes);
    } catch (e) {
      throw BackupFailure('Corrupted or truncated .rsbk backup archive: $e', e);
    }

    // 2. Decode UTF-8 string
    String jsonString;
    try {
      jsonString = utf8.decode(uncompressedBytes);
    } catch (e) {
      throw BackupFailure('Failed to decode UTF-8 JSON from backup: $e', e);
    }

    // 3. Parse JSON
    Map<String, dynamic> jsonMap;
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        throw const BackupFailure('Root of backup JSON must be a key-value object.');
      }
      jsonMap = decoded;
    } catch (e) {
      if (e is Failure) rethrow;
      throw BackupFailure('Malformed JSON in backup payload: $e', e);
    }

    // 4. Validate schema version and data payload
    if (!jsonMap.containsKey('schema_version') || !jsonMap.containsKey('data')) {
      throw const BackupFailure(
          'Missing required backup metadata fields (schema_version or data).');
    }

    return BackupSnapshotDto.fromJson(jsonMap);
  }

  /// Deserializes directly from a .rsbk File.
  Future<BackupSnapshotDto> deserializeFile(File file) async {
    if (!await file.exists()) {
      throw BackupFailure('Backup file does not exist at ${file.path}');
    }
    final bytes = await file.readAsBytes();
    return deserializeBytes(bytes);
  }
}
