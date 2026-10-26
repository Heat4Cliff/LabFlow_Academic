import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_notification_service.dart';
import '../cubit/student_notification_cubit.dart';
import '../cubit/student_notification_state.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentNotificationPage extends StatelessWidget {
  const StudentNotificationPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentNotificationCubit(StudentNotificationService())..start(),
    child: const _StudentNotificationView(),
  );
}

class _StudentNotificationView extends StatelessWidget {
  const _StudentNotificationView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: studentPaper,
    appBar: AppBar(
      title: const Text('Notifikasi'),
      backgroundColor: studentPaper,
    ),
    bottomNavigationBar: const StudentBottomNavigation(currentIndex: 0),
    body: BlocBuilder<StudentNotificationCubit, StudentNotificationState>(
      builder: (context, state) {
        if (state.status == StudentNotificationStatus.initial ||
            state.status == StudentNotificationStatus.loading) {
          return const StudentLoading(message: 'Memuat notifikasi.');
        }
        if (state.status == StudentNotificationStatus.failure) {
          return StudentErrorState(
            message: state.errorMessage,
            onRetry: () => context.read<StudentNotificationCubit>().retry(),
          );
        }
        if (state.notifications.isEmpty) {
          return const Center(
            child: Text(
              'Belum ada notifikasi.',
              style: TextStyle(color: studentMuted),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          itemCount: state.notifications.length,
          itemBuilder: (context, index) {
            final item = state.notifications[index];
            return Card(
              color: item.read ? Colors.white : studentSoftLime,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: studentBorder),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: Icon(
                  item.read
                      ? Icons.notifications_none
                      : Icons.notifications_active_outlined,
                  color: studentInk,
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                subtitle: Text(
                  '${item.body}${item.createdAt == null ? '' : '\n${studentFormatDate(item.createdAt!)}'}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  if (!item.read) {
                    await context.read<StudentNotificationCubit>().markRead(
                      item.id,
                    );
                  }
                  if (!context.mounted) return;
                  if (item.targetId.isEmpty) return;
                  switch (item.targetType) {
                    case 'borrow_request':
                      context.go('/student/borrowing/${item.targetId}');
                    case 'report':
                      context.go('/student/reports/${item.targetId}');
                  }
                },
              ),
            );
          },
        );
      },
    ),
  );
}
