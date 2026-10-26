import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import '../cubit/student_borrowing_cubit.dart';
import '../cubit/student_borrowing_state.dart';
import '../cubit/student_data_state.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentBorrowingPage extends StatelessWidget {
  const StudentBorrowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentBorrowingCubit(StudentService())..load(),
      child: const _StudentBorrowingView(),
    );
  }
}

class _StudentBorrowingView extends StatelessWidget {
  const _StudentBorrowingView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StudentBorrowingCubit, StudentBorrowingState>(
      listenWhen: (previous, current) =>
          previous.actionMessage != current.actionMessage ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        final message = state.actionMessage.isNotEmpty
            ? state.actionMessage
            : state.errorMessage;

        if (message.isEmpty) return;

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));

        context.read<StudentBorrowingCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: studentPaper,
          bottomNavigationBar: const StudentBottomNavigation(currentIndex: 2),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/student/assets'),
            backgroundColor: studentLime,
            foregroundColor: studentInk,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Ajukan',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
          body: SafeArea(bottom: false, child: _body(context, state)),
        );
      },
    );
  }

  Widget _body(BuildContext context, StudentBorrowingState state) {
    if (state.status == StudentLoadStatus.initial ||
        state.status == StudentLoadStatus.loading) {
      return const StudentLoading(message: 'Memuat aktivitas peminjaman.');
    }

    if (state.status == StudentLoadStatus.failure && state.requests.isEmpty) {
      return StudentErrorState(
        message: state.errorMessage,
        onRetry: context.read<StudentBorrowingCubit>().load,
      );
    }

    return RefreshIndicator(
      onRefresh: context.read<StudentBorrowingCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
        children: [
          const StudentPageTitle(
            title: 'Peminjaman',
            subtitle:
                'Ajukan alat dari katalog dan pantau status persetujuannya.',
          ),
          const SizedBox(height: 18),
          if (state.requests.isEmpty)
            _empty(context)
          else
            ...state.requests.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _card(context, state, request),
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    StudentBorrowingState state,
    StudentBorrowRequest request,
  ) {
    final cancelling = state.cancellingIds.contains(request.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.requestNumber,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _status(request.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.purpose,
            style: const TextStyle(
              fontSize: 15,
              height: 1.3,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${studentFormatDate(request.borrowDate)} → ${studentFormatDate(request.expectedReturnDate)}',
            style: const TextStyle(fontSize: 11, color: studentMuted),
          ),
          if ((request.rejectionReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Alasan: ${request.rejectionReason}',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (request.status == 'pending') ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: studentBorder),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: cancelling
                    ? null
                    : () async {
                        final confirmed = await _confirmCancel(context);

                        if (confirmed != true || !context.mounted) {
                          return;
                        }

                        await context.read<StudentBorrowingCubit>().cancel(
                          request.id,
                        );
                      },
                icon: cancelling
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close_rounded, size: 18),
                label: const Text('Batalkan Pengajuan'),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => context.push('/student/borrowing/${request.id}'),
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Lihat detail'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _status(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: studentSoftLime,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        studentStatusLabel(status),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Belum ada riwayat pengajuan peminjaman.',
            textAlign: TextAlign.center,
            style: TextStyle(color: studentMuted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => context.go('/student/assets'),
            style: FilledButton.styleFrom(
              backgroundColor: studentInk,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pilih Aset'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: studentPaper,
          title: const Text('Batalkan pengajuan?'),
          content: const Text(
            'Pengajuan yang masih menunggu akan ditandai sebagai dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Kembali'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
                foregroundColor: Colors.white,
              ),
              child: const Text('Batalkan'),
            ),
          ],
        );
      },
    );
  }
}
