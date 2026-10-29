import 'package:flutter/material.dart';

import '../../../../shared/presentation/navigation/labflow_back_fallback.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/borrow_request_service.dart';
import '../../data/borrowing_assignment_service.dart';
import '../../domain/borrow_assignment.dart';
import '../cubit/asset_assignment_cubit.dart';
import '../cubit/asset_assignment_state.dart';

class AssetAssignmentPage extends StatelessWidget {
  const AssetAssignmentPage({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AssetAssignmentCubit(
        BorrowRequestService(),
        BorrowingAssignmentService(),
      )..load(requestId),
      child: const _AssetAssignmentView(),
    );
  }
}

class _AssetAssignmentView extends StatelessWidget {
  const _AssetAssignmentView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetAssignmentCubit, AssetAssignmentState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != AssetAssignmentActionStatus.idle,
      listener: (context, state) {
        if (state.actionStatus == AssetAssignmentActionStatus.success) {
          context.pop(true);
          return;
        }

        final type = switch (state.actionStatus) {
          AssetAssignmentActionStatus.warning =>
            LabFlowNotificationType.warning,
          AssetAssignmentActionStatus.failure => LabFlowNotificationType.error,
          AssetAssignmentActionStatus.success =>
            LabFlowNotificationType.success,
          AssetAssignmentActionStatus.idle => LabFlowNotificationType.info,
        };

        showLabFlowNotification(
          context: context,
          title: state.actionStatus == AssetAssignmentActionStatus.warning
              ? 'Penugasan belum dapat diproses'
              : 'Penugasan gagal',
          message: state.actionMessage,
          type: type,
        );

        context.read<AssetAssignmentCubit>().clearActionFeedback();
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
              'Penugasan Aset',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AssetAssignmentState state) {
    if (state.status == AssetAssignmentStatus.initial ||
        state.status == AssetAssignmentStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Menyiapkan penugasan',
        message: 'Memuat item permintaan dan stok aset laboratorium.',
      );
    }

    if (state.status == AssetAssignmentStatus.failure ||
        state.request == null) {
      return LabFlowConnectionErrorState(
        title: 'Penugasan aset tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data penugasan tidak dapat dimuat.'
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
              studentId: request.studentNameLabel,
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
                      'Pilih aset aktual untuk setiap item. Stok baru akan '
                      'dikurangi setelah tombol Konfirmasi Penugasan ditekan.',
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
              'Aset yang Ditugaskan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sesuaikan setiap item dengan aset yang masih tersedia di laboratorium.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            if (state.itemsLoading || state.assetsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.items.isEmpty)
              _emptyCard(
                icon: Icons.inventory_2_outlined,
                title: 'Item permintaan tidak tersedia',
                message: 'Tidak ada item yang dapat dipasangkan dengan aset.',
              )
            else ...[
              for (var index = 0; index < state.items.length; index++) ...[
                _assignmentCard(context, state, state.items[index], index + 1),
                if (index < state.items.length - 1) const SizedBox(height: 12),
              ],
            ],
            if (!state.itemsLoading &&
                !state.assetsLoading &&
                state.assets.isEmpty) ...[
              const SizedBox(height: 16),
              _emptyCard(
                icon: Icons.inventory_2_outlined,
                title: 'Tidak ada aset tersedia',
                message: 'Tambahkan stok atau periksa status/kondisi inventaris sebelum melanjutkan.',
              ),
            ],
            const SizedBox(height: 22),
            if (state.validationMessage != null &&
                !state.itemsLoading &&
                !state.assetsLoading)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0CF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: Color(0xFFA86E00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.validationMessage!,
                        style: const TextStyle(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7D5600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: state.canSubmit
                    ? context.read<AssetAssignmentCubit>().confirmAssignment
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
                    : const Icon(Icons.assignment_turned_in_outlined),
                label: const Text(
                  'Konfirmasi Penugasan',
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
              Icons.assignment_outlined,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permintaan disetujui',
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

  Widget _assignmentCard(
    BuildContext context,
    AssetAssignmentState state,
    AssignmentRequestItem item,
    int number,
  ) {
    final selectedAssetId = state.selectedAssetByItem[item.documentId];
    final selectedAsset = state.assetById(selectedAssetId);

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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBCB),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Jumlah ${item.quantity}',
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
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: selectedAssetId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Pilih aset',
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              filled: true,
              fillColor: const Color(0xFFF8FAF5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD8DDD0)),
              ),
            ),
            items: state.assets
                .map(
                  (asset) => DropdownMenuItem<String>(
                    value: asset.id,
                    child: Text(
                      '${asset.code} · ${asset.name} · Stok ${asset.stock}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: state.isProcessing
                ? null
                : (assetId) {
                    context.read<AssetAssignmentCubit>().selectAsset(
                      requestItemId: item.documentId,
                      assetId: assetId,
                    );
                  },
          ),
          if (selectedAsset != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F9EF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _assetMeta(
                    Icons.location_on_outlined,
                    selectedAsset.location,
                  ),
                  _assetMeta(
                    Icons.inventory_outlined,
                    'Stok ${selectedAsset.stock}',
                  ),
                  _assetMeta(
                    Icons.health_and_safety_outlined,
                    _conditionLabel(selectedAsset.condition),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _assetMeta(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5F6672),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 30, color: const Color(0xFF6B7280)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

String _conditionLabel(String condition) {
  switch (condition) {
    case 'good':
      return 'Baik';
    case 'minor_damage':
      return 'Kerusakan ringan';
    case 'damaged':
      return 'Rusak';
    default:
      return condition;
  }
}
