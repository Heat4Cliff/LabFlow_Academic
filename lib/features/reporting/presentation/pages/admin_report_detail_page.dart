import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/report_service.dart';
import '../../domain/lab_report.dart';
import '../cubit/report_detail_cubit.dart';
import '../cubit/report_detail_state.dart';
import '../widgets/report_conversation_panel.dart';

class AdminReportDetailPage extends StatelessWidget {
  const AdminReportDetailPage({required this.reportId, super.key});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportDetailCubit(ReportService())..load(reportId),
      child: const _AdminReportDetailView(),
    );
  }
}

class _AdminReportDetailView extends StatelessWidget {
  const _AdminReportDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReportDetailCubit, ReportDetailState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != ReportDetailActionStatus.idle,
      listener: (context, state) {
        final type = switch (state.actionStatus) {
          ReportDetailActionStatus.success => LabFlowNotificationType.success,
          ReportDetailActionStatus.warning => LabFlowNotificationType.warning,
          ReportDetailActionStatus.failure => LabFlowNotificationType.error,
          ReportDetailActionStatus.idle => LabFlowNotificationType.info,
        };

        showLabFlowNotification(
          context: context,
          title: state.actionStatus == ReportDetailActionStatus.success
              ? 'Proses berhasil'
              : state.actionStatus == ReportDetailActionStatus.warning
              ? 'Laporan belum dapat diproses'
              : 'Proses laporan gagal',
          message: state.actionMessage,
          type: type,
        );

        context.read<ReportDetailCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Detail Laporan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ReportDetailState state) {
    if (state.status == ReportDetailStatus.initial ||
        state.status == ReportDetailStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat laporan',
        message: 'Menyiapkan detail dan status laporan.',
      );
    }

    if (state.status == ReportDetailStatus.failure || state.report == null) {
      return LabFlowConnectionErrorState(
        title: 'Detail laporan tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data laporan tidak dapat dimuat.'
            : state.errorMessage,
      );
    }

