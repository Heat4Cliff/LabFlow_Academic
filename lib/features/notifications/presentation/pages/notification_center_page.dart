import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../data/notification_center_service.dart';
import '../../domain/notification_route_resolver.dart';
import '../cubit/notification_center_cubit.dart';

class NotificationCenterPage extends StatelessWidget {
  const NotificationCenterPage({required this.role, super.key});

  final String role;

  String get _homePath => switch (role) {
    'student' => '/student',
    'lab_admin' => '/lab-admin',
    'superadmin' => '/superadmin',
    _ => '/login',
  };

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        NotificationCenterCubit(NotificationCenterService(role: role))..start(),
    child: _NotificationCenterView(role: role, homePath: _homePath),
  );
}

class _NotificationCenterView extends StatelessWidget {
  const _NotificationCenterView({required this.role, required this.homePath});

  final String role;
  final String homePath;
  static const _paper = Color(0xFFF6F9EF);
  static const _muted = Color(0xFF6B7280);
  static const _resolver = NotificationRouteResolver();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      backgroundColor: _paper,
      title: const Text(
        'Notifikasi',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      leading: IconButton(
        tooltip: 'Kembali',
        onPressed: () =>
            context.canPop() ? context.pop() : context.go(homePath),
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      actions: [
        BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
          buildWhen: (previous, current) =>
              previous.unreadCount != current.unreadCount,
          builder: (context, state) => IconButton(
            tooltip: 'Tandai semua dibaca',
            onPressed: state.unreadCount == 0
                ? null
                : context.read<NotificationCenterCubit>().markAllRead,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
        builder: (context, state) {
          if (state.status == NotificationCenterStatus.initial ||
              state.status == NotificationCenterStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == NotificationCenterStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 38,
                      color: _muted,
                    ),
                    const SizedBox(height: 12),
                    Text(state.errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: context.read<NotificationCenterCubit>().retry,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state.notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 44,
                      color: _muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Pembaruan yang ditujukan kepada akun ini akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: context.read<NotificationCenterCubit>().retry,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: state.notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final notification = state.notifications[index];
                return Material(
                  color: notification.isRead
                      ? Colors.white
                      : const Color(0xFFEAFBCB),
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      if (!notification.isRead) {
                        await context.read<NotificationCenterCubit>().markRead(
                          notification.id,
                        );
                      }
                      if (!context.mounted) return;
                      final target = _resolver.resolve(
                        role: role,
                        payload: {
                          'entityType': notification.entityType,
                          'entityId': notification.entityId,
                          'route': notification.route,
                        },
                      );
                      if (target == '/login') {
                        showLabFlowNotification(
                          context: context,
                          message: 'Tujuan notifikasi tidak tersedia untuk akun ini.',
                          type: LabFlowNotificationType.info,
                        );
                        context.go(homePath);
                        return;
                      }
                      context.push(target);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: Icon(
                              _icon(notification.entityType),
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notification.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (!notification.isRead)
                                      const CircleAvatar(
                                        radius: 4,
                                        backgroundColor: Color(0xFF188A55),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  notification.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _muted,
                                    height: 1.35,
                                  ),
                                ),
                                if (notification.createdAt != null) ...[
                                  const SizedBox(height: 7),
                                  Text(
                                    _formatDate(notification.createdAt!),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _muted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    ),
  );

  IconData _icon(String entityType) => switch (entityType) {
    'borrow_request' => Icons.inventory_2_outlined,
    'report' => Icons.assignment_outlined,
    'admin_activity' => Icons.admin_panel_settings_outlined,
    _ => Icons.notifications_none_rounded,
  };

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day ${months[local.month - 1]} ${local.year} · $hour:$minute';
  }
}
