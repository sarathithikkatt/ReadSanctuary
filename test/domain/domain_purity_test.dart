import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Layer Purity Verification', () {
    test('lib/domain has zero imports from Flutter or Drift', () {
      final domainDir = Directory('lib/domain');
      expect(domainDir.existsSync(), isTrue,
          reason: 'lib/domain directory must exist');

      final forbiddenPatterns = [
        'package:flutter/',
        'package:drift/',
        'package:flutter_riverpod/',
      ];

      final dartFiles = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      expect(dartFiles.isNotEmpty, isTrue,
          reason: 'lib/domain must contain dart files');

      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        for (final pattern in forbiddenPatterns) {
          final containsForbidden = content.contains(pattern);
          expect(
            containsForbidden,
            isFalse,
            reason:
                'Domain file ${file.path} contains forbidden import "$pattern". Domain must be pure Dart!',
          );
        }
      }
    });
  });
}
