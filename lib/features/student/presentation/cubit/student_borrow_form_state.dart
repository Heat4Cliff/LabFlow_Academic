import '../../domain/student_models.dart';
import 'student_data_state.dart';

enum StudentBorrowFormStep { form, review, success }

class StudentBorrowFormState {
  const StudentBorrowFormState({
    this.status = StudentLoadStatus.initial,
    this.asset,
    this.laboratory,
    this.quantity = 1,
    this.borrowDate,
    this.expectedReturnDate,
    this.purpose = '',
    this.studentNote = '',
    this.step = StudentBorrowFormStep.form,
    this.isSubmitting = false,
    this.errorMessage = '',
    this.result,
    this.draftSaved = false,
  });

  final StudentLoadStatus status;
  final StudentAsset? asset;
  final StudentLaboratory? laboratory;
  final int quantity;
  final DateTime? borrowDate;
  final DateTime? expectedReturnDate;
  final String purpose;
  final String studentNote;
  final StudentBorrowFormStep step;
  final bool isSubmitting;
  final String errorMessage;
  final StudentBorrowSubmissionResult? result;
  final bool draftSaved;

  bool get canReview {
    final selectedAsset = asset;

    return selectedAsset != null &&
        selectedAsset.isAvailable &&
        quantity >= 1 &&
        quantity <= selectedAsset.stock &&
        borrowDate != null &&
        expectedReturnDate != null &&
        !expectedReturnDate!.isBefore(borrowDate!) &&
        purpose.trim().length >= 3;
  }

  StudentBorrowFormState copyWith({
    StudentLoadStatus? status,
    StudentAsset? asset,
    StudentLaboratory? laboratory,
    int? quantity,
    DateTime? borrowDate,
    DateTime? expectedReturnDate,
    String? purpose,
    String? studentNote,
    StudentBorrowFormStep? step,
    bool? isSubmitting,
    String? errorMessage,
    StudentBorrowSubmissionResult? result,
    bool? draftSaved,
  }) {
    return StudentBorrowFormState(
      status: status ?? this.status,
      asset: asset ?? this.asset,
      laboratory: laboratory ?? this.laboratory,
      quantity: quantity ?? this.quantity,
      borrowDate: borrowDate ?? this.borrowDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      purpose: purpose ?? this.purpose,
      studentNote: studentNote ?? this.studentNote,
      step: step ?? this.step,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      draftSaved: draftSaved ?? this.draftSaved,
    );
  }
}
