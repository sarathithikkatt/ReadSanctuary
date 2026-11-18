import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:readsanctuary/core/theme/shelf_themes.dart';
import 'package:readsanctuary/core/utils/image_storage_helper.dart';
import 'package:readsanctuary/data/services/custom_props_service.dart';
import 'package:readsanctuary/data/services/revenuecat_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late ImageStorageHelper storageHelper;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('props_test_');
    storageHelper = ImageStorageHelper(
      baseDirProvider: () async => tempDir,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Free Wall Themes Tests', () {
    test('Expanded free wall themes are not gated by Pro', () {
      const freeThemeIds = [
        'warm_cream',
        'classic_white',
        'soft_sage',
        'misty_grey',
        'warm_terracotta',
        'cozy_linen',
        'botanical',
      ];

      for (final id in freeThemeIds) {
        expect(
          ProFeatureGate.requiresProForWallTheme(id, false),
          isFalse,
          reason: 'Wall theme $id should be free for all users',
        );
      }
    });

    test('Dark Academia remains a Pro aesthetic choice', () {
      expect(
        ProFeatureGate.requiresProForWallTheme('dark_academia', false),
        isTrue,
      );
      expect(
        ProFeatureGate.requiresProForWallTheme('dark_academia', true),
        isFalse,
      );
    });

    test('ShelfWallTheme.all contains all free and pro themes', () {
      final ids = ShelfWallTheme.all.map((t) => t.id).toList();
      expect(ids, contains('warm_cream'));
      expect(ids, contains('classic_white'));
      expect(ids, contains('soft_sage'));
      expect(ids, contains('misty_grey'));
      expect(ids, contains('warm_terracotta'));
      expect(ids, contains('cozy_linen'));
      expect(ids, contains('botanical'));
      expect(ids, contains('dark_academia'));
    });
  });

  group('Free Decorative Shelf Props Tests', () {
    test('Most decorative props are completely free', () {
      const freeProps = [
        'gap',
        'bookend_brass',
        'plant_monstera',
        'plant_succulent',
        'candle_amber',
        'cup_coffee',
        'cat_sleeping',
        'reading_glasses',
        'globe_antique',
        'quill_inkpot',
        'crystal_prism',
      ];

      for (final propId in freeProps) {
        expect(
          ProFeatureGate.requiresProForProp(propId, false),
          isFalse,
          reason: 'Prop $propId should be free',
        );
      }
    });

    test('Custom user props are ALWAYS free', () {
      expect(ProFeatureGate.requiresProForProp('custom:12345', false), isFalse);
      expect(ProFeatureGate.requiresProForProp('custom_prop_abc', false), isFalse);
    });
  });

  group('Custom Props Creation and Persistence Tests', () {
    test('Creating a custom prop saves file and persists to SharedPreferences', () async {
      final notifier = CustomPropsNotifier(storageHelper);

      // Simple 10-byte dummy image
      final dummyBytes = Uint8List.fromList(List.generate(10, (i) => i));

      final created = await notifier.addProp(
        name: 'My Mini Dragon',
        imageBytes: dummyBytes,
        extension: 'png',
        height: 90.0,
      );

      expect(created.name, equals('My Mini Dragon'));
      expect(created.height, equals(90.0));
      expect(created.relativeImagePath, startsWith('props/custom_'));

      // Verify file exists on disk in media/props/
      final file = File('${tempDir.path}/${created.relativeImagePath}');
      expect(await file.exists(), isTrue);

      // Verify memory state
      expect(notifier.state.length, equals(1));
      expect(notifier.state.first.id, equals(created.id));

      // Verify cache
      expect(CustomPropsNotifier.getCached(created.id), isNotNull);

      // Verify persistence by reading in a fresh notifier
      final freshNotifier = CustomPropsNotifier(storageHelper);
      await freshNotifier.loadProps();
      expect(freshNotifier.state.length, equals(1));
      expect(freshNotifier.state.first.name, equals('My Mini Dragon'));

      // Test delete
      await notifier.deleteProp(created.id);
      expect(notifier.state.isEmpty, isTrue);
      expect(await file.exists(), isFalse);
    });
  });
}
