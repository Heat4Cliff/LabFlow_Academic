import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/notification_center_cubit.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context) {
    final path = switch (role) {
      'student' => '/student/notifications',
      'lab_admin' => '/lab-admin/notifications',
      'superadmin' => '/superadmin/notifications',
      _ => '/login',
    };
    return BlocBuilder<NotificationCenterCubit, NotificationCenterState>(
      buildWhen: (previous, current) =>
          previous.unreadCount != current.unreadCount,
      builder: (context, state) {
        final count = state.unreadCount;
        final badge = count == 0
            ? null
            : count > 9
            ? '9+'
            : '$count';
        return Semantics(
          button: true,
          label: badge == null
              ? 'Notifikasi'
              : '$badge notifikasi belum dibaca',
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => context.push(path),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Positioned.fill(
                      child: Icon(Icons.notifications_none_rounded, size: 25),
                    ),
                    if (badge != null)
                      Positioned(
                        top: -3,
                        right: -4,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD92D20),
                            borderRadius: BorderRadius.all(
                              Radius.circular(999),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
