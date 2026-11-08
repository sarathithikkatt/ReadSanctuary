import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/services/revenuecat_service.dart';
import 'gift_redeem_dialog.dart';

/// Modal bottom sheet displaying the Pro upgrade paywall with gift redemption option.
class ProPaywallSheet extends ConsumerWidget {
  final String featureName;

  const ProPaywallSheet({
    super.key,
    required this.featureName,
  });

  static void show(BuildContext context, String featureName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (_) => ProPaywallSheet(featureName: featureName),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messenger = ScaffoldMessenger.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.star, size: 48, color: Colors.amber),
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock ShelfCraft Pro',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '$featureName is a Pro feature.\nSupport independent local-first software with a fair, low one-time lifetime unlock or annual pass.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13.5),
          ),
          const SizedBox(height: 20),

          // Feature list preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFeatureRow(Icons.cloud_sync_outlined, 'Automated Google Drive Cloud Backup'),
                const SizedBox(height: 8),
                _buildFeatureRow(Icons.palette_outlined, 'Unlimited Wall Themes & Artisan Shelves'),
                const SizedBox(height: 8),
                _buildFeatureRow(Icons.eco_outlined, 'Complete Decorative Prop & Decor Catalog'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade800,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await ref.read(isProUserProvider.notifier).setDebugProOverride(
                    true,
                    source: 'lifetime_purchase',
                  );
              if (context.mounted) Navigator.of(context).pop();
              messenger.showSnackBar(
                const SnackBar(content: Text('Pro unlocked! Thank you for supporting ShelfCraft! 🌟')),
              );
            },
            child: const Text(
              r'Unlock Lifetime Pro ($9.99)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),

          // Gift Redemption Option
          OutlinedButton.icon(
            icon: const Icon(Icons.card_giftcard, size: 18, color: Colors.amber),
            label: const Text('Have a Gift Code? Redeem Here'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: Colors.amber.shade900,
              side: BorderSide(color: Colors.amber.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await GiftRedeemDialog.show(context);
            },
          ),
          const SizedBox(height: 8),

          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Maybe Later'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.amber.shade800),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        const Icon(Icons.check, size: 16, color: Colors.green),
      ],
    );
  }
}
