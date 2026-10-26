import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import 'student_borrow_form_state.dart';
import 'student_data_state.dart';

class StudentBorrowFormCubit extends Cubit<StudentBorrowFormState> {
  StudentBorrowFormCubit(this._service, {required this.assetId})
    : super(const StudentBorrowFormState());

  final StudentService _service;
  final String assetId;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      final results = await Future.wait<dynamic>([
        _service.loadAsset(assetId),
        _service.loadActiveLaboratories(),
      ]);

      final asset = results[0] as StudentAsset;
      final laboratories = results[1] as List<StudentLaboratory>;

      StudentLaboratory? laboratory;
      for (final candidate in laboratories) {
        if (candidate.id == asset.labId) {
          laboratory = candidate;
          break;
        }
      }

      if (laboratory == null) {
        throw const StudentServiceException(
          'Laboratorium aset sedang tidak aktif.',
        );
      }

      final today = DateTime.now();
      final borrowDate = DateTime(today.year, today.month, today.day);
      final returnDate = borrowDate.add(const Duration(days: 1));

      emit(
        StudentBorrowFormState(
          status: StudentLoadStatus.success,
          asset: asset,
          laboratory: laboratory,
          quantity: 1,
          borrowDate: borrowDate,
          expectedReturnDate: returnDate,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StudentLoadStatus.failure,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Form peminjaman tidak dapat dimuat.',
        ),
      );
    }
  }

  void setQuantity(int value) {
    final stock = state.asset?.stock ?? 1;
    final next = value.clamp(1, stock);

    emit(state.copyWith(quantity: next, errorMessage: ''));
  }

  void setBorrowDate(DateTime value) {
    var returnDate = state.expectedReturnDate;

    if (returnDate == null || returnDate.isBefore(value)) {
      returnDate = value.add(const Duration(days: 1));
    }

    emit(
      state.copyWith(
        borrowDate: value,
        expectedReturnDate: returnDate,
        errorMessage: '',
      ),
    );
  }

  void setExpectedReturnDate(DateTime value) {
    emit(state.copyWith(expectedReturnDate: value, errorMessage: ''));
  }

  void setPurpose(String value) {
    emit(state.copyWith(purpose: value, errorMessage: ''));
  }

  void setStudentNote(String value) {
    emit(state.copyWith(studentNote: value, errorMessage: ''));
  }

  void review() {
    if (!state.canReview) {
      emit(
        state.copyWith(
          errorMessage: 'Lengkapi jumlah, tanggal, dan tujuan peminjaman terlebih dahulu.',
        ),
      );
      return;
    }

    emit(state.copyWith(step: StudentBorrowFormStep.review, errorMessage: ''));
  }

  void edit() {
    if (state.isSubmitting) return;

    emit(state.copyWith(step: StudentBorrowFormStep.form, errorMessage: ''));
  }

  Future<void> submit() async {
    final asset = state.asset;
    final borrowDate = state.borrowDate;
    final expectedReturnDate = state.expectedReturnDate;

    if (asset == null ||
        borrowDate == null ||
        expectedReturnDate == null ||
        !state.canReview ||
        state.isSubmitting) {
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: ''));

    try {
      final result = await _service.createBorrowRequest(
        asset: asset,
        quantity: state.quantity,
        borrowDate: borrowDate,
        expectedReturnDate: expectedReturnDate,
        purpose: state.purpose,
        studentNote: state.studentNote,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          step: StudentBorrowFormStep.success,
          result: result,
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Pengajuan peminjaman gagal dikirim.',
        ),
      );
    }
  }
}
