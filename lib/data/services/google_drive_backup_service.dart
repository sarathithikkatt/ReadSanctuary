import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../backup/backup_deserializer.dart';
import '../backup/backup_serializer.dart';
import '../backup/restore_backup_service.dart';
import '../local/database.dart';
import 'backup_archive_service.dart';

/// Result status of a Google Drive backup or restore operation.
class BackupOperationResult {
  final bool success;
  final String message;
  final BackupManifest? manifest;
  final RestoreResult? restoreResult;

  const BackupOperationResult({
    required this.success,
    required this.message,
    this.manifest,
    this.restoreResult,
  });
}

/// Service managing automated Google Drive AppData sandbox backup & restore,
/// SQLite WAL checkpointing, and local anti-lock-in ZIP/RSBK export/import.
class GoogleDriveBackupService {
  static const String backupFileName = 'readsanctuary_backup.zip';
  static const int maxRollingSnapshots = 5;

  final GoogleSignIn _googleSignIn;
  final BackupArchiveService _archiveService;
  final BackupSerializer _serializer;
  final BackupDeserializer _deserializer;
  final RestoreBackupService _restoreService;

  GoogleDriveBackupService({
    GoogleSignIn? googleSignIn,
    BackupArchiveService? archiveService,
    BackupSerializer? serializer,
    BackupDeserializer? deserializer,
    RestoreBackupService? restoreService,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveAppdataScope],
            ),
        _archiveService = archiveService ?? BackupArchiveService(),
        _serializer = serializer ?? BackupSerializer(),
        _deserializer = deserializer ?? BackupDeserializer(),
        _restoreService = restoreService ?? RestoreBackupService();

  /// Prompts user to sign in to Google.
  Future<GoogleSignInAccount?> signIn() async {
    return _googleSignIn.signIn();
  }

  /// Signs the user out of Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Whether a user is currently signed in.
  Future<bool> isSignedIn() async {
    return _googleSignIn.isSignedIn();
  }

  /// Exports local database state to a portable Gzipped .rsbk file.
  Future<File> exportLocalRsbk({
    required AppDatabase db,
    required File targetFile,
  }) async {
    await db.checkpointWal();
    return _serializer.exportToFile(db, targetFile);
  }

  /// Imports and smart-merges a local .rsbk file idempotently into the database.
  Future<RestoreResult> importLocalRsbk({
    required AppDatabase db,
    required File sourceFile,
    RestoreMode mode = RestoreMode.smartMerge,
  }) async {
    final snapshot = await _deserializer.deserializeFile(sourceFile);
    return _restoreService.restoreSnapshot(db, snapshot, mode: mode);
  }

