import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/local/database.dart';
import 'dialogs/add_shelf_dialog.dart';

/// Screen allowing users to create, rename, delete, and drag-and-drop reorder custom shelves (categories).
class ManageShelvesScreen extends ConsumerWidget {
  const ManageShelvesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shelfDao = ref.watch(shelfDaoProvider);
    final shelvesStream = shelfDao.watchAllShelves();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Shelves & Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Shelf',
            onPressed: () => AddShelfDialog.show(context, shelfDao),
          ),
        ],
      ),
      body: StreamBuilder<List<Shelf>>(
        stream: shelvesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final shelves = snapshot.data ?? [];
          if (shelves.isEmpty) {
            return Center(
              child: Text(
                'No shelves yet. Tap + to create one.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          return ReorderableListView.builder(
            itemCount: shelves.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final item = shelves.removeAt(oldIndex);
              shelves.insert(newIndex, item);
              final idsInOrder = shelves.map((s) => s.id).toList();
              await shelfDao.reorderShelves(idsInOrder);
            },
            itemBuilder: (context, index) {
              final shelf = shelves[index];
              return ListTile(
                key: ValueKey(shelf.id),
                leading: const Icon(Icons.drag_handle, color: Colors.grey),
                title: Text(shelf.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Theme: ${shelf.woodThemeId} wood'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _showRenameDialog(context, shelfDao, shelf),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context, shelfDao, shelf),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, ShelfDao shelfDao, Shelf shelf) {
    final controller = TextEditingController(text: shelf.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Shelf'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Shelf Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBurgundy),
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await shelfDao.updateShelf(shelf.copyWith(name: newName));
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ShelfDao shelfDao, Shelf shelf) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${shelf.name}"?'),
        content: const Text(
            'Books on this shelf will remain in your library but will be removed from this shelf view.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await shelfDao.deleteShelf(shelf.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