    final report = state.report!;
    final statusPalette = _statusPalette(report.status);

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
                  color: statusPalette.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(report.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: statusPalette.foreground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _hero(report),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _smallCard(
                    label: 'Priority',
                    value: _priorityLabel(report.priority),
                    icon: Icons.flag_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _smallCard(
                    label: 'Severity',
                    value: report.severity == 'urgent' ? 'Urgent' : 'Normal',
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _informationCard(
              icon: Icons.place_outlined,
              label: 'Lokasi',
              value: report.location,
            ),
            const SizedBox(height: 12),
            _informationCard(
              icon: Icons.description_outlined,
              label: 'Deskripsi',
              value: report.description,
            ),
            const SizedBox(height: 12),
            _informationCard(
              icon: Icons.person_outline_rounded,
              label: 'Pelapor',
              value: report.reporterId,
            ),
            if (report.assetId != null) ...[
              const SizedBox(height: 12),
              _informationCard(
                icon: Icons.inventory_2_outlined,
                label: 'Asset ID',
                value: report.assetId!,
              ),
            ],
            if (report.adminResponse != null) ...[
              const SizedBox(height: 12),
              _informationCard(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Tanggapan Lab Admin',
                value: report.adminResponse!,
              ),
            ],
            const SizedBox(height: 18),
            _timeline(report),
            const SizedBox(height: 22),
            if (!report.isResolved && !report.isRejected && !report.isClosed)
              _priorityControl(context, state, report),
            if (!report.isResolved && !report.isRejected && !report.isClosed)
              const SizedBox(height: 16),
            if (report.isAssetRelated &&
                (report.isAcknowledged || report.isInProgress)) ...[
              _maintenanceButton(context, report),
              const SizedBox(height: 12),
            ],
            ReportConversationPanel(reportId: report.id),
            const SizedBox(height: 16),
            _actionArea(context, state, report),
          ],
        ),
      ),
    );
  }

  Widget _hero(LabReport report) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
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
                Text(
                  report.reportNumber,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB8BCB3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  report.title,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _categoryLabel(report.category),
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

  Widget _priorityControl(
    BuildContext context,
    ReportDetailState state,
    LabReport report,
  ) {
    const priorities = <String>['low', 'medium', 'high', 'critical'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority Penanganan',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: priorities
                .map((priority) {
                  return ChoiceChip(
                    label: Text(_priorityLabel(priority)),
                    selected: report.priority == priority,
                    onSelected: state.isProcessing
                        ? null
                        : (_) {
                            context.read<ReportDetailCubit>().setPriority(
                              priority,
                            );
                          },
                    selectedColor: const Color(0xFFB9F33D),
                    backgroundColor: const Color(0xFFF6F9EF),
                    showCheckmark: false,
                    side: const BorderSide(color: Color(0xFFDDE2D5)),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _maintenanceButton(BuildContext context, LabReport report) {
    final uri = Uri(
      path: '/lab-admin/maintenance/create',
      queryParameters: {
        'labId': report.labId,
        'assetId': report.assetId!,
        'reportId': report.id,
        'description': '${report.title}: ${report.description}',
      },
    );

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () {
          context.push(uri.toString());
        },
        icon: const Icon(Icons.build_outlined),
        label: const Text(
          'Buat Maintenance dari Laporan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF111111),
          side: const BorderSide(color: Color(0xFF111111)),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _actionArea(
    BuildContext context,
    ReportDetailState state,
    LabReport report,
  ) {
    if (report.isOpen) {
      return _primaryButton(
        icon: Icons.mark_email_read_outlined,
        label: 'Terima Laporan',
        processing: state.isProcessing,
        onPressed: context.read<ReportDetailCubit>().acknowledge,
      );
    }

    if (report.isAcknowledged) {
      return Column(
        children: [
          _primaryButton(
            icon: Icons.play_arrow_rounded,
            label: 'Mulai Penanganan',
            processing: state.isProcessing,
            onPressed: context.read<ReportDetailCubit>().startProgress,
          ),
          const SizedBox(height: 10),
          _rejectButton(context, state),
        ],
      );
    }

    if (report.isInProgress) {
      return Column(
        children: [
          _primaryButton(
            icon: Icons.task_alt_rounded,
            label: 'Selesaikan Laporan',
            processing: state.isProcessing,
            onPressed: () async {
              final response = await _responseDialog(
                context,
                title: 'Selesaikan Laporan',
                hint: 'Jelaskan tindakan yang sudah dilakukan...',
                actionLabel: 'Selesaikan',
              );

              if (response == null || !context.mounted) {
                return;
              }

              await context.read<ReportDetailCubit>().resolve(response);
            },
          ),
          const SizedBox(height: 10),
          _rejectButton(context, state),
        ],
      );
    }

    if (report.isResolved) {
      return _primaryButton(
        icon: Icons.archive_outlined,
        label: 'Tutup Laporan',
        processing: state.isProcessing,
        onPressed: context.read<ReportDetailCubit>().closeResolved,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: report.isRejected
            ? const Color(0xFFFFE2E2)
            : const Color(0xFFEAFBCB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            report.isRejected
                ? Icons.cancel_outlined
                : Icons.check_circle_outline_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              report.isRejected
                  ? 'Laporan telah ditolak dan tidak memerlukan tindakan lanjutan.'
                  : 'Laporan telah ditutup.',
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejectButton(BuildContext context, ReportDetailState state) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: state.isProcessing
            ? null
            : () async {
                final response = await _responseDialog(
                  context,
                  title: 'Tolak Laporan',
                  hint: 'Jelaskan alasan laporan tidak dapat diproses...',
                  actionLabel: 'Tolak Laporan',
                );

                if (response == null || !context.mounted) {
                  return;
                }

                await context.read<ReportDetailCubit>().reject(response);
              },
        icon: const Icon(Icons.close_rounded),
        label: const Text(
          'Tolak Laporan',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFB42318),
          side: const BorderSide(color: Color(0xFFB42318)),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required bool processing,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: processing ? null : onPressed,
        icon: processing
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }

  Future<String?> _responseDialog(
    BuildContext context, {
    required String title,
    required String hint,
    required String actionLabel,
  }) {
    var response = '';

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F9EF),
          title: Text(title),
          content: TextField(
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            onChanged: (value) {
              response = value.trim();
            },
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (response.isEmpty) {
                  return;
                }

                FocusScope.of(dialogContext).unfocus();
                Navigator.of(dialogContext).pop(response);
              },
              child: Text(actionLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _timeline(LabReport report) {
    // Gunakan timestamp event yang benar-benar tersimpan di Firestore.
    // updatedAt tidak dipakai sebagai timestamp lifecycle karena field itu
    // juga berubah saat priority atau data operasional lain diperbarui.
    final items = <_TimelineEntry>[
      _TimelineEntry('Laporan dibuat', report.createdAt),
      if (report.acknowledgedAt != null)
        _TimelineEntry('Laporan diterima Lab Admin', report.acknowledgedAt!),
      if (report.resolvedAt != null)
        _TimelineEntry('Masalah dinyatakan selesai', report.resolvedAt!),
      if (report.closedAt != null)
        _TimelineEntry(
          report.isRejected ? 'Laporan ditolak' : 'Laporan ditutup',
          report.closedAt!,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Status',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final last = entry.key == items.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB9F33D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 38,
                        color: const Color(0xFFDDE2D5),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(item.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A8190),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
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

class _TimelineEntry {
  const _TimelineEntry(this.label, this.date);

  final String label;
  final DateTime date;
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

String _statusLabel(String status) {
  switch (status) {
    case 'acknowledged':
      return 'Diterima';
    case 'in_progress':
      return 'Sedang Ditangani';
    case 'resolved':
      return 'Resolved';
    case 'closed':
      return 'Selesai';
    case 'rejected':
      return 'Ditolak';
    case 'open':
    default:
      return 'Menunggu Tanggapan';
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

String _categoryLabel(String category) {
  switch (category) {
    case 'asset_damage':
      return 'Kerusakan Aset';
    case 'asset_lost':
      return 'Aset Hilang';
    case 'network':
      return 'Jaringan';
    case 'computer':
      return 'Komputer';
    case 'software':
      return 'Software';
    case 'facility':
      return 'Fasilitas';
    case 'electricity':
      return 'Kelistrikan';
    case 'other':
    default:
      return 'Lainnya';
  }
}

String _formatDateTime(DateTime value) {
  const months = <String>[
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

  final day = value.day.toString().padLeft(2, '0');
  final month = months[value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');

  return '$day $month ${value.year} · $hour:$minute';
}