  /// Creates and uploads a versioned .rsbk snapshot to Google Drive appDataFolder,
  /// and automatically trims backups to the latest 5 snapshots.
  Future<BackupOperationResult> createAndUploadRsbkBackup({
    required AppDatabase db,
  }) async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Google Sign-In required for cloud sync.',
        );
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Failed to acquire authenticated Drive client.',
        );
      }

      final driveApi = drive.DriveApi(authClient);
      await db.checkpointWal();

      // Serialize to Gzipped bytes
      final bytes = await _serializer.serializeDatabase(db);
      final filename =
          'readsanctuary_snapshot_${DateTime.now().millisecondsSinceEpoch}.rsbk';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, filename));
      await tempFile.writeAsBytes(bytes);

      final uploadMedia = drive.Media(
        tempFile.openRead(),
        bytes.length,
      );

      final driveFile = drive.File(
        name: filename,
        parents: ['appDataFolder'],
      );

      await driveApi.files.create(
        driveFile,
        uploadMedia: uploadMedia,
      );

      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      // Enforce rolling retention limit (keep newest 5, delete older)
      await _trimRollingSnapshots(driveApi);

      return const BackupOperationResult(
        success: true,
        message: 'Versioned .rsbk snapshot uploaded to Google Drive.',
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Backup failed: $e',
      );
    }
  }

  /// Downloads and smart-merges the most recent .rsbk snapshot from Google Drive.
  Future<BackupOperationResult> downloadAndRestoreLatestRsbk({
    required AppDatabase db,
    RestoreMode mode = RestoreMode.smartMerge,
  }) async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Google Sign-In required to restore backup.',
        );
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Failed to acquire authenticated Drive client.',
        );
      }

      final driveApi = drive.DriveApi(authClient);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'readsanctuary_snapshot_' and trashed = false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return const BackupOperationResult(
          success: false,
          message: 'No .rsbk snapshots found in Google Drive AppData.',
        );
      }

      final latestFile = fileList.files!.first;
      final fileId = latestFile.id!;

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final byteChunks = <int>[];
      await for (final chunk in media.stream) {
        byteChunks.addAll(chunk);
      }

      final snapshot = await _deserializer.deserializeBytes(byteChunks);
      final result =
          await _restoreService.restoreSnapshot(db, snapshot, mode: mode);

      return BackupOperationResult(
        success: true,
        message:
            'Snapshot restored: ${result.booksMerged} books merged idempotently.',
        restoreResult: result,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Restore failed: $e',
      );
    }
  }

  /// Trims cloud backups in appDataFolder to keep only the newest [maxRollingSnapshots].
  Future<void> _trimRollingSnapshots(drive.DriveApi driveApi) async {
    try {
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'readsanctuary_snapshot_' and trashed = false",
        orderBy: 'createdTime desc',
        $fields: 'files(id, name, createdTime)',
      );

      final files = fileList.files ?? [];
      if (files.length > maxRollingSnapshots) {
        for (int i = maxRollingSnapshots; i < files.length; i++) {
          final oldId = files[i].id;
          if (oldId != null) {
            await driveApi.files.delete(oldId);
          }
        }
      }
    } catch (_) {}
  }

  /// Creates and uploads a full backup archive to Google Drive appDataFolder.
  /// Flushes SQLite WAL first so that app_database.sqlite is 100% current.
  Future<BackupOperationResult> createAndUploadBackup({
    required AppDatabase db,
  }) async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Google Sign-In required for cloud sync.',
        );
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Failed to acquire authenticated Drive client.',
        );
      }

      final driveApi = drive.DriveApi(authClient);

      // 2. Flush SQLite WAL so all data is in app_database.sqlite
      await db.checkpointWal();

      // 3. Locate database and media folder
      final appDocs = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDocs.path, 'app_database.sqlite'));
      final mediaDir = Directory(p.join(appDocs.path, 'media'));

      final allBooks = await db.bookDao.getAllBooks();

      // 4. Create ZIP archive in temporary directory
      final tempDir = await getTemporaryDirectory();
      final zipFile = File(p.join(tempDir.path, backupFileName));

      await _archiveService.createBackupArchive(
        dbFile: dbFile,
        mediaDir: mediaDir,
        outputZipFile: zipFile,
        bookCount: allBooks.length,
      );

      // 5. Query existing backup file in Google Drive AppData folder
      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName' and trashed = false",
        $fields: 'files(id, name)',
      );

      final uploadMedia = drive.Media(
        zipFile.openRead(),
        await zipFile.length(),
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        final existingId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          existingId,
          uploadMedia: uploadMedia,
        );
      } else {
        final driveFile = drive.File(
          name: backupFileName,
          parents: ['appDataFolder'],
        );
        await driveApi.files.create(
          driveFile,
          uploadMedia: uploadMedia,
        );
      }

      if (await zipFile.exists()) {
        await zipFile.delete();
      }

      return const BackupOperationResult(
        success: true,
        message: 'Cloud backup uploaded successfully to Google Drive.',
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Backup failed: $e',
      );
    }
  }

  /// Downloads and restores the latest backup from Google Drive appDataFolder.
  Future<BackupOperationResult> downloadAndRestoreBackup({
    required WidgetRef ref,
  }) async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();

      if (account == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Google Sign-In required to restore backup.',
        );
      }

      final authClient = await _googleSignIn.authenticatedClient();
      if (authClient == null) {
        return const BackupOperationResult(
          success: false,
          message: 'Failed to acquire authenticated Drive client.',
        );
      }

      final driveApi = drive.DriveApi(authClient);

      final fileList = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$backupFileName' and trashed = false",
        $fields: 'files(id, name)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        return const BackupOperationResult(
          success: false,
          message: 'No backup found in Google Drive AppData folder.',
        );
      }

      final fileId = fileList.files!.first.id!;

      final tempDir = await getTemporaryDirectory();
      final tempZip = File(p.join(tempDir.path, 'downloaded_$backupFileName'));

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final sink = tempZip.openWrite();
      await media.stream.pipe(sink);

      ref.invalidate(appDatabaseProvider);

      final appDocs = await getApplicationDocumentsDirectory();
      final manifest = await _archiveService.restoreBackupArchive(
        backupZipFile: tempZip,
        targetDirectory: appDocs,
      );

      if (await tempZip.exists()) {
        await tempZip.delete();
      }

      ref.invalidate(appDatabaseProvider);

      return BackupOperationResult(
        success: true,
        message: 'Library restored successfully (${manifest.bookCount} books).',
        manifest: manifest,
      );
    } catch (e) {
      return BackupOperationResult(
        success: false,
        message: 'Restore failed: $e',
      );
    }
  }

  /// 100% Free Local Backup Export (Anti-Lock-In Promise)
  Future<File> exportLocalBackup({
    required AppDatabase db,
    required File targetFile,
  }) async {
    await db.checkpointWal();
    final appDocs = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(appDocs.path, 'app_database.sqlite'));
    final mediaDir = Directory(p.join(appDocs.path, 'media'));
    final allBooks = await db.bookDao.getAllBooks();

    return _archiveService.createBackupArchive(
      dbFile: dbFile,
      mediaDir: mediaDir,
      outputZipFile: targetFile,
      bookCount: allBooks.length,
    );
  }

  /// 100% Free Local Backup Restore (Anti-Lock-In Promise)
  Future<BackupManifest> importLocalBackup({
    required File sourceZipFile,
    required WidgetRef ref,
  }) async {
    ref.invalidate(appDatabaseProvider);
    final appDocs = await getApplicationDocumentsDirectory();
    final manifest = await _archiveService.restoreBackupArchive(
      backupZipFile: sourceZipFile,
      targetDirectory: appDocs,
    );
    ref.invalidate(appDatabaseProvider);
    return manifest;
  }
}

final googleDriveBackupServiceProvider =
    Provider<GoogleDriveBackupService>((ref) {
  return GoogleDriveBackupService();
});
