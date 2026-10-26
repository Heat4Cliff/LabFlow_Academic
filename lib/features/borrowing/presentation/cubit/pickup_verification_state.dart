import '../../domain/borrow_request.dart';
import '../../domain/pickup_borrowing.dart';

enum PickupVerificationStatus { initial, loading, loaded, failure }

enum PickupVerificationActionStatus { idle, success, warning, failure }

class PickupVerificationState {
  const PickupVerificationState({
    this.status = PickupVerificationStatus.initial,
    this.request,
    this.assignments = const <PickupBorrowing>[],
    this.assignmentsLoading = false,
    this.studentIdentityChecked = false,
    this.assetMatchChecked = false,
    this.handoverChecked = false,
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = PickupVerificationActionStatus.idle,
    this.actionMessage = '',
  });

  final PickupVerificationStatus status;
  final BorrowRequest? request;
  final List<PickupBorrowing> assignments;
  final bool assignmentsLoading;

  /// Lab Admin sudah mencocokkan identitas mahasiswa.
  final bool studentIdentityChecked;

  /// Lab Admin sudah mencocokkan aset fisik dengan aset yang dialokasikan.
  final bool assetMatchChecked;

  /// Lab Admin memastikan barang benar-benar diserahkan.
  final bool handoverChecked;

  final bool isProcessing;
  final String errorMessage;
  final PickupVerificationActionStatus actionStatus;
  final String actionMessage;

  bool get verificationComplete =>
      studentIdentityChecked && assetMatchChecked && handoverChecked;

  bool get canConfirm =>
      status == PickupVerificationStatus.loaded &&
      !assignmentsLoading &&
      assignments.isNotEmpty &&
      verificationComplete &&
      !isProcessing;

  PickupVerificationState copyWith({
    PickupVerificationStatus? status,
    BorrowRequest? request,
    List<PickupBorrowing>? assignments,
    bool? assignmentsLoading,
    bool? studentIdentityChecked,
    bool? assetMatchChecked,
    bool? handoverChecked,
    bool? isProcessing,
    String? errorMessage,
    PickupVerificationActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return PickupVerificationState(
      status: status ?? this.status,
      request: request ?? this.request,
      assignments: assignments ?? this.assignments,
      assignmentsLoading: assignmentsLoading ?? this.assignmentsLoading,
      studentIdentityChecked:
          studentIdentityChecked ?? this.studentIdentityChecked,
      assetMatchChecked: assetMatchChecked ?? this.assetMatchChecked,
      handoverChecked: handoverChecked ?? this.handoverChecked,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
