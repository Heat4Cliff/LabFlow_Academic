import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/maintenance_service.dart';
import '../../domain/maintenance_record.dart';
import '../cubit/maintenance_list_cubit.dart';
import '../cubit/maintenance_list_state.dart';

class MaintenanceListPage extends StatelessWidget {
  const MaintenanceListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MaintenanceListCubit(LabMembershipService(), MaintenanceService())
            ..start(),
      child: const _MaintenanceListView(),
    );
  }
}

class _MaintenanceListView extends StatelessWidget {
  const _MaintenanceListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MaintenanceListCubit, MaintenanceListState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Maintenance',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Tambah maintenance',
                onPressed: state.selectedLabId == null
                    ? null
                    : () {
                        context.push(
                          '/lab-admin/maintenance/create'
                          '?labId=${state.selectedLabId}',
                        );
                      },
                icon: const Icon(Icons.add_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceListState state) {
    if (state.status == MaintenanceListStatus.initial ||
        state.status == MaintenanceListStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat maintenance',
        message: 'Menyiapkan antrean penanganan laboratorium.',
      );
    }

    if (state.status == MaintenanceListStatus.failure) {
      return LabFlowConnectionErrorState(
        title: 'Maintenance tidak dapat dimuat',
        message: state.errorMessage.isEmpty
            ? 'Data maintenance tidak dapat dimuat.'
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
    final records = state.filteredRecords;

    return SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                _laboratorySelector(context, state.laboratories, selectedLab),
                const SizedBox(height: 16),
                TextField(
                  onChanged: context
                      .read<MaintenanceListCubit>()
                      .setSearchQuery,
                  decoration: InputDecoration(
                    hintText: 'Cari aset, kode, atau masalah...',
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
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(context, state, 'pending', 'Menunggu'),
                      const SizedBox(width: 8),
                      _filterChip(context, state, 'in_progress', 'Dikerjakan'),
                      const SizedBox(width: 8),
                      _filterChip(context, state, 'completed', 'Selesai'),
                      const SizedBox(width: 8),
                      _filterChip(context, state, 'all', 'Semua'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          Expanded(
            child: state.recordsLoading
                ? const Center(child: CircularProgressIndicator())
                : records.isEmpty
                ? _emptyState(state.statusFilter)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
                    itemCount: records.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _maintenanceCard(context, records[index]);
                    },
                  ),
          ),
        ],
      ),
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
            child: const Icon(Icons.build_outlined, color: Color(0xFF111111)),
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
              onSelected: context.read<MaintenanceListCubit>().selectLaboratory,
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
    MaintenanceListState state,
    String value,
    String label,
  ) {
    final selected = state.statusFilter == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        context.read<MaintenanceListCubit>().setStatusFilter(value);
      },
      showCheckmark: false,
      selectedColor: const Color(0xFF111111),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFDDE2D5)),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w800,
        color: selected ? const Color(0xFFB9F33D) : const Color(0xFF111111),
      ),
    );
  }

  Widget _maintenanceCard(BuildContext context, MaintenanceRecord record) {
    final palette = _statusPalette(record.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          context.push('/lab-admin/maintenance/${record.id}');
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
                      color: const Color(0xFFFFF0CF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.build_outlined,
                      color: Color(0xFFA86E00),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.assetName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${record.assetCode} · ${_conditionLabel(record.condition)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: palette.background,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(record.status),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: palette.foreground,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                record.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Color(0xFF4F5661),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 16,
                    color: Color(0xFF7A8190),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${record.quantity} unit',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A8190),
                    ),
                  ),
                  const Spacer(),
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
              child: const Icon(Icons.handyman_outlined, size: 30),
            ),
            const SizedBox(height: 18),
            Text(
              filter == 'pending'
                  ? 'Tidak ada maintenance menunggu'
                  : 'Tidak ada data maintenance',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            const Text(
              'Maintenance dari return rusak atau input manual akan muncul di sini.',
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

class _StatusPalette {
  const _StatusPalette(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

_StatusPalette _statusPalette(String status) {
  switch (status) {
    case 'in_progress':
      return const _StatusPalette(Color(0xFFE8EEFF), Color(0xFF3559A6));
    case 'completed':
      return const _StatusPalette(Color(0xFFDFF5E8), Color(0xFF188A55));
    case 'pending':
    default:
      return const _StatusPalette(Color(0xFFFFF0CF), Color(0xFFA86E00));
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'in_progress':
      return 'Dikerjakan';
    case 'completed':
      return 'Selesai';
    case 'pending':
    default:
      return 'Menunggu';
  }
}

String _conditionLabel(String condition) {
  switch (condition) {
    case 'minor_damage':
      return 'Rusak Ringan';
    case 'damaged':
      return 'Rusak';
    default:
      return condition;
  }
}
