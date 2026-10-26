import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../borrowing/domain/borrow_request.dart';
import '../../data/student_borrowing_detail_service.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      body: SafeArea(
        bottom: false,
        child:
            BlocBuilder<
              StudentBorrowingDetailCubit,
              StudentBorrowingDetailState
            >(
              builder: (context, state) {
                if (state.status == StudentBorrowingDetailStatus.initial ||
                    state.status == StudentBorrowingDetailStatus.loading) {
                  return const StudentLoading(
                    message: 'Memuat detail peminjaman.',
                  );
                }
                if (state.status == StudentBorrowingDetailStatus.failure ||
                    state.request == null) {
                  return StudentErrorState(
                    message: state.errorMessage,
                    onRetry: () => context
                        .read<StudentBorrowingDetailCubit>()
                        .watch(requestId),
                  );
                }
                return _content(context, state.request!, state);
              },
            ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    BorrowRequest request,
    StudentBorrowingDetailState state,
  ) {
    final firstItem = state.items.isEmpty ? null : state.items.first;
    final displayName = state.assignments.isNotEmpty
        ? state.assignments.first.assetName
        : firstItem?.itemName ?? request.requestNumber;
    final displayCode = state.assignments.isNotEmpty
        ? state.assignments.first.assetCode
        : firstItem?.itemId ?? '';

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              StudentBackHeader(
                title: 'Detail Peminjaman',
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: studentInk,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StudentStatusPill(status: request.status),
                    const SizedBox(height: 18),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${displayCode.isEmpty ? request.requestNumber : displayCode} · ${state.laboratoryName}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD4D8CE),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _darkMeta(
                            'Tanggal Pinjam',
                            studentFormatDate(request.borrowDate),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _darkMeta(
                            'Tanggal Kembali',
                            studentFormatDate(request.expectedReturnDate),
                            accent: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _plainMeta(
                      'Permintaan Dibuat',
                      studentFormatDateTime(request.createdAt),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(child: _plainMeta('Tujuan', request.purpose)),
                ],
              ),
              if (state.items.length > 1 || state.assignments.length > 1) ...[
                const SizedBox(height: 18),
                const Text(
                  'Barang yang diajukan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 9),
                ...state.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: studentBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${item.quantity} unit',
                            style: const TextStyle(color: studentMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Perjalanan peminjaman',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _timeline(request, state),
              if (request.rejectionReason?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: studentPinkSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    request.rejectionReason!,
                    style: const TextStyle(
                      color: studentPinkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/student/reports'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: studentInk,
                  side: const BorderSide(color: studentBorder),
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text(
                  'Hubungi Lab Admin',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _darkMeta(String label, String value, {bool accent = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: accent ? studentLime : Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _plainMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: studentMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w800,
            color: studentInk,
          ),
        ),
      ],
    );
  }

  Widget _timeline(BorrowRequest request, StudentBorrowingDetailState state) {
    final completed = <String>{'pending'};
    if (request.status == 'approved') {
      completed.add('approved');
    } else if (request.status == 'waiting_pickup') {
      completed.addAll(['approved', 'waiting_pickup']);
    } else if (request.status == 'active') {
      completed.addAll(['approved', 'waiting_pickup', 'active']);
    } else if (request.status == 'returned') {
      completed.addAll(['approved', 'waiting_pickup', 'active', 'returned']);
    }

    final pickup = state.assignments.isNotEmpty
        ? state.assignments.first.pickupAt
        : null;
    final returned = state.assignments.isNotEmpty
        ? state.assignments.first.returnedAt
        : null;

    final steps = <_TimelineData>[
      _TimelineData(
        'Permintaan Dibuat',
        studentFormatDateTime(request.createdAt),
        true,
      ),
      _TimelineData(
        'Disetujui',
        request.approvedAt == null
            ? 'Menunggu Lab Admin'
            : studentFormatDateTime(request.approvedAt!),
        completed.contains('approved'),
      ),
      _TimelineData(
        'Menunggu Pengambilan',
        completed.contains('waiting_pickup')
            ? 'Aset siap diambil'
            : 'Belum tersedia',
        completed.contains('waiting_pickup'),
      ),
      _TimelineData(
        'Aktif',
        pickup == null
            ? 'Aset belum diambil'
            : 'Diambil ${studentFormatDateTime(pickup)}',
        completed.contains('active'),
      ),
      _TimelineData(
        request.status == 'rejected'
            ? 'Ditolak'
            : request.status == 'cancelled'
            ? 'Dibatalkan'
            : 'Selesai',
        request.status == 'returned' && returned != null
            ? 'Dikembalikan ${studentFormatDateTime(returned)}'
            : 'Kembalikan paling lambat ${studentFormatDateTime(request.expectedReturnDate)}',
        request.status == 'returned' ||
            request.status == 'rejected' ||
            request.status == 'cancelled',
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              child: Column(
                children: [
                  Container(
                    width: 13,
                    height: 13,
                    decoration: BoxDecoration(
                      color: step.done ? studentInk : Colors.white,
                      border: Border.all(
                        color: step.done ? studentInk : studentBorder,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 46,
                      color: step.done ? studentInk : studentBorder,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: step.done ? studentInk : studentMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      step.subtitle,
                      style: const TextStyle(fontSize: 11, color: studentMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineData {
  const _TimelineData(this.title, this.subtitle, this.done);
  final String title;
  final String subtitle;
  final bool done;
}
