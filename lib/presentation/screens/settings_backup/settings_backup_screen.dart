import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/cover_cache_manager.dart';
import '../../../data/backup/restore_backup_service.dart';
import '../../../data/local/database.dart';
import '../../../data/services/csv_import_service.dart';
import '../../../data/services/google_drive_backup_service.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../data/services/shelf_widget_service.dart';
import '../bookshelf/manage_shelves_screen.dart';
import 'dialogs/gift_redeem_dialog.dart';
import 'dialogs/pro_paywall_sheet.dart';
import 'widgets/pro_status_banner.dart';

/// Screen managing Google Drive Cloud Sync (Pro), Local Backup Export/Import (.rsbk & .zip),
/// Storage Management, and Settings.
class SettingsBackupScreen extends ConsumerStatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  ConsumerState<SettingsBackupScreen> createState() =>
      _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends ConsumerState<SettingsBackupScreen> {
  bool _isBackingUp = false;
  int _creatorTapCount = 0;
  int _dbSizeBytes = 0;
  int _coverCacheSizeBytes = 0;

  @override
  void initState() {
    super.initState();
    _refreshStorageStats();
  }

  Future<void> _refreshStorageStats() async {
    try {
      final appDocs = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(appDocs.path, 'app_database.sqlite'));
      final dbBytes = dbFile.existsSync() ? dbFile.lengthSync() : 0;

      final coverCache = ref.read(coverCacheManagerProvider);
      final cacheBytes = await coverCache.getCacheSizeBytes();

      if (mounted) {
        setState(() {
          _dbSizeBytes = dbBytes;
          _coverCacheSizeBytes = cacheBytes;
        });
      }
    } catch (_) {}
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleGoogleDriveBackup() async {
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      ProPaywallSheet.show(context, 'Google Drive Cloud Sync');
      return;
    }

    setState(() => _isBackingUp = true);
    final backupService = ref.read(googleDriveBackupServiceProvider);
    final db = ref.read(appDatabaseProvider);

    final result = await backupService.createAndUploadRsbkBackup(db: db);
    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _handleGoogleDriveRestore() async {
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      ProPaywallSheet.show(context, 'Google Drive Cloud Restore');
      return;
    }

    setState(() => _isBackingUp = true);
    final backupService = ref.read(googleDriveBackupServiceProvider);
    final db = ref.read(appDatabaseProvider);

    final result = await backupService.downloadAndRestoreLatestRsbk(
      db: db,
      mode: RestoreMode.smartMerge,
    );
    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _handleRsbkExport() async {
    try {
      final filename =
          'readsanctuary_snapshot_${DateTime.now().millisecondsSinceEpoch}.rsbk';
      File targetFile;

      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        targetFile = File(p.join(tempDir.path, filename));
      } else {
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: filename,
        );
        if (result == null) return;
        targetFile = File(result.path);
      }

      setState(() => _isBackingUp = true);
      final backupService = ref.read(googleDriveBackupServiceProvider);
      final db = ref.read(appDatabaseProvider);

      await backupService.exportLocalRsbk(
        db: db,
        targetFile: targetFile,
      );

      setState(() => _isBackingUp = false);

      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(targetFile.path, mimeType: 'application/gzip')],
            text: 'ReadSanctuary Versioned Snapshot (.rsbk) 📚',
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported snapshot to ${targetFile.path}')),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _handleRsbkImport() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'ReadSanctuary Backup (.rsbk)',
        extensions: ['rsbk', 'gz'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      if (!mounted) return;

      final shouldMerge = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup Snapshot'),
          content: const Text(
            'Smart Merge (Recommended): Merges records using Last-Write-Wins and preserves books you added recently.\n\nOverwrite: Clears local library and replaces everything with this backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Smart Merge'),
            ),
          ],
        ),
      );

      if (shouldMerge != true) return;

      setState(() => _isBackingUp = true);
      final backupService = ref.read(googleDriveBackupServiceProvider);
      final db = ref.read(appDatabaseProvider);

      final result = await backupService.importLocalRsbk(
        db: db,
        sourceFile: File(file.path),
        mode: RestoreMode.smartMerge,
      );

      setState(() => _isBackingUp = false);
      await _refreshStorageStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _handleLocalExport() async {
    try {
      final filename =
          'readsanctuary_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      File targetFile;

      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        targetFile = File(p.join(tempDir.path, filename));
      } else {
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: filename,
        );
        if (result == null) return;
        targetFile = File(result.path);
      }

      setState(() => _isBackingUp = true);
      final backupService = ref.read(googleDriveBackupServiceProvider);
      final db = ref.read(appDatabaseProvider);

      await backupService.exportLocalBackup(
        db: db,
        targetFile: targetFile,
      );

      setState(() => _isBackingUp = false);

      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(targetFile.path, mimeType: 'application/zip')],
            text: 'ReadSanctuary Library Backup Archive 📚',
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported backup to ${targetFile.path}')),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _handleLocalRestore() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'ZIP Archive',
        extensions: ['zip'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      if (!mounted) return;

      setState(() => _isBackingUp = true);
      final backupService = ref.read(googleDriveBackupServiceProvider);

      final manifest = await backupService.importLocalBackup(
        sourceZipFile: File(file.path),
        ref: ref,
      );

      setState(() => _isBackingUp = false);
      await _refreshStorageStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Library restored from archive (${manifest.bookCount} books)! 📚✨',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
  }

  Future<void> _handleCsvImport() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'CSV File',
        extensions: ['csv'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;
      if (!mounted) return;

      final content = await file.readAsString();
      final csvService = ref.read(csvImportServiceProvider);
      final parseResult = csvService.parseCsv(content);

      if (parseResult.books.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No books parsed from CSV.')),
          );
        }
        return;
      }

      final db = ref.read(appDatabaseProvider);
      await db.bookDao.insertBooks(parseResult.books);

      var shelves = await db.shelfDao.getAllShelves();
      if (shelves.isEmpty) {
        await db.shelfDao.insertShelf(
          ShelvesCompanion.insert(
            id: 'default-shelf-imported',
            name: 'Imported Library',
            sortOrder: 0,
          ),
        );
        shelves = await db.shelfDao.getAllShelves();
      }

      final targetShelfId = shelves.first.id;
      final existingItems = await db.shelfDao.getItemsForShelf(targetShelfId);
      const uuid = Uuid();
      final shelfItems = <ShelfItemsCompanion>[];

      for (int i = 0; i < parseResult.books.length; i++) {
        final b = parseResult.books[i];
        shelfItems.add(
          ShelfItemsCompanion.insert(
            id: uuid.v4(),
            shelfId: targetShelfId,
            itemType: 'book',
            bookId: drift.Value(b.id.value),
            positionIndex: existingItems.length + i,
          ),
        );
      }
      await db.shelfDao.insertShelfItems(shelfItems);
      await _refreshStorageStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${parseResult.successCount} books from CSV! 📚',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV import error: $e')),
        );
      }
    }
  }

  Future<void> _handleCsvExport() async {
    try {
      final filename =
          'readsanctuary_library_${DateTime.now().millisecondsSinceEpoch}.csv';
      File targetFile;

      if (Platform.isAndroid || Platform.isIOS) {
        final tempDir = await getTemporaryDirectory();
        targetFile = File(p.join(tempDir.path, filename));
      } else {
        final FileSaveLocation? result = await getSaveLocation(
          suggestedName: filename,
        );
        if (result == null) return;
        targetFile = File(result.path);
      }

      final db = ref.read(appDatabaseProvider);
      final books = await db.bookDao.getAllBooks();

      final csvService = ref.read(csvImportServiceProvider);
      final csvString = csvService.exportToCsv(books);

      await targetFile.writeAsString(csvString);

      if (Platform.isAndroid || Platform.isIOS) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(targetFile.path, mimeType: 'text/csv')],
            text: 'ReadSanctuary Books CSV Export 📄',
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${books.length} books to CSV! 📄'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV export failed: $e')),
        );
      }
    }
  }

  void _onVersionTapped() async {
    _creatorTapCount++;
    if (_creatorTapCount >= 7) {
      _creatorTapCount = 0;
      final isPro = ref.read(isProUserProvider);
      if (isPro) {
        final source =
            ref.read(isProUserProvider.notifier).unlockSource ?? 'unknown';
        final reset = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Creator Debug Menu 🛠️'),
            content: Text(
              'ReadSanctuary Pro is currently ACTIVE.\nUnlock Source: $source\n\nWould you like to reset back to Free tier for testing?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Pro'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Reset to Free',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (reset == true) {
          await ref.read(isProUserProvider.notifier).resetProStatus();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to Free tier.')),
            );
          }
        }
      } else {
        await GiftRedeemDialog.show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(isProUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Data Backup'),
      ),
      body: _isBackingUp
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing backup operation...'),
                ],
              ),
            )
          : ListView(
              children: [
                ProStatusBanner(
                  isPro: isPro,
                  onTap: !isPro
                      ? () => ProPaywallSheet.show(context, 'ReadSanctuary Pro')
                      : null,
                ),

                ListTile(
                  leading: const Icon(Icons.card_giftcard, color: Colors.amber),
                  title: const Text('Redeem Gift Code / Voucher'),
                  subtitle: Text(isPro
                      ? 'Pro is active on this device (${ref.watch(isProUserProvider.notifier).unlockSource ?? "unlocked"})'
                      : 'Have a promotional key or gift pass? Enter it here'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => GiftRedeemDialog.show(context),
                ),

                const Divider(),

                // Storage & Cache Analytics
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'STORAGE & LOCAL CACHE',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.storage_outlined, color: Colors.blueGrey),
                  title: const Text('Local Database Size'),
                  subtitle: Text(_formatBytes(_dbSizeBytes)),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: _refreshStorageStats,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined, color: Colors.teal),
                  title: const Text('Offline Cover Cache'),
                  subtitle: Text(_formatBytes(_coverCacheSizeBytes)),
                  trailing: TextButton(
                    onPressed: () async {
                      await ref.read(coverCacheManagerProvider).clearCoverCache();
                      await _refreshStorageStats();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cover cache cleared.')),
                        );
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ),
                ListTile(
                  leading:
                      const Icon(Icons.category_outlined, color: Colors.purple),
                  title: const Text('Manage Shelves & Categories'),
                  subtitle: const Text('Reorder or edit custom shelves'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ManageShelvesScreen()),
                  ),
                ),

                const Divider(),

                // Google Drive Sync (Pro)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'CLOUD SYNC (PRO)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined,
                      color: Colors.blue),
                  title: const Text('Google Drive AppData Backup'),
                  subtitle: const Text('Automated sandbox sync with 5-snapshot retention'),
                  trailing: isPro
                      ? null
                      : const Icon(Icons.lock, size: 18, color: Colors.amber),
                  onTap: _handleGoogleDriveBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined,
                      color: Colors.blue),
                  title: const Text('Google Drive Restore'),
                  subtitle: const Text('Smart-merge newest cloud snapshot'),
                  trailing: isPro
                      ? null
                      : const Icon(Icons.lock, size: 18, color: Colors.amber),
                  onTap: _handleGoogleDriveRestore,
                ),

                const Divider(),

                // 100% Free Local Backup (Anti-Lock-In)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'PORTABLE BACKUPS (100% FREE & OPEN)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.save_alt_outlined, color: Colors.green),
                  title: const Text('Export .RSBK Snapshot'),
                  subtitle: const Text('Portable Gzipped versioned JSON snapshot'),
                  onTap: _handleRsbkExport,
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined, color: Colors.green),
                  title: const Text('Import & Merge .RSBK Snapshot'),
                  subtitle: const Text('Smart idempotent merge (Last-Write-Wins)'),
                  onTap: _handleRsbkImport,
                ),
                ListTile(
                  leading: const Icon(Icons.folder_zip_outlined,
                      color: Colors.blueGrey),
                  title: const Text('Export Local .ZIP Backup'),
                  subtitle:
                      const Text('SQLite database + covers + spines archive'),
                  onTap: _handleLocalExport,
                ),
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined,
                      color: Colors.blueGrey),
                  title: const Text('Restore Local .ZIP Backup'),
                  subtitle:
                      const Text('Restore whole library from .zip archive file'),
                  onTap: _handleLocalRestore,
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined,
                      color: Colors.teal),
                  title: const Text('Import Goodreads / StoryGraph CSV'),
                  subtitle: const Text('Migrate reading history and ratings'),
                  onTap: _handleCsvImport,
                ),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined,
                      color: Colors.teal),
                  title: const Text('Export Library to CSV'),
                  subtitle: const Text('Export books, authors, and ratings'),
                  onTap: _handleCsvExport,
                ),

                const Divider(),

                // Home Screen Widget
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'HOME SCREEN WIDGET',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.widgets_outlined,
                      color: Colors.amber),
                  title: const Text('Refresh Home Screen Widget'),
                  subtitle: const Text(
                      'Re-renders shelf layout to launcher AppWidget'),
                  trailing: const Icon(Icons.refresh, size: 20),
                  onTap: () async {
                    final widgetService = ref.read(shelfWidgetServiceProvider);
                    final success = await widgetService.updateWidget();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Home Screen Widget refreshed! 📚✨'
                              : 'Could not update widget on this device'),
                        ),
                      );
                    }
                  },
                ),

                const Divider(),

                // Footer with Creator Easter Egg
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: InkWell(
                      onTap: _onVersionTapped,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(
                              'ReadSanctuary v1.2.0',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Local-First • Offline-First • Open SQLite',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
