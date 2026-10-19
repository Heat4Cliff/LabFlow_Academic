import 'package:flutter/material.dart';

/// State standar LabFlow ketika akun pengguna berstatus suspended.
///
/// Digunakan setelah identitas pengguna berhasil dikenali,
/// tetapi akses ke aplikasi dinonaktifkan oleh administrator.
class LabFlowSuspendedAccountState extends StatelessWidget {
  const LabFlowSuspendedAccountState({
    super.key,
    this.title = 'Akun dinonaktifkan',
    this.message =
        'Akun Anda sedang dinonaktifkan dan tidak dapat mengakses LabFlow. '
        'Hubungi administrator apabila Anda membutuhkan bantuan.',
    this.actionLabel = 'Keluar',
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
                color: Color(0xFFFFE8E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_off_rounded,
                size: 40,
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
                  icon: const Icon(Icons.logout_rounded, size: 20),
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
