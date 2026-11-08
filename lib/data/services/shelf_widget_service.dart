import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/database.dart';
import '../../presentation/widgets/home_widget/shelf_home_widget_view.dart';

final shelfWidgetServiceProvider = Provider<ShelfWidgetService>((ref) {
  final shelfDao = ref.watch(shelfDaoProvider);
  return ShelfWidgetService(shelfDao: shelfDao);
});

/// Service responsible for keeping the Android / iOS Home Screen AppWidget
/// synchronized with the user's active virtual bookshelf.
class ShelfWidgetService {
  final ShelfDao shelfDao;
  static const String _prefSelectedShelfKey = 'widget_selected_shelf_id';
  static const String widgetImageKey = 'shelf_widget_image';
  static const String widgetTitleKey = 'shelf_widget_title';
  static const String androidWidgetName = 'ReadSanctuaryWidgetProvider';
  static const String iOSWidgetName = 'ReadSanctuaryWidget';

  ShelfWidgetService({required this.shelfDao});

  /// Retrieves the ID of the shelf chosen for the home screen widget.
  Future<String?> getSelectedShelfId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefSelectedShelfKey);
    } catch (_) {
      return null;
    }
  }

  /// Sets the shelf ID that should be mirrored on the home screen widget.
  Future<void> setSelectedShelfId(String shelfId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefSelectedShelfKey, shelfId);
    } catch (_) {}
  }

  /// Renders and updates the Home Screen AppWidget with the shelf layout.
  /// If [targetShelf] is provided, renders that shelf; otherwise renders the user's
  /// preferred shelf (or top shelf by default).
  Future<bool> updateWidget({
    Shelf? targetShelf,
    List<ShelfItemWithBook>? items,
  }) async {
    // Only attempt on mobile platforms
    if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
      return false;
    }

    try {
      final shelves = await shelfDao.getAllShelves();
      if (shelves.isEmpty) {
        return false;
      }

      Shelf shelfToRender;
      if (targetShelf != null) {
        shelfToRender = targetShelf;
      } else {
        final preferredId = await getSelectedShelfId();
        shelfToRender = shelves.firstWhere(
          (s) => s.id == preferredId,
          orElse: () => shelves.first,
        );
      }

      final shelfItems =
          items ?? await shelfDao.getItemsWithBooksForShelf(shelfToRender.id);

      // Render the shelf preview offscreen to PNG
      final widgetView = ShelfHomeWidgetView(
        shelfName: shelfToRender.name,
        woodThemeId: shelfToRender.woodThemeId,
        wallThemeId: shelfToRender.wallThemeId,
        items: shelfItems,
      );

      await HomeWidget.saveWidgetData<String>(
        widgetTitleKey,
        shelfToRender.name,
      );

      await HomeWidget.renderFlutterWidget(
        widgetView,
        key: widgetImageKey,
        logicalSize: const Size(400, 200),
        pixelRatio: 2.5,
      );

      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );

      return true;
    } catch (e) {
      debugPrint('ShelfWidgetService: Failed to update home widget: $e');
      return false;
    }
  }
}
