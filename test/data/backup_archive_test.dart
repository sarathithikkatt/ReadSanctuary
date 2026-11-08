import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:readsanctuary/data/services/backup_archive_service.dart';
import 'package:readsanctuary/data/services/revenuecat_service.dart';

void main() {
  late Directory tempBaseDir;
  late Directory sourceDir;
  late Directory restoreDir;
  late BackupArchiveService backupService;

  setUp(() async {
    tempBaseDir =
        await Directory.systemTemp.createTemp('shelfcraft_backup_test_');
    sourceDir = Directory(p.join(tempBaseDir.path, 'source'))..createSync();
    restoreDir = Directory(p.join(tempBaseDir.path, 'restore'))..createSync();
    backupService = BackupArchiveService();
  });

  tearDown(() async {
    if (await tempBaseDir.exists()) {
      await tempBaseDir.delete(recursive: true);
    }
  });

  String computeSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  group('Verification Gate 5 - Backup Archive & Byte-for-Byte Restoration', () {
    test(
      'Packages dummy DB and media directory into ZIP, extracts, and verifies byte-for-byte SHA256 equality',
      () async {
        // 1. Create dummy SQLite database file
        final originalDbFile =
            File(p.join(sourceDir.path, 'app_database.sqlite'));
        final dummyDbBytes = Uint8List.fromList(
          List.generate(4096, (i) => (i * 37) % 256),
        );
        await originalDbFile.writeAsBytes(dummyDbBytes);

        // 2. Create dummy media directory with covers and spines
        final mediaDir = Directory(p.join(sourceDir.path, 'media'));
        final coversDir = Directory(p.join(mediaDir.path, 'covers'))
          ..createSync(recursive: true);
        final spinesDir = Directory(p.join(mediaDir.path, 'spines'))
          ..createSync(recursive: true);

        final cover1File = File(p.join(coversDir.path, 'cover_1.jpg'));
        final cover1Bytes =
            Uint8List.fromList(List.generate(1024, (i) => (i * 13) % 256));
        await cover1File.writeAsBytes(cover1Bytes);

        final cover2File = File(p.join(coversDir.path, 'cover_2.jpg'));
        final cover2Bytes =
            Uint8List.fromList(List.generate(2048, (i) => (i * 17) % 256));
        await cover2File.writeAsBytes(cover2Bytes);

        final spine1File =
            File(p.join(spinesDir.path, 'spine_user_custom.jpg'));
        final spine1Bytes =
            Uint8List.fromList(List.generate(512, (i) => (i * 23) % 256));
        await spine1File.writeAsBytes(spine1Bytes);

        // 3. Create the ZIP backup archive
        final zipFile = File(p.join(tempBaseDir.path, 'shelfcraft_backup.zip'));
        await backupService.createBackupArchive(
          dbFile: originalDbFile,
          mediaDir: mediaDir,
          outputZipFile: zipFile,
          bookCount: 42,
        );

        expect(await zipFile.exists(), isTrue);
        expect(await zipFile.length(), greaterThan(0));

        // 4. Verify manifest integrity directly from the ZIP bytes
        final zipBytes = await zipFile.readAsBytes();
        final manifest = backupService.inspectAndVerifyArchive(zipBytes);
        expect(manifest.appName, 'ReadSanctuary');
        expect(manifest.schemaVersion, 1);
        expect(manifest.bookCount, 42);
        expect(manifest.mediaFilesCount, 3);

        // 5. Extract into fresh target restore directory
        final restoredManifest = await backupService.restoreBackupArchive(
          backupZipFile: zipFile,
          targetDirectory: restoreDir,
        );
        expect(restoredManifest.bookCount, 42);

        // 6. Verify byte-for-byte SHA-256 and size equality for Database
        final restoredDbFile =
            File(p.join(restoreDir.path, 'app_database.sqlite'));
        expect(await restoredDbFile.exists(), isTrue);
        final restoredDbBytes = await restoredDbFile.readAsBytes();
        expect(restoredDbBytes.length, dummyDbBytes.length);
        expect(computeSha256(restoredDbBytes), computeSha256(dummyDbBytes));

        // 7. Verify byte-for-byte SHA-256 and size equality for Media files
        final restoredCover1 =
            File(p.join(restoreDir.path, 'media', 'covers', 'cover_1.jpg'));
        expect(await restoredCover1.exists(), isTrue);
        final restoredCover1Bytes = await restoredCover1.readAsBytes();
        expect(computeSha256(restoredCover1Bytes), computeSha256(cover1Bytes));

        final restoredCover2 =
            File(p.join(restoreDir.path, 'media', 'covers', 'cover_2.jpg'));
        expect(await restoredCover2.exists(), isTrue);
        final restoredCover2Bytes = await restoredCover2.readAsBytes();
        expect(computeSha256(restoredCover2Bytes), computeSha256(cover2Bytes));

        final restoredSpine1 = File(p.join(
            restoreDir.path, 'media', 'spines', 'spine_user_custom.jpg'));
        expect(await restoredSpine1.exists(), isTrue);
        final restoredSpine1Bytes = await restoredSpine1.readAsBytes();
        expect(computeSha256(restoredSpine1Bytes), computeSha256(spine1Bytes));
      },
    );

    test('Rejects corrupted archive or invalid manifest', () {
      final invalidBytes =
          Uint8List.fromList(utf8.encode('NOT A VALID ZIP ARCHIVE'));
      expect(
        () => backupService.inspectAndVerifyArchive(invalidBytes),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Pro Monetization Gating Tests', () {
    test(
        'ProFeatureGate correctly gates wall themes, props, and Google Drive cloud sync',
        () {
      // Free User
      expect(ProFeatureGate.canUseGoogleDriveSync(false), isFalse);
      expect(ProFeatureGate.requiresProForWallTheme('warm_cream', false),
          isFalse); // Free
      expect(ProFeatureGate.requiresProForWallTheme('soft_sage', false),
          isFalse); // Free
      expect(ProFeatureGate.requiresProForWallTheme('midnight_library', false),
          isTrue); // Pro
      expect(ProFeatureGate.requiresProForProp('bookend_brass', false),
          isFalse); // Free
      expect(ProFeatureGate.requiresProForProp('candle_amber', false),
          isTrue); // Pro

      // Pro User
      expect(ProFeatureGate.canUseGoogleDriveSync(true), isTrue);
      expect(ProFeatureGate.requiresProForWallTheme('midnight_library', true),
          isFalse);
      expect(ProFeatureGate.requiresProForProp('candle_amber', true), isFalse);
    });
  });
}
