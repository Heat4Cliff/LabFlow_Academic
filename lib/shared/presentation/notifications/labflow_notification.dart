import 'package:flutter/material.dart';

enum LabFlowNotificationType { success, error, warning, info }

class LabFlowNotification extends StatelessWidget {
  const LabFlowNotification({
    required this.message,
    required this.type,
    this.title,
    super.key,
  });

  final String message;
  final String? title;
  final LabFlowNotificationType type;

  static const Color _dark = Color(0xFF111111);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE1E5DC);

  @override
  Widget build(BuildContext context) {
    final configuration = _configuration();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: configuration.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: configuration.iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              configuration.icon,
              size: 20,
              color: configuration.iconColor,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? configuration.defaultTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: _dark,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Builder(
            builder: (buttonContext) {
              return InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () {
                  ScaffoldMessenger.of(buttonContext).hideCurrentSnackBar();
                },
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close_rounded, size: 18, color: _muted),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _NotificationConfiguration _configuration() {
    switch (type) {
      case LabFlowNotificationType.success:
        return const _NotificationConfiguration(
          defaultTitle: 'Berhasil',
          icon: Icons.check_rounded,
          iconColor: Color(0xFF188A55),
          iconBackground: Color(0xFFE5F6EC),
          borderColor: Color(0xFFCDEADB),
        );

      case LabFlowNotificationType.error:
        return const _NotificationConfiguration(
          defaultTitle: 'Gagal',
          icon: Icons.close_rounded,
          iconColor: Color(0xFFC93434),
          iconBackground: Color(0xFFFCE8E8),
          borderColor: Color(0xFFF0CACA),
        );

      case LabFlowNotificationType.warning:
        return const _NotificationConfiguration(
          defaultTitle: 'Perhatian',
          icon: Icons.warning_amber_rounded,
          iconColor: Color(0xFFA86E00),
          iconBackground: Color(0xFFFFF0CF),
          borderColor: Color(0xFFF1D99B),
        );

      case LabFlowNotificationType.info:
        return const _NotificationConfiguration(
          defaultTitle: 'Informasi',
          icon: Icons.info_outline_rounded,
          iconColor: Color(0xFF111111),
          iconBackground: Color(0xFFEAFBCB),
          borderColor: _border,
        );
    }
  }
}

class _NotificationConfiguration {
  const _NotificationConfiguration({
    required this.defaultTitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.borderColor,
  });

  final String defaultTitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color borderColor;
}

/// Menampilkan notifikasi floating LabFlow.
///
/// Tetap menggunakan ScaffoldMessenger agar aman terhadap
/// perpindahan route, tetapi visual SnackBar bawaan Flutter
/// sepenuhnya diganti oleh notification card LabFlow.
void showLabFlowNotification({
  required BuildContext context,
  required String message,
  LabFlowNotificationType type = LabFlowNotificationType.info,
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);

  if (messenger == null) {
    return;
  }

  /// Hindari notification bertumpuk.
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        dismissDirection: DismissDirection.down,
        content: LabFlowNotification(
          message: message,
          title: title,
          type: type,
        ),
      ),
    );
}
