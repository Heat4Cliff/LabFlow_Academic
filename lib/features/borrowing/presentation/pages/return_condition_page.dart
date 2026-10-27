import 'package:flutter/material.dart';

import '../../../../shared/presentation/navigation/labflow_back_fallback.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../data/borrow_request_service.dart';
import '../../data/return_verification_service.dart';
import '../../domain/pickup_borrowing.dart';
import '../../domain/return_inspection.dart';
import '../cubit/return_condition_cubit.dart';
import '../cubit/return_condition_state.dart';

class ReturnConditionPage extends StatelessWidget {
  const ReturnConditionPage({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReturnConditionCubit(
        BorrowRequestService(),
        ReturnVerificationService(),
      )..load(requestId),
      child: const _ReturnConditionView(),
    );
  }
}

class _ReturnConditionView extends StatelessWidget {
  const _ReturnConditionView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReturnConditionCubit, ReturnConditionState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          current.actionStatus != ReturnConditionActionStatus.idle,
      listener: (context, state) {
        if (state.actionStatus == ReturnConditionActionStatus.success) {
          context.pop(true);
          return;
        }

        final type = switch (state.actionStatus) {
          ReturnConditionActionStatus.warning =>
            LabFlowNotificationType.warning,
          ReturnConditionActionStatus.failure => LabFlowNotificationType.error,
          ReturnConditionActionStatus.success =>
            LabFlowNotificationType.success,
          ReturnConditionActionStatus.idle => LabFlowNotificationType.info,
        };

        showLabFlowNotification(
          context: context,
          title: state.actionStatus == ReturnConditionActionStatus.warning
              ? 'Pemeriksaan belum lengkap'
              : 'Pengembalian gagal',
          message: state.actionMessage,
          type: type,
        );

        context.read<ReturnConditionCubit>().clearActionFeedback();
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
              'Pemeriksaan Kondisi',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ReturnConditionState state) {
    if (state.status == ReturnConditionStatus.initial ||
        state.status == ReturnConditionStatus.loading) {
      return const LabFlowLoadingState(
        title: 'Menyiapkan pemeriksaan',
        message: 'Memuat aset aktif yang sedang dikembalikan.',
      );
    }

    if (state.status == ReturnConditionStatus.failure ||
        state.request == null) {
      return LabFlowConnectionErrorState(
        title: 'Pemeriksaan kondisi tidak tersedia',
        message: state.errorMessage.isEmpty
            ? 'Data pemeriksaan tidak dapat dimuat.'
            : state.errorMessage,
      );
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  Icon(Icons.fact_check_outlined, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nilai kondisi setiap aset. Stok hanya dikembalikan '
                      'untuk barang yang dinyatakan Baik.',
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
            if (state.borrowingsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...state.borrowings.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == state.borrowings.length - 1 ? 0 : 14,
                  ),
                  child: _conditionCard(context, state, entry.value),
                ),
              ),
            if (state.validationMessage != null &&
                !state.borrowingsLoading) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
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
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: state.canSubmit
                    ? context.read<ReturnConditionCubit>().submit
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
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Selesaikan Pengembalian',
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

  Widget _conditionCard(
    BuildContext context,
    ReturnConditionState state,
    PickupBorrowing borrowing,
  ) {
    final selected = state.conditionByBorrowing[borrowing.id];

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
                    const SizedBox(height: 3),
                    Text(
                      '${borrowing.assetCode} · Jumlah ${borrowing.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Kondisi saat kembali',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF5F6672),
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReturnCondition.values
                .map((condition) {
                  final isSelected = selected == condition;

                  return ChoiceChip(
                    label: Text(condition.label),
                    selected: isSelected,
                    onSelected: state.isProcessing
                        ? null
                        : (_) {
                            context.read<ReturnConditionCubit>().setCondition(
                              borrowing.id,
                              condition,
                            );
                          },
                    selectedColor: const Color(0xFFB9F33D),
                    backgroundColor: const Color(0xFFF6F9EF),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFB9F33D)
                          : const Color(0xFFDDE2D5),
                    ),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF111111)
                          : const Color(0xFF5F6672),
                    ),
                  );
                })
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: ValueKey('return-note-${borrowing.id}'),
            initialValue: state.noteByBorrowing[borrowing.id] ?? '',
            enabled: !state.isProcessing,
            maxLines: 3,
            onChanged: (value) {
              context.read<ReturnConditionCubit>().setNote(borrowing.id, value);
            },
            decoration: InputDecoration(
              labelText: 'Catatan kondisi (opsional)',
              hintText: selected == ReturnCondition.good
                  ? 'Contoh: kondisi lengkap dan normal.'
                  : 'Jelaskan kerusakan/kehilangan bila diperlukan.',
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
          ),
        ],
      ),
    );
  }
}
