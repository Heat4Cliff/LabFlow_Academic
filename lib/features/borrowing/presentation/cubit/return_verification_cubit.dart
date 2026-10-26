import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/borrow_request_service.dart';
import '../../data/return_verification_service.dart';
import '../../domain/pickup_borrowing.dart';
import 'return_verification_state.dart';

class ReturnVerificationCubit extends Cubit<ReturnVerificationState> {
  ReturnVerificationCubit(
    this._borrowRequestService,
    this._returnVerificationService,
  ) : super(const ReturnVerificationState());

  final BorrowRequestService _borrowRequestService;
  final ReturnVerificationService _returnVerificationService;

  StreamSubscription<List<PickupBorrowing>>? _borrowingSubscription;
  String? _requestId;

  Future<void> load(String requestId) async {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      emit(
        const ReturnVerificationState(
          status: ReturnVerificationStatus.failure,
          errorMessage: 'ID permintaan peminjaman tidak valid.',
        ),
      );
      return;
    }

    _requestId = cleanId;

    emit(
      const ReturnVerificationState(status: ReturnVerificationStatus.loading),
    );

    try {
      final request = await _borrowRequestService.getRequest(cleanId);

      if (request.status != 'active') {
        emit(
          ReturnVerificationState(
            status: ReturnVerificationStatus.failure,
            request: request,
            errorMessage: request.status == 'returned'
                ? 'Peminjaman ini sudah selesai dikembalikan.'
                : 'Peminjaman belum berada pada status aktif.',
          ),
        );
        return;
      }

      emit(
        ReturnVerificationState(
          status: ReturnVerificationStatus.loaded,
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

              emit(
                state.copyWith(
                  status: ReturnVerificationStatus.loaded,
                  borrowings: borrowings,
                  borrowingsLoading: false,
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
                  status: ReturnVerificationStatus.failure,
                  borrowingsLoading: false,
                  errorMessage:
                      'Data aset aktif tidak dapat dimuat untuk pengembalian.',
                ),
              );
            },
          );
    } on BorrowRequestException catch (error) {
      emit(
        ReturnVerificationState(
          status: ReturnVerificationStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const ReturnVerificationState(
          status: ReturnVerificationStatus.failure,
          errorMessage: 'Data pengembalian tidak dapat dimuat.',
        ),
      );
    }
  }

  void setStudentChecked(bool value) {
    emit(state.copyWith(studentChecked: value));
  }

  void setQuantityChecked(bool value) {
    emit(state.copyWith(quantityChecked: value));
  }

  void setAssetsReceivedChecked(bool value) {
    emit(state.copyWith(assetsReceivedChecked: value));
  }

  @override
  Future<void> close() async {
    await _borrowingSubscription?.cancel();
    return super.close();
  }
}
