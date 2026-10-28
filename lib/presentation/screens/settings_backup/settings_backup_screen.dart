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

/// Screen managing Google Drive Cloud Sync (Pro), Local Backup Export/Import (100% Free),
/// and CSV Migration (Goodreads, StoryGraph).
class SettingsBackupScreen extends ConsumerStatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  ConsumerState<SettingsBackupScreen> createState() => _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends ConsumerState<SettingsBackupScreen> {
  bool _isBackingUp = false;

  Future<void> _handleGoogleDriveBackup() async {
    final isPro = ref.read(isProUserProvider);
    if (!isPro) {
      _showProPaywallModal('Google Drive Cloud Sync');
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
      _showProPaywallModal('Google Drive Cloud Restore');
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
        suggestedName: 'shelfcraft_backup_${DateTime.now().millisecondsSinceEpoch}.zip',
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
          const SnackBar(content: Text('Local backup exported successfully! 📦')),
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

  void _showProPaywallModal(String featureName) {
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (modalContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, size: 54, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              'Unlock ShelfCraft Pro',
              style: Theme.of(modalContext).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '$featureName is a Pro feature.\nSupport independent local-first software with a fair, low one-time lifetime unlock or annual pass.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                ref.read(isProUserProvider.notifier).setDebugProOverride(true);
                Navigator.of(modalContext).pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Pro unlocked! Thank you! 🌟')),
                );
              },
              child: const Text('Unlock Lifetime Pro (\$9.99)'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(modalContext).pop(),
              child: const Text('Maybe Later'),
            ),
          ],
        ),
      ),
    );
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
                Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPro
                          ? [Colors.amber.shade700, Colors.orange.shade800]
                          : [Colors.grey.shade800, Colors.black87],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPro ? Icons.verified : Icons.lock_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isPro ? 'ShelfCraft Pro Active' : 'ShelfCraft Free',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              isPro
                                  ? 'Automated Google Drive Sync & Premium Cosmetics unlocked'
                                  : 'Local backups & CSV exports remain 100% Free forever',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Google Drive Sync (Pro)
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: Colors.blue),
                  title: const Text('Google Drive AppData Backup'),
                  subtitle: const Text('Automated sandbox sync (Pro)'),
                  trailing: isPro ? null : const Icon(Icons.lock, size: 18, color: Colors.amber),
                  onTap: _handleGoogleDriveBackup,
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined, color: Colors.blue),
                  title: const Text('Google Drive Restore'),
                  subtitle: const Text('Restore library from Google Drive'),
                  trailing: isPro ? null : const Icon(Icons.lock, size: 18, color: Colors.amber),
                  onTap: _handleGoogleDriveRestore,
                ),

                const Divider(),

                // 100% Free Local Backup (Anti-Lock-In)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'DATA FREEDOM (100% FREE)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder_zip_outlined, color: Colors.green),
                  title: const Text('Export Local .ZIP Backup'),
                  subtitle: const Text('SQLite database + covers + spines archive'),
                  onTap: _handleLocalExport,
                ),
                ListTile(
                  leading: const Icon(Icons.file_upload_outlined, color: Colors.teal),
                  title: const Text('Import Goodreads / StoryGraph CSV'),
                  subtitle: const Text('Migrate reading history and ratings'),
                  onTap: _handleCsvImport,
                ),
              ],
            ),
    );
  }
}
