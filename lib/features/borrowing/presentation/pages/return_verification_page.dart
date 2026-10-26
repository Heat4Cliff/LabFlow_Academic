import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/borrow_request_service.dart';
import '../../data/return_verification_service.dart';
import '../../domain/pickup_borrowing.dart';
import '../cubit/return_verification_cubit.dart';
import '../cubit/return_verification_state.dart';

class ReturnVerificationPage extends StatelessWidget {
  const ReturnVerificationPage({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnVerificationCubit(
        BorrowRequestService(),
        ReturnVerificationService(),
      )..load(requestId),
      child: const _ReturnVerificationView(),
    );
  }
}

class _ReturnVerificationView extends StatelessWidget {
  const _ReturnVerificationView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReturnVerificationCubit, ReturnVerificationState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F9EF),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF6F9EF),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Proses Pengembalian',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ReturnVerificationState state) {
    if (state.status == ReturnVerificationStatus.initial ||
        state.status == ReturnVerificationStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Menyiapkan pengembalian',
        message: 'Memuat request dan aset yang sedang dipinjam.',
      );
    }

    if (state.status == ReturnVerificationStatus.failure ||
        state.request == null) {
      return LabFlowConnectionErrorState(
        title: 'Pengembalian tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data pengembalian tidak dapat dimuat.'
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
                      'Terima seluruh barang terlebih dahulu. Kondisi setiap '
                      'aset diperiksa pada langkah berikutnya.',
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
              'Aset yang Dikembalikan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pastikan barang yang diterima sesuai dengan aset aktif.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            if (state.borrowingsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.borrowings.isEmpty)
              _emptyBorrowings()
            else
              ...state.borrowings.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == state.borrowings.length - 1 ? 0 : 12,
                  ),
                  child: _borrowingCard(entry.value),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Checklist Penerimaan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 12),
            _checkCard(
              value: state.studentChecked,
              title: 'Mahasiswa sesuai request',
              subtitle: 'Identitas pengembali sesuai dengan data peminjaman.',
              onChanged: context
                  .read<ReturnVerificationCubit>()
                  .setStudentChecked,
            ),
            const SizedBox(height: 10),
            _checkCard(
              value: state.quantityChecked,
              title: 'Jumlah barang sesuai',
              subtitle:
                  'Jumlah aset yang diterima sesuai dengan borrowing aktif.',
              onChanged: context
                  .read<ReturnVerificationCubit>()
                  .setQuantityChecked,
            ),
            const SizedBox(height: 10),
            _checkCard(
              value: state.assetsReceivedChecked,
              title: 'Seluruh barang telah diterima',
              subtitle: 'Aset fisik sudah berada kembali di tangan Lab Admin.',
              onChanged: context
                  .read<ReturnVerificationCubit>()
                  .setAssetsReceivedChecked,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: state.canContinue
                    ? () async {
                        final completed = await context.push<bool>(
                          '/lab-admin/borrowing/${request.id}/return/inspection',
                        );

                        if (completed == true && context.mounted) {
                          context.pop(true);
                        }
                      }
                    : null,
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text(
                  'Lanjut Pemeriksaan Kondisi',
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
              Icons.keyboard_return_rounded,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peminjaman aktif',
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

  Widget _borrowingCard(PickupBorrowing borrowing) {
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEAFBCB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  borrowing.assetName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  borrowing.assetCode,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5F6672),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${borrowing.itemName} · Jumlah ${borrowing.quantity}',
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
              color: const Color(0xFFDFF5E8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF188A55),
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
    required ValueChanged<bool> onChanged,
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
        onChanged: (checked) => onChanged(checked ?? false),
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

  Widget _emptyBorrowings() {
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
            'Aset aktif tidak ditemukan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
