import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/activity_log_service.dart';
import '../../data/user_management_service.dart';

/// Mengelola status submit dan mendelegasikan perubahan ke service Superadmin.
class UserManagementActionCubit extends Cubit<bool> {
  UserManagementActionCubit(this._users, this._activityLog) : super(false);

  final UserManagementService _users;
  final ActivityLogService _activityLog;

  Future<UserProfile> getUser(String userId) => _users.getUser(userId);

  Future<void> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String status,
  }) => _run(() async {
    await _users.createUser(
      fullName: fullName,
      email: email,
      password: password,
      role: role,
      status: status,
    );
    await _activityLog.logUserCreated(
      fullName: fullName,
      email: email,
      role: role,
    );
  });

  Future<void> updateUser({
    required String userId,
    required String fullName,
    required String role,
    required String status,
    required String originalFullName,
    required String originalRole,
    required String email,
  }) => _run(() async {
    await _users.updateUser(
      userId: userId,
      fullName: fullName,
      role: role,
      status: status,
    );
    if (originalFullName.trim() != fullName.trim()) {
      await _activityLog.logUserUpdated(fullName: fullName, email: email);
    }
    if (originalRole != role) {
      await _activityLog.logUserRoleChanged(
        fullName: fullName,
        email: email,
        oldRole: originalRole,
        newRole: role,
      );
    }
  });

  Future<void> setUserStatus({
    required String userId,
    required String fullName,
    required String email,
    required bool suspend,
  }) => _run(() async {
    if (suspend) {
      await _users.suspendUser(userId);
      await _activityLog.logUserSuspended(fullName: fullName, email: email);
    } else {
      await _users.activateUser(userId);
      await _activityLog.logUserActivated(fullName: fullName, email: email);
    }
  });

  Future<void> _run(Future<void> Function() operation) async {
    if (state) return;
    emit(true);
    try {
      await operation();
    } finally {
      emit(false);
    }
  }
}
