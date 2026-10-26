import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_notification_service.dart';
import '../student_navigation.dart';
import '../cubit/student_notification_cubit.dart';
import '../cubit/student_notification_state.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentNotificationPage extends StatelessWidget {
  const StudentNotificationPage({this.cubit, super.key});

  final StudentNotificationCubit? cubit;

  @override
  Widget build(BuildContext context) {
    final sharedCubit = cubit;
    if (sharedCubit != null) {
      return BlocProvider.value(
        value: sharedCubit,
        child: const _StudentNotificationView(),
      );
    }

    return BlocProvider(
      create: (_) =>
          StudentNotificationCubit(StudentNotificationService())..start(),
      child: const _StudentNotificationView(),
    );
  }
}

class _StudentNotificationView extends StatelessWidget {
  const _StudentNotificationView();

  @override
  Widget build(BuildContext context) {
    final canReturn = context.canPop();
    return PopScope<Object?>(
      canPop: canReturn,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !canReturn) context.go('/student');
      },
      child: Scaffold(
        backgroundColor: studentPaper,
        bottomNavigationBar: const StudentBottomNavigation(currentIndex: 0),
        body: SafeArea(
          bottom: false,
          child:
              BlocBuilder<StudentNotificationCubit, StudentNotificationState>(
                builder: (context, state) {
                  if (state.status == StudentNotificationStatus.initial ||
                      state.status == StudentNotificationStatus.loading) {
                    return const StudentLoading(message: 'Memuat notifikasi.');
                  }
                  if (state.status == StudentNotificationStatus.failure) {
                    return StudentErrorState(
                      message: state.errorMessage,
                      onRetry: () =>
                          context.read<StudentNotificationCubit>().retry(),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
                    children: [
                      StudentBackHeader(
                        title: 'Notifikasi',
                        onBack: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/student');
                          }
                        },
                        trailing: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.done_all_rounded, size: 19),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.notifications.isEmpty)
                        _empty()
                      else ...[
                        const Text(
                          'HARI INI',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: studentMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...state.notifications.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Material(
                              color: item.read ? Colors.white : studentSoftLime,
                              borderRadius: BorderRadius.circular(18),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(18),
                                onTap: () async {
                                  if (!item.read) {
                                    await context
                                        .read<StudentNotificationCubit>()
                                        .markRead(item.id);
                                  }
                                  final target = studentNotificationTargetPath(
                                    targetType: item.targetType,
                                    targetId: item.targetId,
                                  );
                                  if (!context.mounted || target == null) {
                                    return;
                                  }
                                  context.push(target);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: item.read
                                              ? const Color(0xFFF0F1ED)
                                              : Colors.white.withValues(
                                                  alpha: .55,
                                                ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _icon(item.targetType),
                                          size: 17,
                                          color: studentInk,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                    ),
                                                  ),
                                                ),
                                                if (!item.read)
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF188A55,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.body,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                height: 1.35,
                                                color: studentMuted,
                                              ),
                                            ),
                                            if (item.createdAt != null) ...[
                                              const SizedBox(height: 5),
                                              Text(
                                                studentFormatDateTime(
                                                  item.createdAt!,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 9,
                                                  color: studentMuted,
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Anda sudah melihat semua notifikasi.',
                            style: TextStyle(fontSize: 9, color: studentMuted),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }

  IconData _icon(String targetType) {
    switch (targetType) {
      case 'borrow_request':
        return Icons.check_circle_outline_rounded;
      case 'report':
        return Icons.assignment_turned_in_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none_rounded, size: 38, color: studentMuted),
          SizedBox(height: 10),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
