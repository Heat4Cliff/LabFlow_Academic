import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../borrowing/domain/borrow_request.dart';
import '../../data/student_borrowing_detail_service.dart';
import '../../domain/student_borrowing_detail.dart';
import '../cubit/student_borrowing_detail_cubit.dart';
import '../cubit/student_borrowing_detail_state.dart';
import '../widgets/student_ui.dart';

class StudentBorrowingDetailPage extends StatelessWidget {
  const StudentBorrowingDetailPage({required this.requestId, super.key});
  final String requestId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        StudentBorrowingDetailCubit(StudentBorrowingDetailService())
          ..watch(requestId),
    child: _StudentBorrowingDetailView(requestId: requestId),
  );
}

class _StudentBorrowingDetailView extends StatelessWidget {
  const _StudentBorrowingDetailView({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: studentPaper,
    appBar: AppBar(
      title: const Text('Detail Peminjaman'),
      backgroundColor: studentPaper,
    ),
    body: BlocBuilder<StudentBorrowingDetailCubit, StudentBorrowingDetailState>(
      builder: (context, state) {
        if (state.status == StudentBorrowingDetailStatus.initial ||
            state.status == StudentBorrowingDetailStatus.loading) {
          return const StudentLoading(message: 'Memuat detail peminjaman.');
        }
        if (state.status == StudentBorrowingDetailStatus.failure ||
            state.request == null) {
          return StudentErrorState(
            message: state.errorMessage,
            onRetry: () =>
                context.read<StudentBorrowingDetailCubit>().watch(requestId),
          );
        }
        return _content(state.request!, state);
      },
    ),
  );

  Widget _content(BorrowRequest request, StudentBorrowingDetailState state) =>
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            request.requestNumber,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          _badge(studentStatusLabel(request.status)),
          const SizedBox(height: 16),
          _card('Laboratorium', state.laboratoryName),
          _card('Tujuan', request.purpose),
          _card(
            'Catatan',
            request.studentNote?.isNotEmpty == true
                ? request.studentNote!
                : 'Tidak ada catatan',
          ),
          _card('Tanggal pinjam', studentFormatDate(request.borrowDate)),
          _card(
            'Rencana kembali',
            studentFormatDate(request.expectedReturnDate),
          ),
          if (request.rejectionReason?.isNotEmpty == true)
            _card('Alasan penolakan', request.rejectionReason!),
          const SizedBox(height: 8),
          const Text(
            'Barang yang diajukan',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          ...state.items.map(
            (item) => _card(item.itemName, '${item.quantity} unit'),
          ),
          if (state.assignments.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Aset yang dialokasikan',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            ...state.assignments.map((item) => _assignment(item)),
          ],
          const SizedBox(height: 16),
          _timeline(request.status),
        ],
      );

  Widget _card(String title, String value) => Container(
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: studentBorder),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: studentMuted, fontSize: 11)),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  Widget _assignment(StudentAssignedBorrowing item) => _card(
    '${item.assetName}${item.assetCode.isEmpty ? '' : ' · ${item.assetCode}'}',
    '${item.quantity} unit · ${studentStatusLabel(item.status)}${item.pickupAt == null ? '' : '\nDiambil ${studentFormatDate(item.pickupAt!)}'}${item.returnedAt == null ? '' : '\nDikembalikan ${studentFormatDate(item.returnedAt!)}'}${item.returnCondition == null ? '' : '\nKondisi: ${item.returnCondition}'}${item.returnNote == null || item.returnNote!.isEmpty ? '' : '\nCatatan: ${item.returnNote}'}',
  );

  Widget _badge(String label) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: studentSoftLime,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );

  Widget _timeline(String status) {
    final steps = [
      'pending',
      'approved',
      'waiting_pickup',
      'active',
      'returned',
    ];
    final rejected = status == 'rejected' || status == 'cancelled';
    final current = steps.indexOf(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perjalanan peminjaman',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (rejected)
            Text(
              status == 'rejected'
                  ? 'Pengajuan ditolak'
                  : 'Pengajuan dibatalkan',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          for (var index = 0; index < steps.length && !rejected; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(
                    index <= current
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: index <= current ? studentInk : studentMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    studentStatusLabel(steps[index]),
                    style: TextStyle(
                      fontWeight: index == current
                          ? FontWeight.w900
                          : FontWeight.w500,
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
