import 'package:flutter/material.dart';

/// Visual banner showing the user's Pro status or Free status benefits.
class ProStatusBanner extends StatelessWidget {
  final bool isPro;
  final VoidCallback? onTap;

  const ProStatusBanner({
    super.key,
    required this.isPro,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPro
              ? [Colors.amber.shade700, Colors.orange.shade800]
              : [Colors.grey.shade800, Colors.black87],
        ),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  isPro ? Icons.verified : Icons.lock_outline,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'ReadSanctuary Pro Active' : 'ReadSanctuary Free',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        isPro
                            ? 'Automated Google Drive Sync & Premium Cosmetics unlocked'
                            : 'Tap to view Pro features • Local backups remain free',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!isPro)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white70,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
