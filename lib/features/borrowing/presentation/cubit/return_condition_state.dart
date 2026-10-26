import '../../domain/borrow_request.dart';
import '../../domain/pickup_borrowing.dart';
import '../../domain/return_inspection.dart';

enum ReturnConditionStatus { initial, loading, loaded, failure }

enum ReturnConditionActionStatus { idle, success, warning, failure }

class ReturnConditionState {
  const ReturnConditionState({
    this.status = ReturnConditionStatus.initial,
    this.request,
    this.borrowings = const <PickupBorrowing>[],
    this.borrowingsLoading = false,
    this.conditionByBorrowing = const <String, ReturnCondition>{},
    this.noteByBorrowing = const <String, String>{},
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = ReturnConditionActionStatus.idle,
    this.actionMessage = '',
  });

  final ReturnConditionStatus status;
  final BorrowRequest? request;
  final List<PickupBorrowing> borrowings;
  final bool borrowingsLoading;
  final Map<String, ReturnCondition> conditionByBorrowing;
  final Map<String, String> noteByBorrowing;
  final bool isProcessing;
  final String errorMessage;
  final ReturnConditionActionStatus actionStatus;
  final String actionMessage;

  String? get validationMessage {
    if (borrowingsLoading) {
      return 'Data aset masih dimuat.';
    }

    if (borrowings.isEmpty) {
      return 'Tidak ada aset aktif yang dapat diperiksa.';
    }

    for (final borrowing in borrowings) {
      if (!conditionByBorrowing.containsKey(borrowing.id)) {
        return 'Pilih kondisi untuk seluruh aset.';
      }
    }

    return null;
  }

  bool get canSubmit =>
      status == ReturnConditionStatus.loaded &&
      !isProcessing &&
      validationMessage == null;

  ReturnConditionState copyWith({
    ReturnConditionStatus? status,
    BorrowRequest? request,
    List<PickupBorrowing>? borrowings,
    bool? borrowingsLoading,
    Map<String, ReturnCondition>? conditionByBorrowing,
    Map<String, String>? noteByBorrowing,
    bool? isProcessing,
    String? errorMessage,
    ReturnConditionActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return ReturnConditionState(
      status: status ?? this.status,
      request: request ?? this.request,
      borrowings: borrowings ?? this.borrowings,
      borrowingsLoading: borrowingsLoading ?? this.borrowingsLoading,
      conditionByBorrowing: conditionByBorrowing ?? this.conditionByBorrowing,
      noteByBorrowing: noteByBorrowing ?? this.noteByBorrowing,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
