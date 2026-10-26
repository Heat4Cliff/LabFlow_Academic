import '../../domain/lab_admin_profile.dart';

enum LabAdminProfileStatus { initial, loading, loaded, failure }

enum LabAdminProfileActionStatus { idle, signedOut, failure }

class LabAdminProfileState {
  const LabAdminProfileState({
    this.status = LabAdminProfileStatus.initial,
    this.profile,
    this.isSigningOut = false,
    this.errorMessage = '',
    this.actionStatus = LabAdminProfileActionStatus.idle,
    this.actionMessage = '',
  });

  final LabAdminProfileStatus status;
  final LabAdminProfile? profile;
  final bool isSigningOut;
  final String errorMessage;
  final LabAdminProfileActionStatus actionStatus;
  final String actionMessage;

  LabAdminProfileState copyWith({
    LabAdminProfileStatus? status,
    LabAdminProfile? profile,
    bool? isSigningOut,
    String? errorMessage,
    LabAdminProfileActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return LabAdminProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      isSigningOut: isSigningOut ?? this.isSigningOut,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
