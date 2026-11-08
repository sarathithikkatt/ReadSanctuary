import 'dart:io';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../local/database.dart';
import 'backup_archive_service.dart';

/// Result status of a Google Drive backup or restore operation.
class BackupOperationResult {
  final bool success;
  final String message;
  final BackupManifest? manifest;

  const BackupOperationResult({
    required this.success,
    required this.message,
    this.manifest,
  });
}

/// Service managing automated Google Drive AppData sandbox backup & restore,
/// SQLite WAL checkpointing, and local anti-lock-in ZIP export/import.
class GoogleDriveBackupService {
  static const String backupFileName = 'shelfcraft_backup.zip';
  final GoogleSignIn _googleSignIn;
  final BackupArchiveService _archiveService;

  GoogleDriveBackupService({
    GoogleSignIn? googleSignIn,
    BackupArchiveService? archiveService,
  })  : _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: [drive.DriveApi.driveAppdataScope],
            ),
        _archiveService = archiveService ?? BackupArchiveService();

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

  /// Creates and uploads a full backup archive to Google Drive appDataFolder.
  /// Flushes SQLite WAL first so that app_database.sqlite is 100% current.
  Future<BackupOperationResult> createAndUploadBackup({
    required AppDatabase db,
  }) async {
    try {
      // 1. Ensure user is authenticated
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
        // Update existing backup file
        final existingId = fileList.files!.first.id!;
        await driveApi.files.update(
          drive.File(),
          existingId,
          uploadMedia: uploadMedia,
        );
      } else {
        // Create new backup file in appDataFolder
        final driveFile = drive.File(
          name: backupFileName,
          parents: ['appDataFolder'],
        );
        await driveApi.files.create(
          driveFile,
          uploadMedia: uploadMedia,
        );
      }

      // Cleanup local temp zip
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

      // 1. Locate file in appDataFolder
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

      // 2. Download into temporary file
      final tempDir = await getTemporaryDirectory();
      final tempZip = File(p.join(tempDir.path, 'downloaded_$backupFileName'));

      final media = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final sink = tempZip.openWrite();
      await media.stream.pipe(sink);

      // 3. Close active database connection to safely replace SQLite file
      ref.invalidate(appDatabaseProvider);

      // 4. Extract into App Documents Directory
      final appDocs = await getApplicationDocumentsDirectory();
      final manifest = await _archiveService.restoreBackupArchive(
        backupZipFile: tempZip,
        targetDirectory: appDocs,
      );

      // 5. Cleanup temp downloaded zip
      if (await tempZip.exists()) {
        await tempZip.delete();
      }

      // 6. Refresh provider so UI and DAOs reconnect to restored DB
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
