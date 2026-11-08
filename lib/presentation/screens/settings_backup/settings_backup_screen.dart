import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/database.dart';
import '../../../data/services/csv_import_service.dart';
import '../../../data/services/google_drive_backup_service.dart';
import '../../../data/services/revenuecat_service.dart';
import '../../../data/services/shelf_widget_service.dart';
import 'dialogs/gift_redeem_dialog.dart';
import 'dialogs/pro_paywall_sheet.dart';
import 'widgets/pro_status_banner.dart';

/// Screen managing Google Drive Cloud Sync (Pro), Local Backup Export/Import (100% Free),
/// CSV Migration & Export, and Promotional Gift Code Redemption.
class SettingsBackupScreen extends ConsumerStatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  ConsumerState<SettingsBackupScreen> createState() =>
      _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends ConsumerState<SettingsBackupScreen> {
  bool _isBackingUp = false;
  int _creatorTapCount = 0;

  Future<void> _handleGoogleDriveBackup() async {
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      ProPaywallSheet.show(context, 'Google Drive Cloud Sync');
      return;
    }

    setState(() => _isBackingUp = true);
    final backupService = ref.read(googleDriveBackupServiceProvider);
    final db = ref.read(appDatabaseProvider);

    final result = await backupService.createAndUploadBackup(db: db);
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

    final result = await backupService.downloadAndRestoreBackup(ref: ref);
    setState(() => _isBackingUp = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _handleLocalExport() async {
    try {
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName:
            'shelfcraft_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
      );
      if (result == null) return;

      setState(() => _isBackingUp = true);
      final backupService = ref.read(googleDriveBackupServiceProvider);
      final db = ref.read(appDatabaseProvider);

      await backupService.exportLocalBackup(
        db: db,
        targetFile: File(result.path),
      );
      setState(() => _isBackingUp = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Local backup archive exported successfully! 📦')),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Local Backup? 📦'),
        content: const Text(
          'Restoring will replace your current local library, book spines, and shelves with the contents of the backup archive.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      const typeGroup = XTypeGroup(
        label: 'ZIP Backup Archives',
        extensions: ['zip'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

      setState(() => _isBackingUp = true);
      final backupService = ref.read(googleDriveBackupServiceProvider);
      final manifest = await backupService.importLocalBackup(
        sourceZipFile: File(file.path),
        ref: ref,
      );
      setState(() => _isBackingUp = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Library restored successfully (${manifest.bookCount} books)! 📚✨',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isBackingUp = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Local restore failed: $e')),
        );
      }
    }
  }

  Future<void> _handleCsvImport() async {
    try {
      const typeGroup = XTypeGroup(
        label: 'CSV Files',
        extensions: ['csv'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file == null) return;

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

      // Populate shelf items for imported books so they render immediately
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
      final FileSaveLocation? result = await getSaveLocation(
        suggestedName:
            'shelfcraft_library_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      if (result == null) return;

      final db = ref.read(appDatabaseProvider);
      final books = await db.bookDao.getAllBooks();

      final csvService = ref.read(csvImportServiceProvider);
      final csvString = csvService.exportToCsv(books);

      final file = File(result.path);
      await file.writeAsString(csvString);

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
              'ShelfCraft Pro is currently ACTIVE.\nUnlock Source: $source\n\nWould you like to reset back to Free tier for testing?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep Pro'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child:
                    const Text('Reset to Free', style: TextStyle(color: Colors.white)),
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
                // Pro Banner
                ProStatusBanner(
                  isPro: isPro,
                  onTap: !isPro
                      ? () => ProPaywallSheet.show(context, 'ShelfCraft Pro')
                      : null,
                ),

                // Redeem Gift Code Tile
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

                // Google Drive Sync (Pro)
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined,
                      color: Colors.blue),
                  title: const Text('Google Drive AppData Backup'),
                  subtitle: const Text('Automated sandbox sync (Pro)'),
                  trailing: isPro
                      ? null
                      : const Icon(Icons.lock, size: 18, color: Colors.amber),
                  onTap: _handleGoogleDriveBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined,
                      color: Colors.blue),
                  title: const Text('Google Drive Restore'),
                  subtitle: const Text('Restore library from Google Drive'),
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
                    'DATA FREEDOM (100% FREE)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_zip_outlined,
                      color: Colors.green),
                  title: const Text('Export Local .ZIP Backup'),
                  subtitle:
                      const Text('SQLite database + covers + spines archive'),
                  onTap: _handleLocalExport,
                ),
                ListTile(
                  leading: const Icon(Icons.unarchive_outlined,
                      color: Colors.green),
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
                              'ShelfCraft v1.0.0',
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
