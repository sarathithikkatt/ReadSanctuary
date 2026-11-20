import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../providers/library_filter_provider.dart';

/// Mihon-inspired multi-facet Filter & Sort bottom sheet.
class LibraryFilterBottomSheet extends ConsumerWidget {
  const LibraryFilterBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const LibraryFilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(libraryFilterProvider);
    final notifier = ref.read(libraryFilterProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const TabBar(
                indicatorColor: AppColors.primaryBurgundy,
                labelColor: AppColors.primaryBurgundy,
                tabs: [
                  Tab(icon: Icon(Icons.filter_list), text: 'Filter'),
                  Tab(icon: Icon(Icons.sort), text: 'Sort'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: TabBarView(
                  children: [
                    _buildFilterTab(context, filterState, notifier),
                    _buildSortTab(context, filterState, notifier),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    LibraryFilterState state,
    LibraryFilterNotifier notifier,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reading Status',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('All', state.status == null,
                  () => notifier.setStatus(null)),
              _buildChoiceChip('Reading', state.status == 'reading',
                  () => notifier.setStatus('reading')),
              _buildChoiceChip('Finished', state.status == 'finished',
                  () => notifier.setStatus('finished')),
              _buildChoiceChip('TBR', state.status == 'tbr',
                  () => notifier.setStatus('tbr')),
              _buildChoiceChip('DNF', state.status == 'dnf',
                  () => notifier.setStatus('dnf')),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Minimum Rating',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('Any', state.minRating == null,
                  () => notifier.setMinRating(null)),
              _buildChoiceChip(
                '3.0+',
                state.minRating == 3.0,
                () => notifier.setMinRating(3.0),
                avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
              ),
              _buildChoiceChip(
                '4.0+',
                state.minRating == 4.0,
                () => notifier.setMinRating(4.0),
                avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
              ),
              _buildChoiceChip(
                '4.5+',
                state.minRating == 4.5,
                () => notifier.setMinRating(4.5),
                avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortTab(
    BuildContext context,
    LibraryFilterState state,
    LibraryFilterNotifier notifier,
  ) {
    final sortOptions = [
      (LibrarySortField.lastRead, 'Last Read'),
      (LibrarySortField.title, 'Title'),
      (LibrarySortField.author, 'Author'),
      (LibrarySortField.progress, 'Progress %'),
      (LibrarySortField.dateAdded, 'Date Added'),
      (LibrarySortField.rating, 'Rating'),
    ];

    return ListView(
      children: [
        for (final (field, label) in sortOptions)
          ListTile(
            dense: true,
            title: Text(label),
            trailing: state.sortBy == field
                ? Icon(
                    state.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: AppColors.primaryBurgundy,
                  )
                : null,
            selected: state.sortBy == field,
            onTap: () => notifier.setSortBy(field),
          ),
      ],
    );
  }

  Widget _buildChoiceChip(
    String label,
    bool isSelected,
    VoidCallback onSelected, {
    Widget? avatar,
  }) {
    return ChoiceChip(
      avatar: avatar,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppColors.primaryBurgundy.withOpacity(0.18),
      onSelected: (_) => onSelected(),
    );
  }
}
