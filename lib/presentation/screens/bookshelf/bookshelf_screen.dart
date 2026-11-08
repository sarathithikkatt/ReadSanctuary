import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/local/database.dart';
import '../../../data/services/shelf_widget_service.dart';
import '../book_search/book_search_screen.dart';
import 'dialogs/add_book_dialog.dart';
import 'dialogs/add_shelf_dialog.dart';
import 'shelf_share_exporter.dart';
import 'widgets/shelf_empty_state.dart';
import 'widgets/shelf_section.dart';

/// Main visual bookshelf screen rendering 2.5D wooden shelves, reactive database updates,
/// book spines, tilted covers, background textures, and decorative props.
class BookshelfScreen extends ConsumerStatefulWidget {
  const BookshelfScreen({super.key});

  @override
  ConsumerState<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends ConsumerState<BookshelfScreen> {
  final GlobalKey _shelfExportKey = GlobalKey();
  bool _isReorderMode = false;
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
  Widget build(BuildContext context) {
    final shelfDao = ref.watch(shelfDaoProvider);
    final bookDao = ref.watch(bookDaoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReadSanctuary',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search & Free Books',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BookSearchScreen()),
            ),
          ),
          IconButton(
            icon: Icon(_isReorderMode ? Icons.done : Icons.swap_horiz),
            tooltip: _isReorderMode ? 'Done Reordering' : 'Reorder Books',
            onPressed: () => setState(() => _isReorderMode = !_isReorderMode),
          ),
          IconButton(
            icon: const Icon(Icons.add_to_photos_outlined),
            tooltip: 'Add Shelf',
            onPressed: () => AddShelfDialog.show(context, shelfDao),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Bookshelf',
            onPressed: () => ShelfShareExporter.exportAndShare(
              repaintBoundaryKey: _shelfExportKey,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        onPressed: () => AddBookDialog.show(context, shelfDao, bookDao),
      ),
      body: RepaintBoundary(
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
      ),
    );
  }
}
