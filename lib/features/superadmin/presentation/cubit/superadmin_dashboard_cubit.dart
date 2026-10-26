import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/user_profile.dart';
import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/user_management_service.dart';

sealed class SuperadminDashboardState {
  const SuperadminDashboardState();
}

final class SuperadminDashboardLoading extends SuperadminDashboardState {
  const SuperadminDashboardLoading();
}

final class SuperadminDashboardFailure extends SuperadminDashboardState {
  const SuperadminDashboardFailure(this.message);

  final String message;
}

final class SuperadminDashboardLoaded extends SuperadminDashboardState {
  const SuperadminDashboardLoaded({required this.users, required this.labs});

  final List<UserProfile> users;
  final List<Laboratory> labs;
}

/// Menggabungkan dua stream ringkasan dashboard dan mengelola lifecycle-nya.
class SuperadminDashboardCubit extends Cubit<SuperadminDashboardState> {
  SuperadminDashboardCubit(this._userService, this._laboratoryService)
    : super(const SuperadminDashboardLoading());

  final UserManagementService _userService;
  final LaboratoryService _laboratoryService;
  StreamSubscription<List<UserProfile>>? _usersSubscription;
  StreamSubscription<List<Laboratory>>? _labsSubscription;
  List<UserProfile>? _users;
  List<Laboratory>? _labs;
  String? _errorMessage;

  void start() {
    if (_usersSubscription != null || _labsSubscription != null) return;
    _usersSubscription = _userService.watchUsers().listen(
      (users) {
        _users = List.unmodifiable(users);
        _emitIfReady();
      },
      onError: (Object _) {
        _errorMessage = 'Data pengguna tidak dapat diambil saat ini.';
        emit(SuperadminDashboardFailure(_errorMessage!));
      },
    );
    _labsSubscription = _laboratoryService.watchLaboratories().listen(
      (labs) {
        _labs = List.unmodifiable(labs);
        _emitIfReady();
      },
      onError: (Object _) {
        _errorMessage = 'Data laboratorium tidak dapat diambil saat ini.';
        emit(SuperadminDashboardFailure(_errorMessage!));
      },
    );
  }

  void _emitIfReady() {
    final users = _users;
    final labs = _labs;
    if (_errorMessage == null && users != null && labs != null) {
      emit(SuperadminDashboardLoaded(users: users, labs: labs));
    }
  }

  @override
  Future<void> close() async {
    await _usersSubscription?.cancel();
    await _labsSubscription?.cancel();
    return super.close();
  }
}
