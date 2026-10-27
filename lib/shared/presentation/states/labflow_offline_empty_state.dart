import 'package:flutter/material.dart';

class LabFlowOfflineEmptyState extends StatelessWidget {
  const LabFlowOfflineEmptyState({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 14),
          const Text(
            'Belum ada data offline',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data ini belum pernah dimuat pada perangkat. Hubungkan ke internet lalu buka halaman ini sekali.',
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba Lagi')),
          ],
        ],
      ),
    ),
  );
}
