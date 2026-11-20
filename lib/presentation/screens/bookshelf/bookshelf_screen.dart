import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/local/database.dart';
import '../../../data/services/shelf_widget_service.dart';
import '../../providers/filtered_library_provider.dart';
import '../../providers/library_filter_provider.dart';
import '../book_search/book_search_screen.dart';
import '../scanner/barcode_scanner_screen.dart';
import 'dialogs/add_book_dialog.dart';
import 'dialogs/add_shelf_dialog.dart';
import 'dialogs/library_filter_bottom_sheet.dart';
import 'manage_shelves_screen.dart';
import 'shelf_share_exporter.dart';
import 'widgets/library_grid_view.dart';
import 'widgets/shelf_empty_state.dart';
import 'widgets/shelf_section.dart';

/// Main bookshelf screen supporting both tactile 3D wooden shelves
/// and high-signal Mihon-inspired 2D category grid/list view with FTS5 search.
class BookshelfScreen extends ConsumerStatefulWidget {
  const BookshelfScreen({super.key});

  @override
  ConsumerState<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends ConsumerState<BookshelfScreen> {
  final GlobalKey _shelfExportKey = GlobalKey();
  bool _isReorderMode = false;
  bool _isGridLibraryMode = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late final Stream<List<Shelf>> _shelvesStream;

  @override
  void initState() {
    super.initState();
    _shelvesStream = ref.read(shelfDaoProvider).watchAllShelves();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shelfWidgetServiceProvider).updateWidget();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shelfDao = ref.watch(shelfDaoProvider);
    final bookDao = ref.watch(bookDaoProvider);
    final filterState = ref.watch(libraryFilterProvider);
    final filterNotifier = ref.read(libraryFilterProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Search title, author, notes...',
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        filterNotifier.setSearchQuery('');
                        setState(() => _isSearching = false);
                      },
                    ),
                  ),
                  onChanged: (val) => filterNotifier.setSearchQuery(val),
                ),
              )
            : Text(
                _isGridLibraryMode ? 'Library' : 'ReadSanctuary',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
        actions: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.qr_code_scanner, size: 22),
            tooltip: 'Scan ISBN Barcode',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(_isSearching ? Icons.search_off : Icons.search, size: 22),
            tooltip: 'Search Library',
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  filterNotifier.setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: Icon(_isGridLibraryMode ? Icons.shelves : Icons.grid_view, size: 22),
            tooltip: _isGridLibraryMode ? 'View Bookshelf' : 'View Library Grid',
            onPressed: () =>
                setState(() => _isGridLibraryMode = !_isGridLibraryMode),
          ),
          if (_isGridLibraryMode)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(filterState.isGridView ? Icons.view_list : Icons.grid_view, size: 22),
              tooltip: filterState.isGridView ? 'List View' : 'Grid View',
              onPressed: () => filterNotifier.toggleGridView(),
            ),
          if (_isGridLibraryMode)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.filter_list, size: 22),
              tooltip: 'Filter & Sort',
              onPressed: () => LibraryFilterBottomSheet.show(context),
            ),
          if (!_isGridLibraryMode)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(_isReorderMode ? Icons.done : Icons.swap_horiz, size: 22),
              tooltip: _isReorderMode ? 'Done Reordering' : 'Reorder Books',
              onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 22),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              switch (value) {
                case 'barcode':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const BarcodeScannerScreen()),
                  );
                  break;
                case 'search_free':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const BookSearchScreen()),
                  );
                  break;
                case 'manage_shelves':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ManageShelvesScreen()),
                  );
                  break;
                case 'add_shelf':
                  AddShelfDialog.show(context, shelfDao);
                  break;
                case 'share':
                  ShelfShareExporter.exportAndShare(
                    repaintBoundaryKey: _shelfExportKey,
                  );
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'manage_shelves',
                child: Row(
                  children: [
                    Icon(Icons.category_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Shelves'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'barcode',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 8),
                    Text('Scan Barcode'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'search_free',
                child: Row(
                  children: [
                    Icon(Icons.public, size: 20),
                    SizedBox(width: 8),
                    Text('Find Free Books'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'add_shelf',
                child: Row(
                  children: [
                    Icon(Icons.add_to_photos_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Add Shelf'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Share Shelf Image'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 2,
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Add Book',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        onPressed: () => AddBookDialog.show(context, shelfDao, bookDao),
      ),
      body: _isGridLibraryMode
          ? _buildLibraryGridMode(shelfDao, filterState, filterNotifier)
          : _buildTactileBookshelfMode(shelfDao, bookDao),
    );
  }

  Widget _buildLibraryGridMode(
    ShelfDao shelfDao,
    LibraryFilterState filterState,
    LibraryFilterNotifier filterNotifier,
  ) {
    final filteredAsync = ref.watch(filteredBooksProvider);

    return Column(
      children: [
        // Category / Shelf Tab Bar
        StreamBuilder<List<Shelf>>(
          stream: _shelvesStream,
          builder: (context, snapshot) {
            final shelves = snapshot.data ?? [];
            return Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      showCheckmark: false,
                      label: const Text('All Books'),
                      selected: filterState.shelfId == null,
                      selectedColor: AppColors.primaryBurgundy.withOpacity(0.14),
                      side: BorderSide(
                        color: filterState.shelfId == null
                            ? AppColors.primaryBurgundy.withOpacity(0.4)
                            : Colors.black.withOpacity(0.08),
                      ),
                      onSelected: (_) => filterNotifier.setShelfId(null),
                    ),
                  ),
                  for (final shelf in shelves)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        showCheckmark: false,
                        label: Text(shelf.name),
                        selected: filterState.shelfId == shelf.id,
                        selectedColor:
                            AppColors.primaryBurgundy.withOpacity(0.14),
                        side: BorderSide(
                          color: filterState.shelfId == shelf.id
                              ? AppColors.primaryBurgundy.withOpacity(0.4)
                              : Colors.black.withOpacity(0.08),
                        ),
                        onSelected: (_) => filterNotifier.setShelfId(shelf.id),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1),
        // Books Grid / List
        Expanded(
          child: filteredAsync.when(
            data: (books) => LibraryGridView(
              books: books,
              isGridView: filterState.isGridView,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildTactileBookshelfMode(ShelfDao shelfDao, BookDao bookDao) {
    return RepaintBoundary(
      key: _shelfExportKey,
      child: StreamBuilder<List<Shelf>>(
        stream: _shelvesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final shelves = snapshot.data ?? [];
          if (shelves.isEmpty) {
            return ShelfEmptyState(
              onAddShelf: () => AddShelfDialog.show(context, shelfDao),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80.0),
            itemCount: shelves.length,
            itemBuilder: (context, index) {
              final shelf = shelves[index];
              return ShelfSection(
                shelf: shelf,
                shelfDao: shelfDao,
                bookDao: bookDao,
                isReorderable: _isReorderMode,
              );
            },
          );
        },
      ),
    );
  }
}
