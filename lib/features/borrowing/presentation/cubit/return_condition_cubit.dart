import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/borrow_request_service.dart';
import '../../data/return_verification_service.dart';
import '../../domain/pickup_borrowing.dart';
import '../../domain/return_inspection.dart';
import 'return_condition_state.dart';

class ReturnConditionCubit extends Cubit<ReturnConditionState> {
  ReturnConditionCubit(
    this._borrowRequestService,
    this._returnVerificationService,
  ) : super(const ReturnConditionState());

  final BorrowRequestService _borrowRequestService;
  final ReturnVerificationService _returnVerificationService;

  StreamSubscription<List<PickupBorrowing>>? _borrowingSubscription;
  String? _requestId;

  Future<void> load(String requestId) async {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      emit(
        const ReturnConditionState(
          status: ReturnConditionStatus.failure,
          errorMessage: 'ID permintaan peminjaman tidak valid.',
        ),
      );
      return;
    }

    _requestId = cleanId;

    emit(const ReturnConditionState(status: ReturnConditionStatus.loading));

    try {
      final request = await _borrowRequestService.getRequest(cleanId);

      if (request.status != 'active') {
        emit(
          ReturnConditionState(
            status: ReturnConditionStatus.failure,
            request: request,
            errorMessage: request.status == 'returned'
                ? 'Peminjaman ini sudah selesai dikembalikan.'
                : 'Pemeriksaan kondisi hanya tersedia untuk peminjaman aktif.',
          ),
        );
        return;
      }

      emit(
        ReturnConditionState(
          status: ReturnConditionStatus.loaded,
          request: request,
          borrowingsLoading: true,
        ),
      );

      await _borrowingSubscription?.cancel();

      _borrowingSubscription = _returnVerificationService
          .watchActiveBorrowings(
            requestId: request.id,
            laboratoryId: request.labId,
          )
          .listen(
            (borrowings) {
              if (_requestId != cleanId) {
                return;
              }

              final validIds = borrowings.map((item) => item.id).toSet();
              final conditions = Map<String, ReturnCondition>.from(
                state.conditionByBorrowing,
              )..removeWhere((id, _) => !validIds.contains(id));
              final notes = Map<String, String>.from(state.noteByBorrowing)
                ..removeWhere((id, _) => !validIds.contains(id));

              emit(
                state.copyWith(
                  status: ReturnConditionStatus.loaded,
                  borrowings: borrowings,
                  borrowingsLoading: false,
                  conditionByBorrowing: conditions,
                  noteByBorrowing: notes,
                  errorMessage: '',
                ),
              );
            },
            onError: (_) {
              if (_requestId != cleanId) {
                return;
              }

              emit(
                state.copyWith(
                  status: ReturnConditionStatus.failure,
                  borrowingsLoading: false,
                  errorMessage:
                      'Data aset aktif tidak dapat dimuat untuk pemeriksaan.',
                ),
              );
            },
          );
    } on BorrowRequestException catch (error) {
      emit(
        ReturnConditionState(
          status: ReturnConditionStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const ReturnConditionState(
          status: ReturnConditionStatus.failure,
          errorMessage: 'Data pemeriksaan kondisi tidak dapat dimuat.',
        ),
      );
    }
  }

  void setCondition(String borrowingId, ReturnCondition condition) {
    if (state.isProcessing) {
      return;
    }

    final values = Map<String, ReturnCondition>.from(
      state.conditionByBorrowing,
    );
    values[borrowingId] = condition;

    emit(
      state.copyWith(
        conditionByBorrowing: values,
        actionStatus: ReturnConditionActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void setNote(String borrowingId, String value) {
    if (state.isProcessing) {
      return;
    }

    final notes = Map<String, String>.from(state.noteByBorrowing);
    notes[borrowingId] = value;

    emit(state.copyWith(noteByBorrowing: notes));
  }

  Future<void> submit() async {
    final request = state.request;

    if (request == null || state.isProcessing) {
      return;
    }

    final validationMessage = state.validationMessage;

    if (validationMessage != null) {
      emit(
        state.copyWith(
          actionStatus: ReturnConditionActionStatus.warning,
          actionMessage: validationMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: ReturnConditionActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _returnVerificationService.completeReturn(
        requestId: request.id,
        laboratoryId: request.labId,
        conditionByBorrowing: state.conditionByBorrowing,
        noteByBorrowing: state.noteByBorrowing,
      );

      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: ReturnConditionActionStatus.success,
          actionMessage:
              'Pengembalian selesai dan kondisi aset telah disimpan.',
        ),
      );
    } on ReturnVerificationException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: ReturnConditionActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: ReturnConditionActionStatus.failure,
          actionMessage:
              'Pengembalian gagal diproses. Periksa koneksi lalu coba lagi.',
        ),
      );
    }
  }

  void clearActionFeedback() {
    emit(
      state.copyWith(
        actionStatus: ReturnConditionActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _borrowingSubscription?.cancel();
    return super.close();
  }
}
