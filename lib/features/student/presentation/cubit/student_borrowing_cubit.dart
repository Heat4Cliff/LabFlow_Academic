import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_service.dart';
import 'student_borrowing_state.dart';
import 'student_data_state.dart';

class StudentBorrowingCubit extends Cubit<StudentBorrowingState> {
  StudentBorrowingCubit(this._service) : super(const StudentBorrowingState());

  final StudentService _service;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      final requests = await _service.loadBorrowRequests();

      emit(
        state.copyWith(
          status: StudentLoadStatus.success,
          requests: requests,
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StudentLoadStatus.failure,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Peminjaman tidak dapat dimuat.',
        ),
      );
    }
  }

  Future<void> cancel(String requestId) async {
    if (state.cancellingIds.contains(requestId)) {
      return;
    }

    emit(
      state.copyWith(
        cancellingIds: {...state.cancellingIds, requestId},
        errorMessage: '',
        actionMessage: '',
      ),
    );

    try {
      await _service.cancelBorrowRequest(requestId);

      final requests = await _service.loadBorrowRequests();

      emit(
        state.copyWith(
          status: StudentLoadStatus.success,
          requests: requests,
          cancellingIds: {...state.cancellingIds}..remove(requestId),
          actionMessage: 'Pengajuan berhasil dibatalkan.',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          cancellingIds: {...state.cancellingIds}..remove(requestId),
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Pengajuan tidak dapat dibatalkan.',
        ),
      );
    }
  }

  void clearFeedback() {
    emit(state.copyWith(errorMessage: '', actionMessage: ''));
  }
}
