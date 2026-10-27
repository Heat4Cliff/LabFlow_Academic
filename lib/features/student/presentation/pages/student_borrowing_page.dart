import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import '../student_navigation.dart';
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

class _StudentBorrowingView extends StatefulWidget {
  const _StudentBorrowingView();

  @override
  State<_StudentBorrowingView> createState() => _StudentBorrowingViewState();
}

class _StudentBorrowingViewState extends State<_StudentBorrowingView> {
  String _tab = 'Permintaan';

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
        showLabFlowNotification(
          context: context,
          message: message,
          type: state.errorMessage.isNotEmpty
              ? LabFlowNotificationType.error
              : LabFlowNotificationType.success,
        );
        context.read<StudentBorrowingCubit>().clearFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: studentPaper,
          bottomNavigationBar: const StudentBottomNavigation(currentIndex: 2),
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

    final visible = _filter(state.requests);
    final overdue = state.requests.where((request) {
      return request.status == 'active' &&
          request.expectedReturnDate.isBefore(DateTime.now());
    }).length;

    return RefreshIndicator(
      onRefresh: context.read<StudentBorrowingCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Pinjaman Saya',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.5,
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _tabButton('Permintaan'),
              const SizedBox(width: 8),
              _tabButton('Aktif'),
              const SizedBox(width: 8),
              _tabButton('Riwayat'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${visible.length} alat.\nSiap berkarya.',
            style: const TextStyle(
              fontSize: 25,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: studentInk,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pantau batas waktu dan kembalikan tepat waktu.',
            style: TextStyle(fontSize: 11, color: studentMuted),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            _empty(context)
          else
            ...visible.map(
              (request) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _requestCard(context, state, request),
              ),
            ),
          if (overdue > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$overdue pinjaman melewati batas waktu. Segera hubungi Lab Admin untuk pengembalian.',
              style: const TextStyle(
                fontSize: 10,
                height: 1.4,
                color: studentPinkText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(String label) {
    final selected = _tab == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _tab = label),
      selectedColor: studentInk,
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? studentInk : studentBorder),
      labelStyle: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: selected ? studentLime : studentInk,
      ),
      shape: const StadiumBorder(),
    );
  }

  List<StudentBorrowRequest> _filter(List<StudentBorrowRequest> requests) {
    switch (_tab) {
      case 'Aktif':
        return requests
            .where(
              (request) =>
                  request.status == 'active' ||
                  request.status == 'waiting_pickup',
            )
            .toList(growable: false);
      case 'Riwayat':
        return requests
            .where(
              (request) =>
                  request.status == 'returned' ||
                  request.status == 'rejected' ||
                  request.status == 'cancelled',
            )
            .toList(growable: false);
      default:
        return requests
            .where(
              (request) =>
                  request.status == 'pending' || request.status == 'approved',
            )
            .toList(growable: false);
    }
  }

  Widget _requestCard(
    BuildContext context,
    StudentBorrowingState state,
    StudentBorrowRequest request,
  ) {
    final cancelling = state.cancellingIds.contains(request.id);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => context.push(studentBorrowingDocumentPath(request.id)),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.purpose,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.requestNumber,
                          style: const TextStyle(
                            fontSize: 9,
                            color: studentMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_outward_rounded, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              StudentStatusPill(status: request.status, small: true),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: studentMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${studentFormatDate(request.borrowDate)} → ${studentFormatDate(request.expectedReturnDate)}',
                    style: const TextStyle(fontSize: 10, color: studentMuted),
                  ),
                ],
              ),
              if (request.status == 'pending') ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: cancelling
                        ? null
                        : () async {
                            final confirmed = await _confirmCancel(context);
                            if (confirmed != true || !context.mounted) return;
                            await context.read<StudentBorrowingCubit>().cancel(
                              request.id,
                            );
                          },
                    icon: cancelling
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Batalkan'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(Icons.handshake_outlined, size: 38, color: studentMuted),
          const SizedBox(height: 10),
          const Text(
            'Belum ada pinjaman',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          const Text(
            'Mulai praktikum Anda dengan menemukan peralatan yang tepat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: studentMuted),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/student/assets'),
              style: FilledButton.styleFrom(
                backgroundColor: studentInk,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Cari Peralatan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmCancel(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Batalkan pengajuan?'),
        content: const Text(
          'Pengajuan yang masih menunggu akan ditandai sebagai dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: studentPinkText,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }
}
