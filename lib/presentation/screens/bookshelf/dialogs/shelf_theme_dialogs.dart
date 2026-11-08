import 'package:flutter/material.dart';

import '../../../../core/theme/shelf_themes.dart';
import '../../../../data/local/database.dart';
import '../../../../data/services/revenuecat_service.dart';
import '../../settings_backup/dialogs/pro_paywall_sheet.dart';

/// Helper dialogs for customizing shelf wood material and wall backdrops.
abstract final class ShelfThemeDialogs {
  /// Opens a picker dialog for selecting shelf wood materials.
  static Future<void> showWoodThemeDialog({
    required BuildContext context,
    required Shelf shelf,
    required ShelfDao shelfDao,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Wood Style'),
        children: ShelfWoodTheme.all.map((theme) {
          return SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(theme.id),
            child: ListTile(
              leading: Icon(Icons.nature, color: theme.topSurfaceFront),
              title: Text(theme.name),
              subtitle: Text(theme.description),
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await shelfDao.updateShelf(shelf.copyWith(woodThemeId: selected));
    }
  }

  /// Opens a picker dialog for selecting shelf wallpaper or wall textures,
  /// gating premium themes with the Pro paywall.
  static Future<void> showWallThemeDialog({
    required BuildContext context,
    required Shelf shelf,
    required ShelfDao shelfDao,
    bool isProUser = false,
  }) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Choose Background Theme'),
        children: ShelfWallTheme.all.map((theme) {
          final isLocked =
              ProFeatureGate.requiresProForWallTheme(theme.id, isProUser);

          return SimpleDialogOption(
            onPressed: () {
              if (isLocked) {
                Navigator.of(context).pop();
                ProPaywallSheet.show(context, 'Wall Theme "${theme.name}"');
              } else {
                Navigator.of(context).pop(theme.id);
              }
            },
            child: ListTile(
              leading: CircleAvatar(backgroundColor: theme.fallbackColor),
              title: Text(theme.name),
              subtitle: Text(theme.description),
              trailing: isLocked
                  ? const Icon(Icons.lock, size: 16, color: Colors.amber)
                  : null,
            ),
          );
        }).toList(),
      ),
    );

    if (selected != null) {
      await shelfDao.updateShelf(shelf.copyWith(wallThemeId: selected));
    }
  }

  /// Opens a confirmation dialog to delete a shelf.
  static Future<void> showDeleteShelfDialog({
    required BuildContext context,
    required Shelf shelf,
    required ShelfDao shelfDao,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shelf'),
        content: Text('Delete "${shelf.name}" and remove all items on it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await shelfDao.deleteShelf(shelf.id);
    }
  }
}
