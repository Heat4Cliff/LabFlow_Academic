import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/borrow_request_service.dart';
import '../../data/pickup_verification_service.dart';
import '../../domain/pickup_borrowing.dart';
import 'pickup_verification_state.dart';

class PickupVerificationCubit extends Cubit<PickupVerificationState> {
  PickupVerificationCubit(
    this._borrowRequestService,
    this._pickupVerificationService,
  ) : super(const PickupVerificationState());

  final BorrowRequestService _borrowRequestService;
  final PickupVerificationService _pickupVerificationService;

  StreamSubscription<List<PickupBorrowing>>? _assignmentSubscription;
  String? _requestId;

  Future<void> load(String requestId) async {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      emit(
        const PickupVerificationState(
          status: PickupVerificationStatus.failure,
          errorMessage: 'ID permintaan peminjaman tidak valid.',
        ),
      );
      return;
    }

    _requestId = cleanId;

    emit(
      const PickupVerificationState(status: PickupVerificationStatus.loading),
    );

    try {
      final request = await _borrowRequestService.getRequest(cleanId);

      if (request.status != 'waiting_pickup') {
        emit(
          PickupVerificationState(
            status: PickupVerificationStatus.failure,
            request: request,
            errorMessage: request.status == 'active'
                ? 'Pengambilan untuk request ini sudah diverifikasi.'
                : 'Request belum berada pada tahap verifikasi pengambilan.',
          ),
        );
        return;
      }

      emit(
        PickupVerificationState(
          status: PickupVerificationStatus.loaded,
          request: request,
          assignmentsLoading: true,
        ),
      );

      await _assignmentSubscription?.cancel();

      _assignmentSubscription = _pickupVerificationService
          .watchAssignments(requestId: request.id, laboratoryId: request.labId)
          .listen(
            (assignments) {
              if (_requestId != cleanId) {
                return;
              }

              emit(
                state.copyWith(
                  status: PickupVerificationStatus.loaded,
                  assignments: assignments,
                  assignmentsLoading: false,
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
                  status: PickupVerificationStatus.failure,
                  assignmentsLoading: false,
                  errorMessage: 'Data aset yang ditugaskan tidak dapat dimuat.',
                ),
              );
            },
          );
    } on BorrowRequestException catch (error) {
      emit(
        PickupVerificationState(
          status: PickupVerificationStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const PickupVerificationState(
          status: PickupVerificationStatus.failure,
          errorMessage: 'Data verifikasi pengambilan tidak dapat dimuat.',
        ),
      );
    }
  }

  void setStudentIdentityChecked(bool value) {
    if (state.isProcessing) {
      return;
    }

    emit(
      state.copyWith(
        studentIdentityChecked: value,
        actionStatus: PickupVerificationActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void setAssetMatchChecked(bool value) {
    if (state.isProcessing) {
      return;
    }

    emit(
      state.copyWith(
        assetMatchChecked: value,
        actionStatus: PickupVerificationActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void setHandoverChecked(bool value) {
    if (state.isProcessing) {
      return;
    }

    emit(
      state.copyWith(
        handoverChecked: value,
        actionStatus: PickupVerificationActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  Future<void> confirmPickup() async {
    final request = state.request;

    if (request == null || state.isProcessing) {
      return;
    }

    if (state.assignments.isEmpty) {
      emit(
        state.copyWith(
          actionStatus: PickupVerificationActionStatus.warning,
          actionMessage:
              'Belum ada aset yang dapat diverifikasi untuk request ini.',
        ),
      );
      return;
    }

    if (!state.verificationComplete) {
      emit(
        state.copyWith(
          actionStatus: PickupVerificationActionStatus.warning,
          actionMessage:
              'Selesaikan seluruh checklist sebelum mengonfirmasi pengambilan.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: PickupVerificationActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _pickupVerificationService.confirmPickup(
        requestId: request.id,
        laboratoryId: request.labId,
      );

      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: PickupVerificationActionStatus.success,
          actionMessage:
              'Pengambilan terverifikasi. Peminjaman sekarang aktif.',
        ),
      );
    } on PickupVerificationException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: PickupVerificationActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: PickupVerificationActionStatus.failure,
          actionMessage:
              'Verifikasi pengambilan gagal. Periksa koneksi lalu coba lagi.',
        ),
      );
    }
  }

  void clearActionFeedback() {
    emit(
      state.copyWith(
        actionStatus: PickupVerificationActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _assignmentSubscription?.cancel();
    return super.close();
  }
}
