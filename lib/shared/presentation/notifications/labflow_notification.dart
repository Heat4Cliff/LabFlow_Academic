import 'dart:async';

import 'package:flutter/material.dart';

enum LabFlowNotificationType { success, error, warning, info }

class LabFlowNotification extends StatelessWidget {
  const LabFlowNotification({
    required this.message,
    required this.type,
    required this.onDismiss,
    this.title,
    super.key,
  });

  final String message;
  final String? title;
  final LabFlowNotificationType type;
  final VoidCallback onDismiss;

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

          IconButton(
            key: const ValueKey('labflow-notification-close'),
            tooltip: 'Tutup notifikasi',
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
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

/// Menampilkan satu transient notification di root overlay aplikasi.
void showLabFlowNotification({
  required BuildContext context,
  required String message,
  LabFlowNotificationType type = LabFlowNotificationType.info,
  String? title,
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) {
    return;
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final safeTop = MediaQuery.maybeOf(context)?.viewPadding.top ?? 0;
  final headerOffset = Scaffold.maybeOf(context) == null ? 0.0 : kToolbarHeight;
  _TopNotificationController.show(
    overlay: overlay,
    top: safeTop + headerOffset + 12,
    message: message,
    title: title,
    type: type,
    duration: duration,
  );
}

class _TopNotificationController {
  static OverlayEntry? _entry;
  static Timer? _timer;
  static Timer? _removeTimer;
  static GlobalKey<_TopNotificationCardState>? _cardKey;
  static int _generation = 0;

  static void show({
    required OverlayState overlay,
    required double top,
    required String message,
    required String? title,
    required LabFlowNotificationType type,
    required Duration duration,
  }) {
    _timer?.cancel();
    _removeTimer?.cancel();
    if (_entry?.mounted == true) _entry!.remove();

    final generation = ++_generation;
    final cardKey = GlobalKey<_TopNotificationCardState>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: top,
        left: 16,
        right: 16,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _TopNotificationCard(
              key: cardKey,
              message: message,
              title: title,
              type: type,
              onDismiss: () => dismiss(generation),
            ),
          ),
        ),
      ),
    );
    _entry = entry;
    _cardKey = cardKey;
    overlay.insert(entry);
    _timer = Timer(duration, () => dismiss(generation));
  }

  static void dismiss(int generation) {
    if (generation != _generation || _entry == null) return;
    _timer?.cancel();
    _cardKey?.currentState?.hide();
    _removeTimer?.cancel();
    _removeTimer = Timer(const Duration(milliseconds: 240), () {
      if (generation != _generation) return;
      final entry = _entry;
      if (entry?.mounted == true) entry!.remove();
      _entry = null;
      _cardKey = null;
      _removeTimer = null;
    });
  }
}

class _TopNotificationCard extends StatefulWidget {
  const _TopNotificationCard({
    required this.message,
    required this.title,
    required this.type,
    required this.onDismiss,
    super.key,
  });

  final String message;
  final String? title;
  final LabFlowNotificationType type;
  final VoidCallback onDismiss;

  @override
  State<_TopNotificationCard> createState() => _TopNotificationCardState();
}

class _TopNotificationCardState extends State<_TopNotificationCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void hide() {
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !_visible,
    child: AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, -0.35),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        child: Material(
          type: MaterialType.transparency,
          child: LabFlowNotification(
            message: widget.message,
            title: widget.title,
            type: widget.type,
            onDismiss: widget.onDismiss,
          ),
        ),
      ),
    ),
  );
}
