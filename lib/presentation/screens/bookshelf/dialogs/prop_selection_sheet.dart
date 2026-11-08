import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/shelf_props.dart';
import '../../../../data/local/database.dart';
import '../../../../data/services/revenuecat_service.dart';
import '../../../../data/services/shelf_widget_service.dart';
import '../../settings_backup/dialogs/pro_paywall_sheet.dart';

/// Bottom sheet modal allowing the user to select and place props or spacers onto a shelf,
/// gating premium props with the Pro paywall.
class PropSelectionSheet extends StatelessWidget {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => PropSelectionSheet(
        shelfId: shelfId,
        shelfDao: shelfDao,
        isProUser: isProUser,
      ),
    );
  }

  Future<void> _insertProp(BuildContext context, ShelfPropItem prop) async {
    if (ProFeatureGate.requiresProForProp(prop.id, isProUser)) {
      Navigator.of(context).pop();
      ProPaywallSheet.show(context, 'Decorative Prop "${prop.title}"');
      return;
    }

    Navigator.of(context).pop();
    final existing = await shelfDao.getItemsForShelf(shelfId);
    const uuid = Uuid();

    await shelfDao.insertShelfItem(
      ShelfItemsCompanion.insert(
        id: uuid.v4(),
        shelfId: shelfId,
        itemType: prop.isSpacer ? 'gap' : 'prop',
        propAssetId: drift.Value(prop.id),
        positionIndex: existing.length,
      ),
    );
    ShelfWidgetService(shelfDao: shelfDao).updateWidget();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Add Decorative Prop or Spacer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ),
              ...ShelfPropItem.all.map((prop) => _buildPropTile(context, prop)),
            ],
          ),
        ),
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
        onTap: () => _insertProp(context, prop),
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
            : Icon(prop.fallbackIcon),
      ),
      title: Text(prop.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(prop.subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      trailing: isLocked
          ? const Icon(Icons.lock, size: 16, color: Colors.amber)
          : null,
      onTap: () => _insertProp(context, prop),
    );
  }
}
