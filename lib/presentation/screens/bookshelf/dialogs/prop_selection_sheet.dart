import 'dart:io';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/shelf_props.dart';
import '../../../../core/utils/image_storage_helper.dart';
import '../../../../data/local/database.dart';
import '../../../../data/services/custom_props_service.dart';
import '../../../../data/services/revenuecat_service.dart';
import '../../../../data/services/shelf_widget_service.dart';
import '../../settings_backup/dialogs/pro_paywall_sheet.dart';
import 'add_custom_prop_dialog.dart';

/// Bottom sheet modal allowing the user to select and place props or spacers onto a shelf,
/// create custom user props, and manage their custom prop library.
class PropSelectionSheet extends ConsumerWidget {
  final String shelfId;
  final ShelfDao shelfDao;
  final bool isProUser;

  const PropSelectionSheet({
    super.key,
    required this.shelfId,
    required this.shelfDao,
    this.isProUser = false,
  });

  static Future<void> show(
    BuildContext context,
    String shelfId,
    ShelfDao shelfDao, {
    bool isProUser = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PropSelectionSheet(
        shelfId: shelfId,
        shelfDao: shelfDao,
        isProUser: isProUser,
      ),
    );
  }

  Future<void> _insertProp(
    BuildContext context, {
    required String propId,
    bool isSpacer = false,
    String? title,
  }) async {
    if (ProFeatureGate.requiresProForProp(propId, isProUser)) {
      Navigator.of(context).pop();
      ProPaywallSheet.show(context, 'Decorative Prop "${title ?? propId}"');
      return;
    }

    Navigator.of(context).pop();
    final existing = await shelfDao.getItemsForShelf(shelfId);
    const uuid = Uuid();

    await shelfDao.insertShelfItem(
      ShelfItemsCompanion.insert(
        id: uuid.v4(),
        shelfId: shelfId,
        itemType: isSpacer ? 'gap' : 'prop',
        propAssetId: drift.Value(propId),
        positionIndex: existing.length,
      ),
    );
    ShelfWidgetService(shelfDao: shelfDao).updateWidget();
  }

  Future<void> _openAddCustomProp(BuildContext context, WidgetRef ref) async {
    final newProp = await AddCustomPropDialog.show(context);
    if (newProp != null && context.mounted) {
      await _insertProp(
        context,
        propId: 'custom:${newProp.id}',
        title: newProp.name,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customProps = ref.watch(customPropsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.deck_outlined,
                          color: Colors.amber, size: 22),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Shelf Decorations & Props',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ),
                  ],
                ),
              ),

              // Banner: Create Your Own Prop (100% Free)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openAddCustomProp(context, ref),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade50,
                            Colors.orange.shade50,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.amber.shade300, width: 1.2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.add_photo_alternate,
                                color: Colors.amber, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Create Custom Prop',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'FREE',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Upload any photo, figurine, or transparent PNG from your device',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              size: 14, color: Colors.amber),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Section: User's Custom Props
              if (customProps.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Text(
                    'My Custom Props',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...customProps.map((prop) => _buildCustomPropTile(context, ref, prop)),
              ],

              // Section: Built-in Catalog
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Text(
                  'Decor Catalog & Spacers',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Colors.grey,
                  ),
                ),
              ),
              ...ShelfPropItem.all.map((prop) => _buildPropTile(context, prop)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPropTile(
    BuildContext context,
    WidgetRef ref,
    CustomPropItem prop,
  ) {
    final absPath = ImageStorageHelper.resolvePathSync(prop.relativeImagePath);
    final file = absPath != null ? File(absPath) : null;

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.withOpacity(0.25)),
        ),
        child: file != null && file.existsSync()
            ? Image.file(
                file,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.palette, color: Colors.amber),
              )
            : const Icon(Icons.palette, color: Colors.amber),
      ),
      title: Text(
        prop.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        'Custom Prop • ${prop.height.toInt()}dp',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
        tooltip: 'Delete custom prop',
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Custom Prop?'),
              content: Text('Remove "${prop.name}" from your custom props list?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await ref.read(customPropsProvider.notifier).deleteProp(prop.id);
          }
        },
      ),
      onTap: () => _insertProp(
        context,
        propId: 'custom:${prop.id}',
        title: prop.name,
      ),
    );
  }

  Widget _buildPropTile(BuildContext context, ShelfPropItem prop) {
    final isLocked = ProFeatureGate.requiresProForProp(prop.id, isProUser);

    if (prop.isSpacer) {
      return ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blueGrey.shade200),
          ),
          child: Icon(prop.fallbackIcon, color: Colors.blueGrey),
        ),
        title: Text(prop.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(prop.subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        trailing: isLocked
            ? const Icon(Icons.lock, size: 16, color: Colors.amber)
            : null,
        onTap: () => _insertProp(
          context,
          propId: prop.id,
          isSpacer: true,
          title: prop.title,
        ),
      );
    }

    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: prop.assetPath != null
            ? Image.asset(
                prop.assetPath!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(prop.fallbackIcon),
              )
            : Icon(prop.fallbackIcon, color: Colors.amber.shade900),
      ),
      title: Text(prop.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(prop.subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: isLocked
          ? const Icon(Icons.lock, size: 16, color: Colors.amber)
          : null,
      onTap: () => _insertProp(
        context,
        propId: prop.id,
        isSpacer: false,
        title: prop.title,
      ),
    );
  }
}
