import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';

import '../../../../shared/presentation/states/labflow_loading_state.dart';

import '../../data/borrow_request_service.dart';

import '../../domain/borrow_request.dart';

import '../cubit/admin_borrow_request_detail_cubit.dart';

import '../cubit/admin_borrow_request_detail_state.dart';

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

            _identityCard(request),

            const SizedBox(height: 16),

            _itemsCard(state),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _dateCard(
                    'Tanggal Pinjam',

                    request.borrowDate,

                    Icons.calendar_today_outlined,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _dateCard(
                    'Tanggal Kembali',

                    request.expectedReturnDate,

                    Icons.event_available_outlined,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _textCard(
              'Tujuan Peminjaman',

              request.purpose.isEmpty ? 'Tidak dicantumkan.' : request.purpose,

              Icons.notes_rounded,
            ),

            if ((request.studentNote ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              _textCard(
                'Catatan Mahasiswa',

                request.studentNote!.trim(),

                Icons.chat_bubble_outline_rounded,
              ),
            ],

            if (request.isRejected &&
                (request.rejectionReason ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),

              _textCard(
                'Alasan Penolakan',

                request.rejectionReason!.trim(),

                Icons.block_outlined,
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
              _processedState(context, request),
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
      builder: (_) => const _RejectBorrowRequestDialog(),
    );

    if (reason == null || !context.mounted) {
      return;
    }

    await context.read<AdminBorrowRequestDetailCubit>().reject(reason);
  }

  Widget _processedState(BuildContext context, BorrowRequest request) {
    if (request.status == 'approved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDDE2D5)),
        ),
        child: Column(
          children: [
            const Text(
              'Permintaan telah disetujui. Pilih aset aktual yang akan '
              'dialokasikan sebelum mahasiswa melakukan pengambilan.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () async {
                  final assigned = await context.push<bool>(
                    '/lab-admin/borrowing/${request.id}/assign',
                  );

                  if (assigned != true || !context.mounted) {
                    return;
                  }

                  await context.read<AdminBorrowRequestDetailCubit>().load(
                    request.id,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  showLabFlowNotification(
                    context: context,
                    title: 'Penugasan berhasil',
                    message: 'Aset sudah dialokasikan dan menunggu proses pengambilan.',
                    type: LabFlowNotificationType.success,
                  );
                },
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text(
                  'Tugaskan Aset',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (request.status == 'waiting_pickup') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBCB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.inventory_outlined, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aset sudah ditugaskan. Verifikasi mahasiswa dan barang '
                    'sebelum peminjaman diaktifkan.',
                    style: TextStyle(height: 1.4, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () async {
                  final verified = await context.push<bool>(
                    '/lab-admin/borrowing/${request.id}/pickup',
                  );

                  if (verified != true || !context.mounted) {
                    return;
                  }

                  await context.read<AdminBorrowRequestDetailCubit>().load(
                    request.id,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  showLabFlowNotification(
                    context: context,
                    title: 'Pengambilan terverifikasi',
                    message:
                        'Aset telah diserahkan dan peminjaman sekarang aktif.',
                    type: LabFlowNotificationType.success,
                  );
                },
                icon: const Icon(Icons.verified_outlined),
                label: const Text(
                  'Verifikasi Pengambilan',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (request.status == 'active') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFDFF5E8),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 22,
                  color: Color(0xFF188A55),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Peminjaman aktif. Saat barang dikembalikan, lanjutkan '
                    'proses penerimaan dan pemeriksaan kondisi.',
                    style: TextStyle(
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF145C3E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () async {
                  final returned = await context.push<bool>(
                    '/lab-admin/borrowing/${request.id}/return',
                  );

                  if (returned != true || !context.mounted) {
                    return;
                  }

                  await context.read<AdminBorrowRequestDetailCubit>().load(
                    request.id,
                  );

                  if (!context.mounted) {
                    return;
                  }

                  showLabFlowNotification(
                    context: context,
                    title: 'Pengembalian selesai',
                    message:
                        'Barang telah diterima dan kondisi aset sudah dicatat.',
                    type: LabFlowNotificationType.success,
                  );
                },
                icon: const Icon(Icons.keyboard_return_rounded),
                label: const Text(
                  'Proses Pengembalian',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (request.status == 'returned') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBCB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.task_alt_rounded, size: 22, color: Color(0xFF4D7014)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Peminjaman selesai. Barang telah dikembalikan dan hasil '
                'pemeriksaan kondisi sudah tersimpan.',
                style: TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF39560E),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Text(
        request.isRejected
            ? 'Permintaan telah ditolak.'
            : 'Permintaan ini tidak lagi menunggu persetujuan.',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _identityCard(BorrowRequest request) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),

      child: Row(
        children: [
          Container(
            width: 48,

            height: 48,

            decoration: const BoxDecoration(
              color: Color(0xFFEAFBCB),

              shape: BoxShape.circle,
            ),

            child: const Icon(Icons.person_outline_rounded),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Peminjam',

                  style: TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
                ),

                const SizedBox(height: 4),

                Text(
                  request.studentId,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 16,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  request.requestNumber,

                  style: const TextStyle(
                    fontSize: 12,

                    color: Color(0xFF7A8190),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(AdminBorrowRequestDetailState state) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Aset yang Diminta',

            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 14),

          if (state.itemsLoading)
            const Row(
              children: [
                SizedBox(
                  width: 18,

                  height: 18,

                  child: CircularProgressIndicator(strokeWidth: 2),
                ),

                SizedBox(width: 10),

                Text('Memuat detail item...'),
              ],
            )
          else if (state.itemsError.isNotEmpty)
            Text(
              state.itemsError,

              style: const TextStyle(color: Color(0xFFBD3232)),
            )
          else if (state.items.isEmpty)
            const Text(
              'Detail item belum tersedia.',

              style: TextStyle(color: Color(0xFF7A8190)),
            )
          else
            for (var index = 0; index < state.items.length; index++) ...[
              if (index > 0)
                const Divider(height: 22, color: Color(0xFFE2E6DC)),

              Row(
                children: [
                  Container(
                    width: 54,

                    height: 54,

                    decoration: BoxDecoration(
                      color: const Color(0xFFEAFBCB),

                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: const Icon(Icons.inventory_2_outlined),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          state.items[index].itemName,

                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          'Jumlah ${state.items[index].quantity}'
                          '${state.items[index].requestedAssetId == null ? '' : ' · Aset ${state.items[index].requestedAssetId}'}',

                          maxLines: 2,

                          overflow: TextOverflow.ellipsis,

                          style: const TextStyle(
                            fontSize: 12,

                            color: Color(0xFF7A8190),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  Widget _dateCard(String label, DateTime date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 20, color: const Color(0xFF5F6672)),

          const SizedBox(height: 10),

          Text(
            label,

            style: const TextStyle(fontSize: 11, color: Color(0xFF7A8190)),
          ),

          const SizedBox(height: 3),

          Text(
            _formatDate(date),

            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _textCard(String title, String text, IconData icon) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon, size: 20, color: const Color(0xFF5F6672)),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 12,

                    color: Color(0xFF7A8190),
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  text,

                  style: const TextStyle(
                    height: 1.4,

                    fontWeight: FontWeight.w600,
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

class _RejectBorrowRequestDialog extends StatefulWidget {
  const _RejectBorrowRequestDialog();

  @override
  State<_RejectBorrowRequestDialog> createState() =>
      _RejectBorrowRequestDialogState();
}

class _RejectBorrowRequestDialogState
    extends State<_RejectBorrowRequestDialog> {
  final TextEditingController _reasonController = TextEditingController();

  String? _errorText;

  @override
  void dispose() {
    // Controller dimiliki oleh dialog sehingga baru dibuang setelah route
    // dialog benar-benar selesai keluar dari widget tree.
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _reasonController.text.trim();

    if (reason.isEmpty) {
      setState(() {
        _errorText = 'Alasan penolakan wajib diisi.';
      });
      return;
    }

    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF6F9EF),
      title: const Text(
        'Tolak permintaan?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      content: TextField(
        controller: _reasonController,
        autofocus: true,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        onChanged: (_) {
          if (_errorText == null) {
            return;
          }

          setState(() {
            _errorText = null;
          });
        },
        decoration: InputDecoration(
          labelText: 'Alasan penolakan',
          hintText: 'Contoh: jadwal penggunaan bentrok dengan praktikum...',
          errorText: _errorText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFBD3232),
            foregroundColor: Colors.white,
          ),
          child: const Text('Tolak'),
        ),
      ],
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

String _formatDate(DateTime date) {
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

  if (date.millisecondsSinceEpoch == 0) {
    return '-';
  }

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
