import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import '../cubit/student_data_state.dart';
import '../cubit/student_home_cubit.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentHomeCubit(StudentService())..load(),
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
    final availableAssets = data.assets
        .where((asset) => asset.isAvailable)
        .toList();

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

    final openReports = data.reports
        .where(
          (report) =>
              report.status == 'open' ||
              report.status == 'acknowledged' ||
              report.status == 'in_progress',
        )
        .length;

    final labMap = {
      for (final laboratory in data.laboratories)
        laboratory.id: laboratory.name,
    };

    return RefreshIndicator(
      onRefresh: context.read<StudentHomeCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang,',
                      style: TextStyle(fontSize: 12, color: studentMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.profile.firstName,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: studentInk,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.go('/student/notifications'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 42,
                  height: 42,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: studentInk,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.go('/student/profile'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: studentInk,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    data.profile.initials,
                    style: const TextStyle(
                      color: studentLime,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: studentInk,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: studentLime,
                  size: 30,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Temukan alat laboratorium',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Lihat aset yang tersedia dan buka detail alat sebelum mengajukan peminjaman.',
                  style: TextStyle(
                    color: Color(0xFFC5C9C0),
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => context.go('/student/assets'),
                  icon: const Icon(Icons.arrow_outward_rounded),
                  label: const Text('Buka Katalog'),
                  style: FilledButton.styleFrom(
                    backgroundColor: studentLime,
                    foregroundColor: studentInk,
                    minimumSize: const Size.fromHeight(48),
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Aktivitas Saya',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  'Aktif',
                  activeBorrowing,
                  Icons.swap_horiz_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Menunggu',
                  pendingBorrowing,
                  Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricCard(
                  'Laporan',
                  openReports,
                  Icons.report_problem_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Aset Tersedia',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/student/assets'),
                child: const Text('Lihat semua'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (availableAssets.isEmpty)
            _emptyAssets()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableAssets.length > 4
                  ? 4
                  : availableAssets.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final asset = availableAssets[index];

                return StudentAssetCard(
                  asset: asset,
                  labName: labMap[asset.labId] ?? 'Laboratorium',
                  onTap: () => context.push('/student/assets/${asset.id}'),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _metricCard(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: studentMuted),
          const SizedBox(height: 12),
          Text(
            '$value',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: studentMuted),
          ),
        ],
      ),
    );
  }

  Widget _emptyAssets() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Belum ada aset yang tersedia untuk dipinjam.',
        textAlign: TextAlign.center,
        style: TextStyle(color: studentMuted, fontWeight: FontWeight.w700),
      ),
    );
  }
}
