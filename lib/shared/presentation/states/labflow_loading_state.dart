import 'package:flutter/material.dart';

/// Loading state standar LabFlow.
///
/// Digunakan ketika sebuah halaman sedang menunggu data utama,
/// misalnya data pengguna, laboratorium, membership, atau activity log.
///
/// Loading pada tombol submit tetap menggunakan spinner kecil pada tombol
/// dan tidak perlu menggunakan widget ini.
class LabFlowLoadingState extends StatelessWidget {
  const LabFlowLoadingState({
    super.key,
    this.title = 'Memuat data',
    this.message = 'Mohon tunggu sebentar.',
    this.compact = false,
  });

  final String title;
  final String message;

  /// Mode compact dapat digunakan pada section kecil.
  ///
  /// Untuk loading seluruh halaman gunakan nilai default false.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: Color(0xFF111111),
            ),
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
          vertical: 40,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFEAFBCB),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
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
          ],
        ),
      ),
    );
  }
}