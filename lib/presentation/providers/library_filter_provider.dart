import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LibrarySortField {
  lastRead,
  title,
  author,
  progress,
  dateAdded,
  rating,
}

class LibraryFilterState {
  final String? status; // null for all, or 'reading', 'finished', 'tbr', 'dnf'
  final String? shelfId; // null for all
  final String searchQuery;
  final double? minRating;
  final bool hasNotes;
  final bool unreadOnly;
  final LibrarySortField sortBy;
  final bool ascending;
  final bool isGridView;

  const LibraryFilterState({
    this.status,
    this.shelfId,
    this.searchQuery = '',
    this.minRating,
    this.hasNotes = false,
    this.unreadOnly = false,
    this.sortBy = LibrarySortField.lastRead,
    this.ascending = false,
    this.isGridView = true,
  });

  LibraryFilterState copyWith({
    String? Function()? status,
    String? Function()? shelfId,
    String? searchQuery,
    double? Function()? minRating,
    bool? hasNotes,
    bool? unreadOnly,
    LibrarySortField? sortBy,
    bool? ascending,
    bool? isGridView,
  }) {
    return LibraryFilterState(
      status: status != null ? status() : this.status,
      shelfId: shelfId != null ? shelfId() : this.shelfId,
      searchQuery: searchQuery ?? this.searchQuery,
      minRating: minRating != null ? minRating() : this.minRating,
      hasNotes: hasNotes ?? this.hasNotes,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      isGridView: isGridView ?? this.isGridView,
    );
  }
}

class LibraryFilterNotifier extends StateNotifier<LibraryFilterState> {
  LibraryFilterNotifier() : super(const LibraryFilterState()) {
    _loadPreferences();
  }

  static const _prefSortBy = 'library_sort_by';
  static const _prefAscending = 'library_sort_ascending';
  static const _prefGridView = 'library_is_grid_view';

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sortName = prefs.getString(_prefSortBy);
      final ascending = prefs.getBool(_prefAscending) ?? false;
      final isGridView = prefs.getBool(_prefGridView) ?? true;

      LibrarySortField sortBy = LibrarySortField.lastRead;
      if (sortName != null) {
        sortBy = LibrarySortField.values.firstWhere(
          (e) => e.name == sortName,
          orElse: () => LibrarySortField.lastRead,
        );
      }

      state = state.copyWith(
        sortBy: sortBy,
        ascending: ascending,
        isGridView: isGridView,
      );
    } catch (_) {}
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setShelfId(String? shelfId) {
    state = state.copyWith(shelfId: () => shelfId);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: () => status);
  }

  void setMinRating(double? rating) {
    state = state.copyWith(minRating: () => rating);
  }

  void setSortBy(LibrarySortField sortBy, {bool? ascending}) {
    final asc = ascending ?? (state.sortBy == sortBy ? !state.ascending : false);
    state = state.copyWith(sortBy: sortBy, ascending: asc);
    _savePreferences();
  }

  void toggleGridView() {
    state = state.copyWith(isGridView: !state.isGridView);
    _savePreferences();
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefSortBy, state.sortBy.name);
      await prefs.setBool(_prefAscending, state.ascending);
      await prefs.setBool(_prefGridView, state.isGridView);
    } catch (_) {}
  }
}

final libraryFilterProvider =
    StateNotifierProvider<LibraryFilterNotifier, LibraryFilterState>((ref) {
  return LibraryFilterNotifier();
});
