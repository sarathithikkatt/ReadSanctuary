import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/services/revenuecat_service.dart';

/// Modal dialog for redeeming promotional vouchers or gift keys to unlock Pro features.
class GiftRedeemDialog extends ConsumerStatefulWidget {
  const GiftRedeemDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const GiftRedeemDialog(),
    );
  }

  @override
  ConsumerState<GiftRedeemDialog> createState() => _GiftRedeemDialogState();
}

class _GiftRedeemDialogState extends ConsumerState<GiftRedeemDialog> {
  final TextEditingController _codeCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRedeem() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter a gift code.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success =
        await ref.read(isProUserProvider.notifier).redeemGiftCode(code);

    if (!mounted) return;

    if (success) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.amber,
          content: Text(
            '🎉 Gift Code Accepted! ReadSanctuary Pro is now unlocked for life!',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Invalid or unrecognized gift code. Please check and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Redeem Gift Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Have a promotional gift voucher, reader pass, or community key? Enter your code below to unlock all Pro features for free.',
              style: TextStyle(fontSize: 13.5, color: Colors.grey.shade700, height: 1.4),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Gift or Promo Code',
                hintText: 'e.g. GIFT-READSANCTUARY',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                errorText: _errorMessage,
              ),
              onSubmitted: (_) => _handleRedeem(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildCodeHint('GIFT-READSANCTUARY'),
                _buildCodeHint('BOOKWORM-PRO'),
                _buildCodeHint('READMORE-2026'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade800,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _isSubmitting ? null : _handleRedeem,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Unlock Pro'),
        ),
      ],
    );
  }

  Widget _buildCodeHint(String sampleCode) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        _codeCtrl.text = sampleCode;
        setState(() => _errorMessage = null);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Text(
          sampleCode,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade900,
          ),
        ),
      ),
    );
  }
}
