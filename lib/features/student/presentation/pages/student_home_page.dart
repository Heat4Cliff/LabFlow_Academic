import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../data/student_notification_service.dart';
import '../../domain/student_models.dart';
import '../cubit/student_notification_cubit.dart';
import '../cubit/student_notification_state.dart';
import '../cubit/student_data_state.dart';
import '../cubit/student_home_cubit.dart';
import '../student_navigation.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StudentHomeCubit(StudentService())..load()),
        BlocProvider(
          create: (_) =>
              StudentNotificationCubit(StudentNotificationService())..start(),
        ),
      ],
      child: const _StudentHomeView(),
    );
  }
}

class _StudentHomeView extends StatelessWidget {
  const _StudentHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      bottomNavigationBar: const StudentBottomNavigation(currentIndex: 0),
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<StudentHomeCubit, StudentDataState<StudentHomeData>>(
          builder: (context, state) {
            if (state.status == StudentLoadStatus.initial ||
                state.status == StudentLoadStatus.loading) {
              return const StudentLoading(
                message: 'Menyiapkan layanan laboratorium untuk Anda.',
              );
            }

            if (state.status == StudentLoadStatus.failure ||
                state.data == null) {
              return StudentErrorState(
                message: state.errorMessage,
                onRetry: context.read<StudentHomeCubit>().load,
              );
            }

            return _content(context, state.data!);
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, StudentHomeData data) {
    final activeBorrowing = data.borrowRequests
        .where((request) => request.status == 'active')
        .length;
    final pendingBorrowing = data.borrowRequests
        .where(
          (request) =>
              request.status == 'pending' ||
              request.status == 'approved' ||
              request.status == 'waiting_pickup',
        )
        .length;
    final labMap = {
      for (final laboratory in data.laboratories)
        laboratory.id: laboratory.name,
    };
    final recentAssets = data.assets.take(2).toList(growable: false);

    return RefreshIndicator(
      onRefresh: context.read<StudentHomeCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: studentSoftLime,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: studentInk),
                ),
                alignment: Alignment.center,
                child: Text(
                  data.profile.initials,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: studentInk,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${data.profile.firstName} 👋',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: studentInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Siap menggunakan laboratorium hari ini?',
                      style: TextStyle(fontSize: 11, color: studentMuted),
                    ),
                  ],
                ),
              ),
              BlocBuilder<StudentNotificationCubit, StudentNotificationState>(
                buildWhen: (previous, current) =>
                    previous.unreadCount != current.unreadCount,
                builder: (context, notificationState) {
                  final badge = studentNotificationBadgeLabel(
                    notificationState.unreadCount,
                  );
                  return InkWell(
                    onTap: () => context.push(
                      '/student/notifications',
                      extra: context.read<StudentNotificationCubit>(),
                    ),
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.notifications_none_rounded),
                            ),
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
                                  shape: BoxShape.rectangle,
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
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: studentInk,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pinjaman Aktif',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD4D8CE),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$activeBorrowing',
                        style: const TextStyle(
                          fontSize: 44,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: studentLime,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pendingBorrowing Menunggu Persetujuan',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFD4D8CE),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: studentLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: studentInk,
                    size: 34,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                onTap: () => context.go('/student/assets'),
              ),
              _quickAction(
                icon: Icons.search_rounded,
                label: 'Cari Peralatan',
                onTap: () => context.go('/student/assets'),
              ),
              _quickAction(
                icon: Icons.handshake_outlined,
                label: 'Pinjaman Saya',
                onTap: () => context.go('/student/borrowing'),
              ),
              _quickAction(
                icon: Icons.assignment_outlined,
                label: 'Buat Laporan',
                onTap: () => context.push('/student/reports/create'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: studentInk,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/student/borrowing'),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          if (recentAssets.isEmpty)
            _emptyActivity()
          else
            ...recentAssets.map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: studentSoftLime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 19),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              labMap[asset.labId] ?? 'Laboratorium',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                color: studentMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StudentStatusPill(
                        status: asset.isAvailable ? 'available' : asset.status,
                        small: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          const Text(
            'Informasi Laboratorium',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: studentInk,
            ),
          ),
          const SizedBox(height: 9),
          if (data.laboratories.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: studentSoftLime,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.laboratories.first.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${data.laboratories.first.location} · 08.00–16.00',
                          style: const TextStyle(
                            fontSize: 9,
                            color: studentMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_outward_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: studentSoftLime,
                shape: BoxShape.circle,
                border: Border.all(color: studentBorder),
              ),
              child: Icon(icon, size: 19, color: studentInk),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 8,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyActivity() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'Belum ada aktivitas terbaru.',
        style: TextStyle(color: studentMuted),
      ),
    );
  }
}
