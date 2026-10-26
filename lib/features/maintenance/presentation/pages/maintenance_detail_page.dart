import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/maintenance_service.dart';
import '../../domain/maintenance_record.dart';
import '../cubit/maintenance_detail_cubit.dart';
import '../cubit/maintenance_detail_state.dart';

class MaintenanceDetailPage extends StatelessWidget {
  const MaintenanceDetailPage({required this.maintenanceId, super.key});

  final String maintenanceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MaintenanceDetailCubit(MaintenanceService())..load(maintenanceId),
      child: const _MaintenanceDetailView(),
    );
  }
}

class _MaintenanceDetailView extends StatelessWidget {
  const _MaintenanceDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MaintenanceDetailCubit, MaintenanceDetailState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != MaintenanceDetailActionStatus.idle,
      listener: (context, state) {
        final type = switch (state.actionStatus) {
          MaintenanceDetailActionStatus.success =>
            LabFlowNotificationType.success,
          MaintenanceDetailActionStatus.warning =>
            LabFlowNotificationType.warning,
          MaintenanceDetailActionStatus.failure =>
            LabFlowNotificationType.error,
          MaintenanceDetailActionStatus.idle => LabFlowNotificationType.info,
        };

        showLabFlowNotification(
          context: context,
          title: state.actionStatus == MaintenanceDetailActionStatus.success
              ? 'Proses berhasil'
              : state.actionStatus == MaintenanceDetailActionStatus.warning
              ? 'Maintenance belum dapat diproses'
              : 'Maintenance gagal',
          message: state.actionMessage,
          type: type,
        );

        context.read<MaintenanceDetailCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Detail Maintenance',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, MaintenanceDetailState state) {
    if (state.status == MaintenanceDetailStatus.initial ||
        state.status == MaintenanceDetailStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat maintenance',
        message: 'Menyiapkan detail penanganan aset.',
      );
    }

    if (state.status == MaintenanceDetailStatus.failure ||
        state.record == null) {
      return LabFlowConnectionErrorState(
        title: 'Detail maintenance tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data maintenance tidak dapat dimuat.'
            : state.errorMessage,
      );
    }

    final record = state.record!;
    final palette = _statusPalette(record.status);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(record.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: palette.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _assetCard(record),
            const SizedBox(height: 14),
            _informationCard(
              icon: Icons.report_problem_outlined,
              label: 'Masalah',
              value: record.description,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _smallCard(
                    label: 'Kondisi',
                    value: _conditionLabel(record.condition),
                    icon: Icons.health_and_safety_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _smallCard(
                    label: 'Jumlah',
                    value: '${record.quantity} unit',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _informationCard(
              icon: Icons.link_rounded,
              label: 'Sumber',
              value: _sourceLabel(record.sourceType),
            ),
            if (record.isCompleted) ...[
              const SizedBox(height: 12),
              _informationCard(
                icon: Icons.task_alt_rounded,
                label: 'Hasil Akhir',
                value: _resolutionLabel(record.resolution),
              ),
              if ((record.resolutionNote ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                _informationCard(
                  icon: Icons.notes_rounded,
                  label: 'Catatan Penyelesaian',
                  value: record.resolutionNote!,
                ),
              ],
            ],
            const SizedBox(height: 22),
            _actionArea(context, state, record),
          ],
        ),
      ),
    );
  }

  Widget _actionArea(
    BuildContext context,
    MaintenanceDetailState state,
    MaintenanceRecord record,
  ) {
    if (record.isPending) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: state.isProcessing
              ? null
              : context.read<MaintenanceDetailCubit>().startMaintenance,
          icon: state.isProcessing
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.play_arrow_rounded),
          label: const Text(
            'Mulai Penanganan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
        ),
      );
    }

    if (record.isInProgress) {
      return SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: state.isProcessing
              ? null
              : () async {
                  final result =
                      await showModalBottomSheet<_MaintenanceResolutionInput>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const _MaintenanceResolutionSheet(),
                      );

                  if (result == null || !context.mounted) {
                    return;
                  }

                  await context
                      .read<MaintenanceDetailCubit>()
                      .completeMaintenance(
                        resolution: result.resolution,
                        note: result.note,
                      );
                },
          icon: state.isProcessing
              ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.task_alt_rounded),
          label: const Text(
            'Selesaikan Maintenance',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF111111),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBCB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline_rounded),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Maintenance telah selesai dan tersimpan sebagai histori.',
              style: TextStyle(height: 1.4, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetCard(MaintenanceRecord record) {
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
            width: 52,
            height: 52,
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
                  'Aset maintenance',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 4),
                Text(
                  record.assetName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  record.assetCode,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8BCB3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF7A8190)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _informationCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6B7280)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8190),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceResolutionInput {
  const _MaintenanceResolutionInput({
    required this.resolution,
    required this.note,
  });

  final MaintenanceResolution resolution;
  final String note;
}

class _MaintenanceResolutionSheet extends StatefulWidget {
  const _MaintenanceResolutionSheet();

  @override
  State<_MaintenanceResolutionSheet> createState() =>
      _MaintenanceResolutionSheetState();
}

class _MaintenanceResolutionSheetState
    extends State<_MaintenanceResolutionSheet> {
  final TextEditingController _noteController = TextEditingController();

  MaintenanceResolution _resolution = MaintenanceResolution.repaired;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F9EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hasil Maintenance',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MaintenanceResolution.values
                    .map((resolution) {
                      return ChoiceChip(
                        label: Text(resolution.label),
                        selected: _resolution == resolution,
                        onSelected: (_) {
                          setState(() {
                            _resolution = resolution;
                          });
                        },
                        selectedColor: const Color(0xFFB9F33D),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                        side: const BorderSide(color: Color(0xFFDDE2D5)),
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Catatan penyelesaian',
                  hintText: 'Contoh: konektor diganti dan fungsi sudah diuji.',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _MaintenanceResolutionInput(
                        resolution: _resolution,
                        note: _noteController.text.trim(),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Konfirmasi Penyelesaian',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
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
      return 'Sedang Dikerjakan';
    case 'completed':
      return 'Selesai';
    case 'pending':
    default:
      return 'Menunggu Penanganan';
  }
}

String _conditionLabel(String value) {
  switch (value) {
    case 'minor_damage':
      return 'Rusak Ringan';
    case 'damaged':
      return 'Rusak';
    default:
      return value;
  }
}

String _sourceLabel(String value) {
  switch (value) {
    case 'return':
      return 'Hasil pemeriksaan pengembalian';
    case 'report':
      return 'Laporan masalah';
    case 'manual':
    default:
      return 'Dibuat manual oleh Lab Admin';
  }
}

String _resolutionLabel(String? value) {
  switch (value) {
    case 'repaired':
      return 'Berhasil Diperbaiki';
    case 'unrepairable':
      return 'Tidak Dapat Diperbaiki';
    default:
      return '-';
  }
}
