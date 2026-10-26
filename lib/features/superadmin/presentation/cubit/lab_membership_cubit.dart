import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/user_profile.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/activity_log_service.dart';

sealed class LabMembershipState {
  const LabMembershipState();
}

final class LabMembershipLoading extends LabMembershipState {
  const LabMembershipLoading();
}

final class LabMembershipFailure extends LabMembershipState {
  const LabMembershipFailure(this.message);

  final String message;
}

final class LabMembershipLoaded extends LabMembershipState {
  const LabMembershipLoaded({
    required this.admins,
    required this.laboratories,
    required this.memberships,
    this.isMutating = false,
  });

  final List<UserProfile> admins;
  final List<Laboratory> laboratories;
  final List<LabMembership> memberships;
  final bool isMutating;
}

/// Mengelola tiga stream membership dan mutation assignment pada satu halaman.
class LabMembershipCubit extends Cubit<LabMembershipState> {
  LabMembershipCubit(this._service, this._activityLogService)
    : super(const LabMembershipLoading());

  final LabMembershipService _service;
  final ActivityLogService _activityLogService;
  StreamSubscription<List<UserProfile>>? _adminsSubscription;
  StreamSubscription<List<Laboratory>>? _labsSubscription;
  StreamSubscription<List<LabMembership>>? _membershipsSubscription;
  List<UserProfile>? _admins;
  List<Laboratory>? _labs;
  List<LabMembership>? _memberships;
  String? _errorMessage;
  bool _isMutating = false;

  void start() {
    if (_adminsSubscription != null ||
        _labsSubscription != null ||
        _membershipsSubscription != null) {
      return;
    }

    _adminsSubscription = _service.watchLabAdmins().listen(
      (value) {
        _admins = List.unmodifiable(value);
        _emitIfReady();
      },
      onError: (Object _) =>
          _fail('Daftar akun Lab Admin tidak dapat diambil saat ini.'),
    );
    _labsSubscription = _service.watchActiveLaboratories().listen(
      (value) {
        _labs = List.unmodifiable(value);
        _emitIfReady();
      },
      onError: (Object _) =>
          _fail('Daftar laboratorium tidak dapat diambil saat ini.'),
    );
    _membershipsSubscription = _service.watchMemberships().listen(
      (value) {
        _memberships = List.unmodifiable(value);
        _emitIfReady();
      },
      onError: (Object _) =>
          _fail('Data assignment laboratorium tidak dapat diambil saat ini.'),
    );
  }

  Future<bool> assign({required String userId, required String labId}) async {
    final current = _loadedState;
    if (current == null || _isMutating) return false;
    _isMutating = true;
    emit(_copyWithMutation(current));
    try {
      await _service.assignLabAdmin(userId: userId, labId: labId);
      return await _activityLogService.logMembershipAssigned(
        userId: userId,
        labId: labId,
      );
    } finally {
      _isMutating = false;
      _emitIfReady();
    }
  }

  Future<bool> deactivate({
    required String membershipId,
    required String userId,
    required String labId,
  }) async {
    final current = _loadedState;
    if (current == null || _isMutating) return false;
    _isMutating = true;
    emit(_copyWithMutation(current));
    try {
      await _service.deactivateMembership(membershipId);
      return await _activityLogService.logMembershipRevoked(
        userId: userId,
        labId: labId,
      );
    } finally {
      _isMutating = false;
      _emitIfReady();
    }
  }

  LabMembershipLoaded? get _loadedState {
    final admins = _admins;
    final laboratories = _labs;
    final memberships = _memberships;
    if (admins == null || laboratories == null || memberships == null) {
      return null;
    }
    return LabMembershipLoaded(
      admins: admins,
      laboratories: laboratories,
      memberships: memberships,
      isMutating: _isMutating,
    );
  }

  void _emitIfReady() {
    final loaded = _loadedState;
    if (_errorMessage == null && loaded != null) emit(loaded);
  }

  void _fail(String message) {
    _errorMessage = message;
    emit(LabMembershipFailure(message));
  }

  LabMembershipLoaded _copyWithMutation(LabMembershipLoaded state) =>
      LabMembershipLoaded(
        admins: state.admins,
        laboratories: state.laboratories,
        memberships: state.memberships,
        isMutating: _isMutating,
      );

  @override
  Future<void> close() async {
    await _adminsSubscription?.cancel();
    await _labsSubscription?.cancel();
    await _membershipsSubscription?.cancel();
    return super.close();
  }
}
