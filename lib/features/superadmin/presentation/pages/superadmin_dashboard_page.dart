import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/user_management_service.dart';
import '../cubit/superadmin_dashboard_cubit.dart';
import '../widgets/superadmin_bottom_navigation.dart';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  @override
  State<SuperadminDashboardPage> createState() =>
      _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SuperadminDashboardCubit(UserManagementService(), LaboratoryService())
            ..start(),
      child: BlocBuilder<SuperadminDashboardCubit, SuperadminDashboardState>(
        builder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          body: SafeArea(
            bottom: false,
            child: switch (state) {
              SuperadminDashboardLoading() => const LabFlowLoadingState(
                title: 'Memuat dashboard',
                message: 'Menyiapkan ringkasan sistem LabFlow.',
              ),
              SuperadminDashboardFailure(:final message) =>
                LabFlowConnectionErrorState(
                  title: 'Dashboard tidak dapat dimuat',
                  message: '$message Periksa koneksi Anda lalu coba lagi.',
                ),
              SuperadminDashboardLoaded(:final users, :final labs) =>
                _buildDashboardContent(users.length, labs),
            },
          ),
          bottomNavigationBar: const SuperadminBottomNavigation(
            currentIndex: 0,
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(int userCount, List<Laboratory> laboratories) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMainStatistics(
            laboratoryCount: laboratories.length,
            userCount: userCount,
          ),
          const SizedBox(height: 18),
          _buildSecondaryStatistics(),
          const SizedBox(height: 26),
          const Text(
            'Kelola ekosistem',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 18),
          _buildManagementActions(),
          const SizedBox(height: 24),
          _buildSyncStatus(laboratoryCount: laboratories.length),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Header utama Dashboard Superadmin.
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Superadmin',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Seluruh laboratorium · ${_formattedDate()}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF7A8190)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              _showInformation(
                title: 'Notifikasi belum tersedia',
                message: 'Notifikasi Superadmin akan tersedia pada tahap berikutnya.',
              );
            },
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Statistik utama.
  ///
  /// Laboratorium dan Users mengambil data secara realtime
  /// dari Cloud Firestore.
  Widget _buildMainStatistics({
    required int laboratoryCount,
    required int userCount,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildLargeStat(
                  label: 'Laboratorium',
                  value: laboratoryCount.toString(),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 28),
              const Expanded(
                child: _LargeStaticStat(label: 'Assets', value: '0'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSmallStat(
                  value: userCount.toString(),
                  label: 'Users',
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: _buildSmallStat(value: '0', label: 'Active Loans'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLargeStat({
    required String label,
    required String value,
    bool highlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFFD7D7D7)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 62,
            height: 1,
            fontWeight: FontWeight.w800,
            color: highlighted ? const Color(0xFFB9F33D) : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStat({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 29,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFFAEB0AC)),
        ),
      ],
    );
  }

  /// Reports dan Maintenance.
  ///
  /// Nilai masih menggunakan placeholder karena domain tersebut
  /// belum masuk ke dashboard Superadmin saat ini.
  Widget _buildSecondaryStatistics() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SecondaryStatCard(
            value: '0',
            label: 'Reports',
            backgroundColor: Color(0xFFFBE4E2),
            valueColor: Color(0xFFC93434),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _SecondaryStatCard(
            value: '0',
            label: 'Maintenance',
            backgroundColor: Color(0xFFFFF0CF),
            valueColor: Color(0xFFA86E00),
          ),
        ),
      ],
    );
  }

  /// Shortcut fitur utama Superadmin.
  Widget _buildManagementActions() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ManagementAction(
            icon: Icons.science_outlined,
            label: 'Kelola\nLaboratorium',
            onTap: () {
              context.go('/superadmin/labs');
            },
          ),
        ),
        Expanded(
          child: _ManagementAction(
            icon: Icons.people_outline_rounded,
            label: 'Kelola\nPengguna',
            onTap: () {
              context.go('/superadmin/users');
            },
          ),
        ),
        Expanded(
          child: _ManagementAction(
            icon: Icons.person_add_alt_outlined,
            label: 'Membership',
            onTap: () {
              context.push('/superadmin/memberships');
            },
          ),
        ),
        Expanded(
          child: _ManagementAction(
            icon: Icons.history_rounded,
            label: 'Activity Log',
            onTap: () {
              context.go('/superadmin/activity');
            },
          ),
        ),
      ],
    );
  }

  /// Indikator sederhana koneksi data laboratorium.
  Widget _buildSyncStatus({required int laboratoryCount}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FBC5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF188A55)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              laboratoryCount > 0
                  ? 'Semua laboratorium tersinkronisasi.'
                  : 'Belum ada laboratorium yang terdaftar.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF111111)),
            ),
          ),
        ],
      ),
    );
  }

  void _showInformation({required String title, required String message}) {
    showLabFlowNotification(
      context: context,
      title: title,
      message: message,
      type: LabFlowNotificationType.info,
    );
  }

  String _formattedDate() {
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

    final now = DateTime.now();

    return '${now.day} '
        '${months[now.month - 1]} '
        '${now.year}';
  }
}

class _LargeStaticStat extends StatelessWidget {
  const _LargeStaticStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFFD7D7D7)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 62,
            height: 1,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Card statistik Reports / Maintenance.
class _SecondaryStatCard extends StatelessWidget {
  const _SecondaryStatCard({
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              height: 1,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagementAction extends StatelessWidget {
  const _ManagementAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE9FDC7),
              ),
              child: Icon(icon, size: 27, color: const Color(0xFF111111)),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
