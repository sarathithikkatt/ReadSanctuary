import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/image_storage_helper.dart';

/// Representation of a user-created custom decorative shelf prop.
class CustomPropItem {
  final String id;
  final String name;
  final String relativeImagePath;
  final double height;
  final int createdAt;

  const CustomPropItem({
    required this.id,
    required this.name,
    required this.relativeImagePath,
    this.height = 80.0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'relativeImagePath': relativeImagePath,
        'height': height,
        'createdAt': createdAt,
      };

  factory CustomPropItem.fromJson(Map<String, dynamic> json) => CustomPropItem(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Custom Prop',
        relativeImagePath: json['relativeImagePath'] as String,
        height: (json['height'] as num?)?.toDouble() ?? 80.0,
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

/// State notifier managing the list of user-created decorative props.
class CustomPropsNotifier extends StateNotifier<List<CustomPropItem>> {
  static const String spKeyCustomProps = 'shelfcraft_custom_props_json';
  final ImageStorageHelper _storage;
  final Uuid _uuid;

  CustomPropsNotifier(this._storage, {Uuid? uuid})
      : _uuid = uuid ?? const Uuid(),
        super([]) {
    loadProps();
  }

  /// In-memory cache for fast synchronous lookup by prop ID
  static final Map<String, CustomPropItem> _cache = {};

  static CustomPropItem? getCached(String id) => _cache[id];

  /// Loads custom props from SharedPreferences.
  Future<void> loadProps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(spKeyCustomProps);
      if (rawJson != null && rawJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawJson);
        final list = decoded
            .map((item) => CustomPropItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _updateCache(list);
        state = list;
      }
    } catch (_) {}
  }

  void _updateCache(List<CustomPropItem> list) {
    _cache.clear();
    for (final p in list) {
      _cache[p.id] = p;
    }
  }

  /// Adds a new custom prop from image bytes.
  Future<CustomPropItem> addProp({
    required String name,
    required Uint8List imageBytes,
    String extension = 'png',
    double height = 80.0,
  }) async {
    final propId = 'custom_${_uuid.v4().substring(0, 8)}';
    final filename = '$propId.$extension';

    final relativePath = await _storage.savePropBytes(
      imageBytes,
      filename: filename,
      extension: extension,
    );

    final newProp = CustomPropItem(
      id: propId,
      name: name.trim().isEmpty ? 'Custom Prop' : name.trim(),
      relativeImagePath: relativePath,
      height: height.clamp(40.0, 160.0),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );

    final updated = [...state, newProp];
    state = updated;
    _updateCache(updated);
    await _persist();
    return newProp;
  }

  /// Deletes a custom prop and removes its image file.
  Future<void> deleteProp(String id) async {
    final item = state.firstWhere((p) => p.id == id, orElse: () => const CustomPropItem(
      id: '',
      name: '',
      relativeImagePath: '',
      createdAt: 0,
    ));

    if (item.id.isNotEmpty && item.relativeImagePath.isNotEmpty) {
      try {
        await _storage.deleteFile(item.relativeImagePath);
      } catch (_) {}
    }

    final updated = state.where((p) => p.id != id).toList();
    state = updated;
    _updateCache(updated);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(state.map((p) => p.toJson()).toList());
      await prefs.setString(spKeyCustomProps, encoded);
    } catch (_) {}
  }
}

final customPropsProvider =
    StateNotifierProvider<CustomPropsNotifier, List<CustomPropItem>>((ref) {
  final storage = ref.watch(imageStorageHelperProvider);
  return CustomPropsNotifier(storage);
});
