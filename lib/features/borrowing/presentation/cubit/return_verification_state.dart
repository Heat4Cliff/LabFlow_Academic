import '../../domain/borrow_request.dart';
import '../../domain/pickup_borrowing.dart';

enum ReturnVerificationStatus { initial, loading, loaded, failure }

class ReturnVerificationState {
  const ReturnVerificationState({
    this.status = ReturnVerificationStatus.initial,
    this.request,
    this.borrowings = const <PickupBorrowing>[],
    this.borrowingsLoading = false,
    this.studentChecked = false,
    this.quantityChecked = false,
    this.assetsReceivedChecked = false,
    this.errorMessage = '',
  });

  final ReturnVerificationStatus status;
  final BorrowRequest? request;
  final List<PickupBorrowing> borrowings;
  final bool borrowingsLoading;
  final bool studentChecked;
  final bool quantityChecked;
  final bool assetsReceivedChecked;
  final String errorMessage;

  bool get checklistComplete =>
      studentChecked && quantityChecked && assetsReceivedChecked;

  bool get canContinue =>
      status == ReturnVerificationStatus.loaded &&
      !borrowingsLoading &&
      borrowings.isNotEmpty &&
      checklistComplete;

  ReturnVerificationState copyWith({
    ReturnVerificationStatus? status,
    BorrowRequest? request,
    List<PickupBorrowing>? borrowings,
    bool? borrowingsLoading,
    bool? studentChecked,
    bool? quantityChecked,
    bool? assetsReceivedChecked,
    String? errorMessage,
  }) {
    return ReturnVerificationState(
      status: status ?? this.status,
      request: request ?? this.request,
      borrowings: borrowings ?? this.borrowings,
      borrowingsLoading: borrowingsLoading ?? this.borrowingsLoading,
      studentChecked: studentChecked ?? this.studentChecked,
      quantityChecked: quantityChecked ?? this.quantityChecked,
      assetsReceivedChecked:
          assetsReceivedChecked ?? this.assetsReceivedChecked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
