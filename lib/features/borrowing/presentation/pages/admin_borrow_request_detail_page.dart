import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/navigation/labflow_back_fallback.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';

import '../../../../shared/presentation/states/labflow_loading_state.dart';

import '../../data/borrow_request_service.dart';

import '../../domain/borrow_request.dart';

import '../cubit/admin_borrow_request_detail_cubit.dart';

import '../cubit/admin_borrow_request_detail_state.dart';
import '../widgets/processed_borrow_request_panel.dart';
import '../widgets/borrow_request_detail_cards.dart';

class AdminBorrowRequestDetailPage extends StatelessWidget {
  const AdminBorrowRequestDetailPage({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminBorrowRequestDetailCubit(BorrowRequestService())
            ..load(requestId),

      child: const _AdminBorrowRequestDetailView(),
    );
  }
}

class _AdminBorrowRequestDetailView extends StatelessWidget {
  const _AdminBorrowRequestDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<
      AdminBorrowRequestDetailCubit,

      AdminBorrowRequestDetailState
    >(
      listenWhen: (previous, current) {
        return previous.actionStatus != current.actionStatus &&
            current.actionStatus != AdminBorrowRequestActionStatus.idle;
      },

      listener: (context, state) {
        final type = switch (state.actionStatus) {
          AdminBorrowRequestActionStatus.success =>
            LabFlowNotificationType.success,

          AdminBorrowRequestActionStatus.warning =>
            LabFlowNotificationType.warning,

          AdminBorrowRequestActionStatus.failure =>
            LabFlowNotificationType.error,

          AdminBorrowRequestActionStatus.idle => LabFlowNotificationType.info,
        };

        final title = switch (state.actionStatus) {
          AdminBorrowRequestActionStatus.success => 'Proses berhasil',

          AdminBorrowRequestActionStatus.warning =>
            'Permintaan tidak dapat diproses',

          AdminBorrowRequestActionStatus.failure => 'Proses gagal',

          AdminBorrowRequestActionStatus.idle => 'Informasi',
        };

        showLabFlowNotification(
          context: context,

          title: title,

          message: state.actionMessage,

          type: type,
        );

        context.read<AdminBorrowRequestDetailCubit>().clearActionFeedback();
      },

      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),

          appBar: AppBar(
            leading: BackButton(
              onPressed: () => popOrGo(context, '/lab-admin/borrowing'),
            ),
            backgroundColor: const Color(0xFFF6F9EF),

            surfaceTintColor: Colors.transparent,

            elevation: 0,

            title: const Text(
              'Tinjau Permintaan',

              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),

          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AdminBorrowRequestDetailState state) {
    if (state.status == AdminBorrowRequestDetailStatus.initial ||
        state.status == AdminBorrowRequestDetailStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Memuat permintaan',

        message: 'Menyiapkan detail pengajuan peminjaman.',
      );
    }

    if (state.status == AdminBorrowRequestDetailStatus.failure ||
        state.request == null) {
      return LabFlowConnectionErrorState(
        title: 'Permintaan tidak dapat dimuat',

        message: state.errorMessage.isEmpty
            ? 'Data permintaan tidak tersedia atau akses Anda telah berubah.'
            : state.errorMessage,
      );
    }

