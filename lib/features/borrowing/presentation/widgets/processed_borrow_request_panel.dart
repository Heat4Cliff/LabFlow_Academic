import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../domain/borrow_request.dart';
import '../cubit/admin_borrow_request_detail_cubit.dart';

class ProcessedBorrowRequestPanel extends StatelessWidget {
  const ProcessedBorrowRequestPanel({required this.request, super.key});

  final BorrowRequest request;

  @override
  Widget build(BuildContext context) {
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
}

class RejectBorrowRequestDialog extends StatefulWidget {
  const RejectBorrowRequestDialog({super.key});

  @override
  State<RejectBorrowRequestDialog> createState() =>
      _RejectBorrowRequestDialogState();
}

class _RejectBorrowRequestDialogState extends State<RejectBorrowRequestDialog> {
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
