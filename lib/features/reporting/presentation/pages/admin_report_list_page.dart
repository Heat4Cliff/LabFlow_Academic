import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../lab_admin/presentation/widgets/lab_admin_bottom_navigation.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/report_service.dart';
import '../../domain/lab_report.dart';
import '../cubit/report_list_cubit.dart';
import '../cubit/report_list_state.dart';

class AdminReportListPage extends StatelessWidget {
  const AdminReportListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReportListCubit(LabMembershipService(), ReportService())..start(),
      child: const _AdminReportListView(),
    );
  }
}

class _AdminReportListView extends StatelessWidget {
  const _AdminReportListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReportListCubit, ReportListState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          bottomNavigationBar: const LabAdminBottomNavigation(currentIndex: 3),
          body: SafeArea(bottom: false, child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ReportListState state) {
    if (state.status == ReportListStatus.initial ||
        state.status == ReportListStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat laporan',
        message: 'Menyiapkan laporan untuk laboratorium Anda.',
      );
    }

    if (state.status == ReportListStatus.failure) {
      return LabFlowConnectionErrorState(
        title: 'Laporan tidak dapat dimuat',
        message: state.errorMessage.isEmpty
            ? 'Daftar laporan tidak dapat dimuat.'
            : state.errorMessage,
      );
    }

    if (state.laboratories.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Akun Lab Admin belum memiliki laboratorium aktif.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final selectedLab = state.selectedLaboratory!;
    final reports = state.filteredReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Text(
            'Laporan',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111111),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _laboratorySelector(context, state.laboratories, selectedLab),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            onChanged: context.read<ReportListCubit>().setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Cari nomor, judul, lokasi, atau pelapor...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFFDDE2D5)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(context, state, 'open', 'Menunggu'),
                const SizedBox(width: 8),
                _filterChip(context, state, 'handling', 'Ditangani'),
                const SizedBox(width: 8),
                _filterChip(context, state, 'done', 'Selesai'),
                const SizedBox(width: 8),
                _filterChip(context, state, 'rejected', 'Ditolak'),
                const SizedBox(width: 8),
                _filterChip(context, state, 'all', 'Semua'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: state.reportsLoading
              ? const Center(child: CircularProgressIndicator())
              : reports.isEmpty
              ? _emptyState(state.statusFilter)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                  itemCount: reports.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _reportCard(context, reports[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _laboratorySelector(
    BuildContext context,
    List<Laboratory> laboratories,
    Laboratory selected,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFB9F33D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.report_problem_outlined,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laboratorium aktif',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 3),
                Text(
                  selected.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${selected.code} · ${selected.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB8BCB3),
                  ),
                ),
              ],
            ),
          ),
          if (laboratories.length > 1)
            PopupMenuButton<String>(
              iconColor: Colors.white,
              onSelected: context.read<ReportListCubit>().selectLaboratory,
              itemBuilder: (_) => laboratories
                  .map(
                    (lab) => PopupMenuItem<String>(
                      value: lab.id,
                      child: Text('${lab.code} — ${lab.name}'),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }

  Widget _filterChip(
    BuildContext context,
    ReportListState state,
    String value,
    String label,
  ) {
    final selected = state.statusFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      selectedColor: const Color(0xFF111111),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDDE2D5)),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? const Color(0xFFB9F33D) : const Color(0xFF111111),
      ),
      onSelected: (_) {
        context.read<ReportListCubit>().setStatusFilter(value);
      },
    );
  }

  Widget _reportCard(BuildContext context, LabReport report) {
    final statusPalette = _statusPalette(report.status);
    final priorityPalette = _priorityPalette(report.priority);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          context.push('/lab-admin/reports/${report.id}');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE2D5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBCB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon(report.category)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.reportNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8190),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          report.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusPalette.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(report.status),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: statusPalette.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: priorityPalette.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _priorityLabel(report.priority),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: priorityPalette.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.place_outlined,
                    size: 15,
                    color: Color(0xFF7A8190),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A8190),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF7A8190),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String filter) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFEAFBCB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              filter == 'open'
                  ? 'Tidak ada laporan menunggu'
                  : 'Tidak ada laporan pada filter ini',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Laporan mahasiswa untuk laboratorium ini akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF7A8190),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Palette {
  const _Palette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

_Palette _statusPalette(String status) {
  switch (status) {
    case 'acknowledged':
      return const _Palette(Color(0xFFE8EEFF), Color(0xFF3559A6));
    case 'in_progress':
      return const _Palette(Color(0xFFFFF0CF), Color(0xFFA86E00));
    case 'resolved':
    case 'closed':
      return const _Palette(Color(0xFFDFF5E8), Color(0xFF188A55));
    case 'rejected':
      return const _Palette(Color(0xFFFFE2E2), Color(0xFFB42318));
    case 'open':
    default:
      return const _Palette(Color(0xFFF0F2EC), Color(0xFF535A50));
  }
}

_Palette _priorityPalette(String priority) {
  switch (priority) {
    case 'critical':
      return const _Palette(Color(0xFFFFE2E2), Color(0xFFB42318));
    case 'high':
      return const _Palette(Color(0xFFFFF0CF), Color(0xFFA86E00));
    case 'low':
      return const _Palette(Color(0xFFE8EEFF), Color(0xFF3559A6));
    case 'medium':
    default:
      return const _Palette(Color(0xFFF0F2EC), Color(0xFF535A50));
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'acknowledged':
      return 'Diterima';
    case 'in_progress':
      return 'Ditangani';
    case 'resolved':
      return 'Resolved';
    case 'closed':
      return 'Selesai';
    case 'rejected':
      return 'Ditolak';
    case 'open':
    default:
      return 'Menunggu';
  }
}

String _priorityLabel(String priority) {
  switch (priority) {
    case 'critical':
      return 'Critical';
    case 'high':
      return 'High';
    case 'low':
      return 'Low';
    case 'medium':
    default:
      return 'Medium';
  }
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'network':
      return Icons.wifi_off_rounded;
    case 'computer':
      return Icons.computer_rounded;
    case 'software':
      return Icons.code_rounded;
    case 'facility':
      return Icons.chair_alt_outlined;
    case 'electricity':
      return Icons.electric_bolt_outlined;
    case 'asset_lost':
      return Icons.search_off_rounded;
    case 'asset_damage':
      return Icons.broken_image_outlined;
    default:
      return Icons.report_problem_outlined;
  }
}
