import 'package:flutter_test/flutter_test.dart';
import 'package:readsanctuary/core/errors/failures.dart';
import 'package:readsanctuary/data/remote/metadata_aggregator_service.dart';
import 'package:readsanctuary/domain/entities/book_metadata.dart';
import 'package:readsanctuary/domain/sources/book_metadata_source.dart';

class MockMetadataSource implements BookMetadataSource {
  @override
  final String sourceId;
  @override
  final String displayName;
  @override
  final int priority;

  Future<BookMetadata?> Function(String isbn)? onFetchByIsbn;
  Future<List<BookMetadata>> Function(String query, int limit)? onSearchByQuery;

  MockMetadataSource({
    required this.sourceId,
    required this.displayName,
    required this.priority,
    this.onFetchByIsbn,
    this.onSearchByQuery,
  });

  @override
  Future<BookMetadata?> fetchByIsbn(String isbn) async {
    if (onFetchByIsbn != null) {
      return onFetchByIsbn!(isbn);
    }
    return null;
  }

  @override
  Future<List<BookMetadata>> searchByQuery(String query, {int limit = 20}) async {
    if (onSearchByQuery != null) {
      return onSearchByQuery!(query, limit);
    }
    return [];
  }
}

void main() {
  const testIsbn = '9780765326355';

  group('MetadataAggregatorService Tests', () {
    test('Prioritizes sources with lower priority number', () async {
      final calls = <String>[];

      final primary = MockMetadataSource(
        sourceId: 'primary',
        displayName: 'Primary Source',
        priority: 10,
        onFetchByIsbn: (isbn) async {
          calls.add('primary');
          return const BookMetadata(title: 'Primary Title');
        },
      );

      final secondary = MockMetadataSource(
        sourceId: 'secondary',
        displayName: 'Secondary Source',
        priority: 20,
        onFetchByIsbn: (isbn) async {
          calls.add('secondary');
          return const BookMetadata(title: 'Secondary Title');
        },
      );

      // Pass out of order
      final aggregator =
          MetadataAggregatorService(sources: [secondary, primary]);

      final result = await aggregator.lookupByIsbn(testIsbn, enrich: false);

      expect(calls, ['primary']);
      expect(result?.title, 'Primary Title');
    });

    test(
        'Automatically falls back to secondary provider if primary throws RateLimitFailure (HTTP 429)',
        () async {
      final primary = MockMetadataSource(
        sourceId: 'google_books',
        displayName: 'Google Books',
        priority: 10,
        onFetchByIsbn: (isbn) async {
          throw const RateLimitFailure('Google Books rate limit exceeded (HTTP 429)');
        },
      );

      final secondary = MockMetadataSource(
        sourceId: 'open_library',
        displayName: 'Open Library',
        priority: 20,
        onFetchByIsbn: (isbn) async {
          return const BookMetadata(
            title: 'Dune',
            authors: ['Frank Herbert'],
            pageCount: 658,
          );
        },
      );

      final aggregator = MetadataAggregatorService(sources: [primary, secondary]);
      final result = await aggregator.lookupByIsbn(testIsbn);

      expect(result, isNotNull);
      expect(result!.title, 'Dune');
      expect(result.authors, ['Frank Herbert']);
      expect(result.pageCount, 658);
    });

    test(
        'Automatically falls back to secondary provider if primary throws NetworkFailure or times out',
        () async {
      final primary = MockMetadataSource(
        sourceId: 'primary',
        displayName: 'Primary',
        priority: 10,
        onFetchByIsbn: (isbn) async {
          throw const NetworkFailure('Connection timed out');
        },
      );

      final secondary = MockMetadataSource(
        sourceId: 'secondary',
        displayName: 'Secondary',
        priority: 20,
        onFetchByIsbn: (isbn) async {
          return const BookMetadata(title: 'The Hobbit', pageCount: 310);
        },
      );

      final aggregator = MetadataAggregatorService(sources: [primary, secondary]);
      final result = await aggregator.lookupByIsbn(testIsbn);

      expect(result, isNotNull);
      expect(result!.title, 'The Hobbit');
      expect(result.pageCount, 310);
    });

    test('Enriches partial primary result with secondary fields when missing',
        () async {
      final primary = MockMetadataSource(
        sourceId: 'primary',
        displayName: 'Primary',
        priority: 10,
        onFetchByIsbn: (isbn) async {
          // Missing coverUrl, pageCount, and publisher
          return const BookMetadata(
            title: 'Hyperion',
            authors: ['Dan Simmons'],
          );
        },
      );

      final secondary = MockMetadataSource(
        sourceId: 'secondary',
        displayName: 'Secondary',
        priority: 20,
        onFetchByIsbn: (isbn) async {
          return const BookMetadata(
            title: 'Hyperion',
            authors: ['Dan Simmons'],
            pageCount: 482,
            coverUrl: 'https://example.com/hyperion.jpg',
            publisher: 'Doubleday',
          );
        },
      );

      final aggregator = MetadataAggregatorService(sources: [primary, secondary]);
      final result = await aggregator.lookupByIsbn(testIsbn, enrich: true);

      expect(result, isNotNull);
      expect(result!.title, 'Hyperion');
      expect(result.authors, ['Dan Simmons']);
      // Enriched fields:
      expect(result.pageCount, 482);
      expect(result.coverUrl, 'https://example.com/hyperion.jpg');
      expect(result.publisher, 'Doubleday');
    });

    test('Returns null gracefully if all sources fail or return null', () async {
      final primary = MockMetadataSource(
        sourceId: 'primary',
        displayName: 'Primary',
        priority: 10,
        onFetchByIsbn: (isbn) async => throw const ServerFailure('500 Error'),
      );

      final secondary = MockMetadataSource(
        sourceId: 'secondary',
        displayName: 'Secondary',
        priority: 20,
        onFetchByIsbn: (isbn) async => null,
      );

      final aggregator = MetadataAggregatorService(sources: [primary, secondary]);
      final result = await aggregator.lookupByIsbn(testIsbn);

      expect(result, isNull);
    });

    test('search() falls back to secondary when primary throws or returns empty',
        () async {
      final primary = MockMetadataSource(
        sourceId: 'primary',
        displayName: 'Primary',
        priority: 10,
        onSearchByQuery: (query, limit) async {
          throw const RateLimitFailure('429');
        },
      );

      final secondary = MockMetadataSource(
        sourceId: 'secondary',
        displayName: 'Secondary',
        priority: 20,
        onSearchByQuery: (query, limit) async {
          return [const BookMetadata(title: 'Foundation', pageCount: 255)];
        },
      );

      final aggregator = MetadataAggregatorService(sources: [primary, secondary]);
      final results = await aggregator.search('Isaac Asimov');

      expect(results.length, 1);
      expect(results.first.title, 'Foundation');
    });
  });
}
