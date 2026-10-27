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
      var borrowDate = DateTime(today.year, today.month, today.day);
      var returnDate = borrowDate.add(const Duration(days: 1));
      var quantity = 1;
      var purpose = '';
      var note = '';
      final draft = await _service.loadBorrowDraft(assetId);
      if (draft != null) {
        borrowDate = draft.borrowDate;
        returnDate = draft.returnDate;
        quantity = draft.quantity.clamp(1, asset.stock);
        purpose = draft.purpose;
        note = draft.note;
      }

      emit(
        StudentBorrowFormState(
          status: StudentLoadStatus.success,
          asset: asset,
          laboratory: laboratory,
          quantity: quantity,
          borrowDate: borrowDate,
          expectedReturnDate: returnDate,
          purpose: purpose,
          studentNote: note,
          draftSaved: draft != null,
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

    emit(state.copyWith(quantity: next, errorMessage: '', draftSaved: false));
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
        draftSaved: false,
      ),
    );
  }

  void setExpectedReturnDate(DateTime value) {
    emit(
      state.copyWith(
        expectedReturnDate: value,
        errorMessage: '',
        draftSaved: false,
      ),
    );
  }

  void setPurpose(String value) {
    emit(state.copyWith(purpose: value, errorMessage: '', draftSaved: false));
  }

  void setStudentNote(String value) {
    emit(
      state.copyWith(studentNote: value, errorMessage: '', draftSaved: false),
    );
  }

  Future<void> saveDraft() async {
    final asset = state.asset;
    final borrowDate = state.borrowDate;
    final returnDate = state.expectedReturnDate;
    if (asset == null || borrowDate == null || returnDate == null) return;
    try {
      await _service.saveBorrowDraft(
        assetId: asset.id,
        quantity: state.quantity,
        borrowDate: borrowDate,
        returnDate: returnDate,
        purpose: state.purpose,
        note: state.studentNote,
      );
      emit(state.copyWith(draftSaved: true, errorMessage: ''));
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Draft tidak dapat disimpan di perangkat.',
        ),
      );
    }
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
      await _service.removeBorrowDraft(asset.id);

      emit(
        state.copyWith(
          isSubmitting: false,
          step: StudentBorrowFormStep.success,
          result: result,
          draftSaved: false,
          errorMessage: '',
        ),
      );
    } catch (error) {
      var draftSaved = false;
      try {
        await _service.saveBorrowDraft(
          assetId: asset.id,
          quantity: state.quantity,
          borrowDate: borrowDate,
          returnDate: expectedReturnDate,
          purpose: state.purpose,
          note: state.studentNote,
        );
        draftSaved = true;
      } catch (_) {
        // Preserve the submission error if local storage is unavailable.
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          draftSaved: draftSaved,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Pengajuan peminjaman gagal dikirim.',
        ),
      );
    }
  }
}
