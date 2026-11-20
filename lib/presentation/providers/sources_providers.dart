import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/google_books_api.dart';
import '../../data/remote/metadata_aggregator_service.dart';
import '../../data/remote/open_library_api.dart';
import '../../data/remote/sources/google_books_metadata_source.dart';
import '../../data/remote/sources/open_library_metadata_source.dart';
import '../../domain/sources/book_metadata_source.dart';

/// Provider for GoogleBooksMetadataSource.
final googleBooksSourceProvider = Provider<BookMetadataSource>((ref) {
  return GoogleBooksMetadataSource(
    api: ref.watch(googleBooksApiProvider),
  );
});

/// Provider for OpenLibraryMetadataSource.
final openLibrarySourceProvider = Provider<BookMetadataSource>((ref) {
  return OpenLibraryMetadataSource(
    api: ref.watch(openLibraryApiProvider),
  );
});

/// Provider supplying registered BookMetadataSources in priority order.
final metadataSourcesProvider = Provider<List<BookMetadataSource>>((ref) {
  return [
    ref.watch(googleBooksSourceProvider),
    ref.watch(openLibrarySourceProvider),
  ];
});

/// Provider for the centralized MetadataAggregatorService.
final metadataAggregatorServiceProvider =
    Provider<MetadataAggregatorService>((ref) {
  final sources = ref.watch(metadataSourcesProvider);
  return MetadataAggregatorService(sources: sources);
});