    return _detailContent(context, state.request!, state);
  }

  Widget _detailContent(
    BuildContext context,

    BorrowRequest request,

    AdminBorrowRequestDetailState state,
  ) {
    final palette = _statusPalette(request.status);

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

                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: palette.background,

                  borderRadius: BorderRadius.circular(999),
                ),

                child: Text(
                  _statusLabel(request.status),

                  style: TextStyle(
                    fontSize: 12,

                    fontWeight: FontWeight.w800,

                    color: palette.foreground,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            BorrowRequestIdentityCard(request: request),

            const SizedBox(height: 16),

            BorrowRequestItemsCard(state: state),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: BorrowRequestDateCard(
                    label: 'Tanggal Pinjam',
                    date: request.borrowDate,
                    icon: Icons.calendar_today_outlined,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: BorrowRequestDateCard(
                    label: 'Tanggal Kembali',
                    date: request.expectedReturnDate,
                    icon: Icons.event_available_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            BorrowRequestTextCard(
              title: 'Tujuan Peminjaman',
              text: request.purpose.isEmpty
                  ? 'Tidak dicantumkan.'
                  : request.purpose,
              icon: Icons.notes_rounded,
            ),

            if ((request.studentNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              BorrowRequestTextCard(
                title: 'Catatan Mahasiswa',
                text: request.studentNote!.trim(),
                icon: Icons.chat_bubble_outline_rounded,
              ),
            ],

            if (request.isRejected &&
                (request.rejectionReason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              BorrowRequestTextCard(
                title: 'Alasan Penolakan',
                text: request.rejectionReason!.trim(),
                icon: Icons.block_outlined,
              ),
            ],

            const SizedBox(height: 16),

            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: const Color(0xFFEAFBCB),

                borderRadius: BorderRadius.circular(18),
              ),

              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Icon(Icons.info_outline_rounded, size: 20),

                  SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Pastikan tanggal, tujuan, dan item sudah sesuai sebelum memproses permintaan.',

                      style: TextStyle(
                        height: 1.4,

                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (request.isPending)
              _pendingActions(context, state.isProcessing)
            else
              ProcessedBorrowRequestPanel(request: request),
          ],
        ),
      ),
    );
  }

  Widget _pendingActions(BuildContext context, bool isProcessing) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,

            child: OutlinedButton.icon(
              onPressed: isProcessing ? null : () => _showRejectDialog(context),

              icon: const Icon(Icons.close_rounded),

              label: const Text('Tolak'),

              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBD3232),

                side: const BorderSide(color: Color(0xFFE3A7A7)),

                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: SizedBox(
            height: 52,

            child: FilledButton.icon(
              onPressed: isProcessing
                  ? null
                  : context.read<AdminBorrowRequestDetailCubit>().approve,

              icon: isProcessing
                  ? const SizedBox(
                      width: 18,

                      height: 18,

                      child: CircularProgressIndicator(
                        strokeWidth: 2,

                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded),

              label: const Text('Setujui'),

              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),

                foregroundColor: Colors.white,

                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRejectDialog(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => const RejectBorrowRequestDialog(),
    );

    if (reason == null || !context.mounted) {
      return;
    }

    await context.read<AdminBorrowRequestDetailCubit>().reject(reason);
  }
}

class _StatusPalette {
  const _StatusPalette(this.background, this.foreground);

  final Color background;

  final Color foreground;
}

_StatusPalette _statusPalette(String status) {
  switch (status) {
    case 'pending':
      return const _StatusPalette(Color(0xFFFFE7B3), Color(0xFF8A5700));

    case 'approved':
      return const _StatusPalette(Color(0xFFDFF5E8), Color(0xFF188A55));

    case 'waiting_pickup':
      return const _StatusPalette(Color(0xFFE8EEFF), Color(0xFF3559A6));

    case 'active':
      return const _StatusPalette(Color(0xFFDFF5E8), Color(0xFF188A55));

    case 'returned':
      return const _StatusPalette(Color(0xFFEAFBCB), Color(0xFF4D7014));

    case 'rejected':
      return const _StatusPalette(Color(0xFFFBE1E1), Color(0xFFBD3232));

    case 'cancelled':
      return const _StatusPalette(Color(0xFFE9ECE7), Color(0xFF5F6672));

    default:
      return const _StatusPalette(Color(0xFFE9ECE7), Color(0xFF5F6672));
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'pending':
      return 'Menunggu Persetujuan';

    case 'approved':
      return 'Disetujui';

    case 'waiting_pickup':
      return 'Menunggu Pengambilan';

    case 'active':
      return 'Aktif';

    case 'returned':
      return 'Selesai';

    case 'rejected':
      return 'Ditolak';

    case 'cancelled':
      return 'Dibatalkan';

    default:
      return status;
  }
}
