import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/connectivity/connectivity_cubit.dart';
import '../../../../core/connectivity/connectivity_state.dart';
import '../../../../shared/presentation/states/labflow_offline_empty_state.dart';
import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import '../../../notifications/data/notification_center_service.dart';
import '../../../notifications/presentation/cubit/notification_center_cubit.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';
import '../cubit/student_data_state.dart';
import '../cubit/student_home_cubit.dart';
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
              NotificationCenterCubit(NotificationCenterService())..start(),
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
              return BlocBuilder<ConnectivityCubit, ConnectivityState>(
                builder: (context, connection) => connection.isOffline
                    ? LabFlowOfflineEmptyState(
                        onRetry: context.read<StudentHomeCubit>().load,
                      )
                    : StudentErrorState(
                        message: state.errorMessage,
                        onRetry: context.read<StudentHomeCubit>().load,
                      ),
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
              ClipOval(
                child: data.profile.profilePhotoUrl?.isNotEmpty == true
                    ? Image.network(
                        data.profile.profilePhotoUrl!,
                        width: 50,
                        height: 50,
                        cacheWidth: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            _studentAvatarFallback(data.profile.initials),
                      )
                    : _studentAvatarFallback(data.profile.initials),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${data.profile.firstName} 👋',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: studentInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Siap menggunakan laboratorium hari ini?',
                      maxLines: 2,
                      style: TextStyle(fontSize: 12, color: studentMuted),
                    ),
                  ],
                ),
              ),
              const NotificationBellButton(role: 'student'),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(22),
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
                          fontSize: 14,
                          color: Color(0xFFD4D8CE),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$activeBorrowing',
                        style: const TextStyle(
                          fontSize: 52,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: studentLime,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$pendingBorrowing Menunggu Persetujuan',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD4D8CE),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: studentLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: studentInk,
                    size: 38,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _quickAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                onTap: () => context.push('/student/scanner'),
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
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aktivitas Terbaru',
                  style: TextStyle(
                    fontSize: 19,
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
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: studentSoftLime,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 22),
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
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              labMap[asset.labId] ?? 'Laboratorium',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
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
              fontSize: 19,
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
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${data.laboratories.first.location} · 08.00–16.00',
                          style: const TextStyle(
                            fontSize: 11,
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

  Widget _studentAvatarFallback(String initials) => Container(
    width: 50,
    height: 50,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: studentSoftLime,
      shape: BoxShape.circle,
      border: Border.all(color: studentInk),
    ),
    child: Text(
      initials,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: studentInk,
      ),
    ),
  );

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
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: studentSoftLime,
                shape: BoxShape.circle,
                border: Border.all(color: studentBorder),
              ),
              child: Icon(icon, size: 24, color: studentInk),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
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
