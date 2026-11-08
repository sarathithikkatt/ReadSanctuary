import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/shelf_themes.dart';
import '../../../../data/local/database.dart';

/// Modal dialog for creating a new custom bookshelf.
class AddShelfDialog extends StatefulWidget {
  final ShelfDao shelfDao;

  const AddShelfDialog({
    super.key,
    required this.shelfDao,
  });

  static Future<void> show(BuildContext context, ShelfDao shelfDao) {
    return showDialog(
      context: context,
      builder: (context) => AddShelfDialog(shelfDao: shelfDao),
    );
  }

  @override
  State<AddShelfDialog> createState() => _AddShelfDialogState();
}

class _AddShelfDialogState extends State<AddShelfDialog> {
  final _nameCtrl = TextEditingController(text: 'Favorites & TBR');
  String _woodTheme = 'oak';
  String _wallTheme = 'warm_cream';
  static const _uuid = Uuid();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createShelf() async {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) {
      final allShelves = await widget.shelfDao.getAllShelves();
      await widget.shelfDao.insertShelf(
        ShelvesCompanion.insert(
          id: _uuid.v4(),
          name: name,
          woodThemeId: drift.Value(_woodTheme),
          wallThemeId: drift.Value(_wallTheme),
          sortOrder: allShelves.length,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Shelf'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Shelf Name',
                hintText: 'e.g. Currently Reading, Sci-Fi Favorites',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _woodTheme,
              decoration: const InputDecoration(labelText: 'Wood Style'),
              items: ShelfWoodTheme.all
                  .map((theme) => DropdownMenuItem(
                        value: theme.id,
                        child: Text(
                            '${theme.name} (${theme.description.split(' ').first})'),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _woodTheme = val);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _wallTheme,
              decoration:
                  const InputDecoration(labelText: 'Wall Background Theme'),
              items: ShelfWallTheme.all
                  .map((theme) => DropdownMenuItem(
                        value: theme.id,
                        child: Text(theme.name),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _wallTheme = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createShelf,
          child: const Text('Create Shelf'),
        ),
      ],
    );
  }
}
