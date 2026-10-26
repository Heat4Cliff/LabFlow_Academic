import 'package:flutter/material.dart';

/// State standar LabFlow ketika data dari layanan tidak dapat dimuat.
///
/// Digunakan untuk kegagalan pengambilan data dari Firebase/Firestore
/// atau layanan remote lainnya.
///
/// Error validasi form dan business rule tidak menggunakan widget ini.
class LabFlowConnectionErrorState extends StatelessWidget {
  const LabFlowConnectionErrorState({
    super.key,
    this.title = 'Data tidak dapat dimuat',
    this.message = 'LabFlow mengalami kendala saat mengambil data. Periksa koneksi Anda lalu coba lagi.',
    this.retryLabel = 'Coba Lagi',
    this.onRetry,
  });

  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE8E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 38,
                color: Color(0xFFBD3232),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: Text(
                    retryLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
