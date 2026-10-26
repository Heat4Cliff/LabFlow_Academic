import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/borrow_request_service.dart';
import '../../data/pickup_verification_service.dart';
import '../../domain/pickup_borrowing.dart';
import '../cubit/pickup_verification_cubit.dart';
import '../cubit/pickup_verification_state.dart';

class PickupVerificationPage extends StatelessWidget {
  const PickupVerificationPage({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PickupVerificationCubit(
        BorrowRequestService(),
        PickupVerificationService(),
      )..load(requestId),
      child: const _PickupVerificationView(),
    );
  }
}

class _PickupVerificationView extends StatelessWidget {
  const _PickupVerificationView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PickupVerificationCubit, PickupVerificationState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != PickupVerificationActionStatus.idle,
      listener: (context, state) {
        if (state.actionStatus == PickupVerificationActionStatus.success) {
          context.pop(true);
          return;
        }

        final type = switch (state.actionStatus) {
          PickupVerificationActionStatus.warning =>
            LabFlowNotificationType.warning,
          PickupVerificationActionStatus.failure =>
            LabFlowNotificationType.error,
          PickupVerificationActionStatus.success =>
            LabFlowNotificationType.success,
          PickupVerificationActionStatus.idle => LabFlowNotificationType.info,
        };

        showLabFlowNotification(
          context: context,
          title: state.actionStatus == PickupVerificationActionStatus.warning
              ? 'Verifikasi belum dapat diproses'
              : 'Verifikasi gagal',
          message: state.actionMessage,
          type: type,
        );

        context.read<PickupVerificationCubit>().clearActionFeedback();
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Verifikasi Pengambilan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, PickupVerificationState state) {
    if (state.status == PickupVerificationStatus.initial ||
        state.status == PickupVerificationStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Menyiapkan verifikasi',
        message: 'Memuat request dan aset yang telah dialokasikan.',
      );
    }

    if (state.status == PickupVerificationStatus.failure ||
        state.request == null) {
      return LabFlowConnectionErrorState(
        title: 'Verifikasi pengambilan tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data pengambilan tidak dapat dimuat.'
            : state.errorMessage,
      );
    }

    final request = state.request!;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _requestSummary(
              requestNumber: request.requestNumber,
              studentId: request.studentId,
            ),
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
                      'Pastikan mahasiswa dan aset fisik sesuai sebelum '
                      'mengaktifkan peminjaman.',
                      style: TextStyle(
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Aset yang Diserahkan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Cocokkan kode dan nama aset dengan barang yang diserahkan.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            if (state.assignmentsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.assignments.isEmpty)
              _emptyAssignments()
            else
              ...state.assignments.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == state.assignments.length - 1 ? 0 : 12,
                  ),
                  child: _assignmentCard(entry.value),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Checklist Verifikasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            _checkCard(
              value: state.studentIdentityChecked,
              title: 'Identitas mahasiswa sesuai',
              subtitle:
                  'Pastikan mahasiswa yang mengambil sesuai dengan request.',
              onChanged: state.isProcessing
                  ? null
                  : context
                        .read<PickupVerificationCubit>()
                        .setStudentIdentityChecked,
            ),
            const SizedBox(height: 10),
            _checkCard(
              value: state.assetMatchChecked,
              title: 'Aset fisik sesuai penugasan',
              subtitle: 'Kode, nama, dan jumlah aset sudah dicocokkan.',
              onChanged: state.isProcessing
                  ? null
                  : context
                        .read<PickupVerificationCubit>()
                        .setAssetMatchChecked,
            ),
            const SizedBox(height: 10),
            _checkCard(
              value: state.handoverChecked,
              title: 'Barang telah diserahkan',
              subtitle: 'Konfirmasi bahwa aset benar-benar diterima mahasiswa.',
              onChanged: state.isProcessing
                  ? null
                  : context.read<PickupVerificationCubit>().setHandoverChecked,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: state.canConfirm
                    ? context.read<PickupVerificationCubit>().confirmPickup
                    : null,
                icon: state.isProcessing
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.verified_outlined),
                label: const Text(
                  'Konfirmasi Pengambilan',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFB8BCB3),
                  disabledForegroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _requestSummary({
    required String requestNumber,
    required String studentId,
  }) {
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
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFB9F33D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_outlined,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menunggu pengambilan',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 4),
                Text(
                  requestNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  studentId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

  Widget _assignmentCard(PickupBorrowing assignment) {
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
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAFBCB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignment.assetName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  assignment.assetCode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5F6672),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${assignment.itemName} · Jumlah ${assignment.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8190),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Dialokasikan',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3559A6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkCard({
    required bool value,
    required String title,
    required String subtitle,
    required ValueChanged<bool>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: value ? const Color(0xFFB9F33D) : const Color(0xFFDDE2D5),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged == null
            ? null
            : (checked) => onChanged(checked ?? false),
        activeColor: const Color(0xFF111111),
        checkColor: const Color(0xFFB9F33D),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyAssignments() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32, color: Color(0xFF6B7280)),
          SizedBox(height: 10),
          Text(
            'Aset penugasan tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 5),
          Text(
            'Kembali ke detail request dan pastikan penugasan aset sudah selesai.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
