import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../../shared/presentation/states/labflow_no_search_results_state.dart';
import '../../domain/activity_log.dart';
import '../../data/activity_log_service.dart';
import '../cubit/activity_log_cubit.dart';
import '../widgets/superadmin_bottom_navigation.dart';

/// Kategori filter Activity Log.
/// Semua data tetap dibaca dari Firestore lalu difilter berdasarkan `type`.
enum _ActivityFilter { all, user, laboratory, borrowing, membership }

class ActivityLogPage extends StatelessWidget {
  const ActivityLogPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ActivityLogCubit(ActivityLogService())..start(),
    child: const _ActivityLogView(),
  );
}

class _ActivityLogView extends StatefulWidget {
  const _ActivityLogView();

  @override
  State<_ActivityLogView> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<_ActivityLogView> {
  _ActivityFilter _selectedFilter = _ActivityFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: _buildHeader(),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Setiap perubahan, tercatat jelas.',
                style: TextStyle(fontSize: 16, color: Color(0xFF7A8190)),
              ),
            ),
            const SizedBox(height: 18),
            _buildFilters(),
            const SizedBox(height: 18),
            Expanded(
              child: BlocBuilder<ActivityLogCubit, ActivityLogState>(
                builder: (context, state) {
                  if (state is ActivityLogLoading) {
                    return const LabFlowLoadingState(
                      title: 'Memuat aktivitas',
                      message: 'Mengambil riwayat aktivitas LabFlow.',
                    );
                  }

                  if (state is ActivityLogFailure) {
                    return const LabFlowConnectionErrorState(
                      title: 'Activity Log tidak dapat dimuat',
                      message:
                          'Riwayat aktivitas tidak dapat diambil saat ini. '
                          'Periksa koneksi Anda lalu coba lagi.',
                    );
                  }

                  final loaded = state as ActivityLogLoaded;
                  final activities = loaded.activities;
                  final filteredActivities = loaded.visibleActivities;

                  if (activities.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filteredActivities.isEmpty) {
                    return _buildNoResultState();
                  }

                  return _buildTimeline(filteredActivities);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SuperadminBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Activity Log',
            style: TextStyle(
              fontSize: 30,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showFilterInformation,
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                Icons.tune_rounded,
                size: 26,
                color: Color(0xFF111111),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFilterChip(label: 'Semua', value: _ActivityFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip(label: 'Pengguna', value: _ActivityFilter.user),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Laboratorium',
            value: _ActivityFilter.laboratory,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Peminjaman',
            value: _ActivityFilter.borrowing,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Membership',
            value: _ActivityFilter.membership,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _ActivityFilter value,
  }) {
    final selected = _selectedFilter == value;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        context.read<ActivityLogCubit>().setFilter(switch (value) {
          _ActivityFilter.all => 'all',
          _ActivityFilter.user => 'user',
          _ActivityFilter.laboratory => 'laboratory',
          _ActivityFilter.borrowing => 'borrowing',
          _ActivityFilter.membership => 'membership',
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF111111) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF111111) : const Color(0xFFDDE2D5),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? const Color(0xFFB9F33D)
                  : const Color(0xFF111111),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(List<ActivityLog> activities) {
    final groups = <DateTime, List<ActivityLog>>{};

    for (final activity in activities) {
      final date = DateTime(
        activity.createdAt.year,
        activity.createdAt.month,
        activity.createdAt.day,
      );
      groups.putIfAbsent(date, () => <ActivityLog>[]);
      groups[date]!.add(activity);
    }

    final dates = groups.keys.toList()
      ..sort((first, second) => second.compareTo(first));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [
        for (final date in dates) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 18, top: 4),
            child: Text(
              _sectionDate(date),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF667080),
                letterSpacing: 0.2,
              ),
            ),
          ),
          for (int index = 0; index < groups[date]!.length; index++)
            _buildTimelineItem(
              groups[date]![index],
              isLast: index == groups[date]!.length - 1,
            ),
          const SizedBox(height: 18),
        ],
      ],
    );
  }

  Widget _buildTimelineItem(ActivityLog activity, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 46,
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9FDC7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _activityIcon(activity.type),
                    size: 24,
                    color: const Color(0xFF111111),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      color: const Color(0xFFD8DECF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _activityMeta(activity),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A8190),
                    ),
                  ),
                  if (activity.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      activity.description,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF7A8190),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _activityMeta(ActivityLog activity) {
    final time =
        '${activity.createdAt.hour.toString().padLeft(2, '0')}:'
        '${activity.createdAt.minute.toString().padLeft(2, '0')}';
    final parts = <String>[time, activity.actorName];

    if (activity.reference != null && activity.reference!.trim().isNotEmpty) {
      parts.add(activity.reference!);
    }

    return parts.join(' · ');
  }

  IconData _activityIcon(String type) {
    switch (type) {
      case 'user':
        return Icons.manage_accounts_outlined;
      case 'laboratory':
        return Icons.science_outlined;
      case 'borrowing':
        return Icons.handshake_outlined;
      case 'membership':
        return Icons.person_add_alt_1_outlined;
      case 'maintenance':
        return Icons.build_outlined;
      default:
        return Icons.history_rounded;
    }
  }

  String _sectionDate(DateTime date) {
    const months = [
      'JANUARI',
      'FEBRUARI',
      'MARET',
      'APRIL',
      'MEI',
      'JUNI',
      'JULI',
      'AGUSTUS',
      'SEPTEMBER',
      'OKTOBER',
      'NOVEMBER',
      'DESEMBER',
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final formatted = '${date.day} ${months[date.month - 1]} ${date.year}';

    if (date == today) {
      return 'HARI INI · $formatted';
    }

    if (date == yesterday) {
      return 'KEMARIN · $formatted';
    }

    return formatted;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: Color(0xFFE9FDC7),
              child: Icon(
                Icons.history_rounded,
                size: 34,
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Belum ada aktivitas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Aktivitas sistem akan muncul setelah perubahan mulai tercatat.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF7A8190),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultState() {
    return LabFlowNoSearchResultsState(
      title: 'Tidak ada aktivitas',
      message: _noResultDescription(),
      icon: Icons.filter_alt_off_outlined,
    );
  }

  String _noResultDescription() {
    switch (_selectedFilter) {
      case _ActivityFilter.user:
        return 'Belum ada aktivitas Manajemen Pengguna yang tercatat.';
      case _ActivityFilter.laboratory:
        return 'Belum ada aktivitas Laboratorium yang tercatat.';
      case _ActivityFilter.borrowing:
        return 'Belum ada aktivitas peminjaman yang tercatat.';
      case _ActivityFilter.membership:
        return 'Belum ada aktivitas Membership yang tercatat.';
      case _ActivityFilter.all:
        return 'Belum ada aktivitas yang tercatat.';
    }
  }

  /// Informasi filter menggunakan floating notification LabFlow.
  void _showFilterInformation() {
    showLabFlowNotification(
      context: context,
      title: 'Filter Activity Log',
      message: 'Gunakan kategori di bawah judul untuk memfilter Activity Log.',
      type: LabFlowNotificationType.info,
    );
  }
}
