import 'package:flutter/material.dart';

enum LabFlowConfirmationType { logout, delete, destructive }

class LabFlowConfirmationDialog extends StatelessWidget {
  const LabFlowConfirmationDialog({
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.type,
    super.key,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final LabFlowConfirmationType type;

  static const Color _background = Color(0xFFF6F9EF);
  static const Color _dark = Color(0xFF111111);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _danger = Color(0xFFBD3232);
  static const Color _dangerSoft = Color(0xFFFCE8E5);
  static const Color _border = Color(0xFFE2E5DD);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: _dark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              description,
              style: const TextStyle(fontSize: 13, height: 1.45, color: _muted),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _danger,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _dark,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _border),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  cancelLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    final IconData icon;

    switch (type) {
      case LabFlowConfirmationType.logout:
        icon = Icons.logout_rounded;

      case LabFlowConfirmationType.delete:
        icon = Icons.delete_outline_rounded;

      case LabFlowConfirmationType.destructive:
        icon = Icons.warning_amber_rounded;
    }

    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        color: _dangerSoft,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: _danger),
    );
  }
}

/// Dialog dasar.
///
/// Semua confirmation dialog LabFlow memakai function ini
/// agar visual dan behavior tetap konsisten.
Future<bool> showLabFlowConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmLabel,
  required String cancelLabel,
  required LabFlowConfirmationType type,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: const Color(0xE6111111),
    builder: (dialogContext) {
      return LabFlowConfirmationDialog(
        title: title,
        description: description,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        type: type,
      );
    },
  );

  return result ?? false;
}

/// Confirmation khusus Logout.
Future<bool> showLogoutConfirmationDialog({required BuildContext context}) {
  return showLabFlowConfirmationDialog(
    context: context,
    title: 'Keluar dari LabFlow?',
    description:
        'Anda perlu masuk kembali untuk mengakses layanan laboratorium.',
    confirmLabel: 'Keluar',
    cancelLabel: 'Tetap di Sini',
    type: LabFlowConfirmationType.logout,
  );
}

/// Confirmation khusus Delete.
///
/// Bisa digunakan kembali untuk Laboratory,
/// Asset, User, ataupun entitas lain yang memang
/// boleh dihapus permanen.
Future<bool> showDeleteConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  String confirmLabel = 'Ya, Hapus',
}) {
  return showLabFlowConfirmationDialog(
    context: context,
    title: title,
    description: description,
    confirmLabel: confirmLabel,
    cancelLabel: 'Batal',
    type: LabFlowConfirmationType.delete,
  );
}
