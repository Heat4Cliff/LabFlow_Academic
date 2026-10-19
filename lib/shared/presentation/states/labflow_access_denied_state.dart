import 'package:flutter/material.dart';

/// State standar LabFlow ketika pengguna terautentikasi,
/// tetapi tidak memiliki role atau izin untuk mengakses halaman.
///
/// State ini berbeda dengan Suspended Account.
/// Suspended berarti akun dinonaktifkan, sedangkan Access Denied
/// berarti akun aktif tetapi tidak memiliki authorization yang sesuai.
class LabFlowAccessDeniedState extends StatelessWidget {
  const LabFlowAccessDeniedState({
    super.key,
    this.title = 'Akses ditolak',
    this.message = 'Akun Anda tidak memiliki izin untuk mengakses halaman ini.',
    this.actionLabel = 'Kembali',
    this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

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
                color: Color(0xFFFFF0CF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: Color(0xFFA86E00),
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
            if (onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: Text(
                    actionLabel,
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
