import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/user_management_service.dart';

/// State daftar pengguna beserta pencarian dan filter yang dipakai halaman.
sealed class UserDirectoryState {
  const UserDirectoryState();
}

final class UserDirectoryLoading extends UserDirectoryState {
  const UserDirectoryLoading();
}

final class UserDirectoryFailure extends UserDirectoryState {
  const UserDirectoryFailure();
}

final class UserDirectoryLoaded extends UserDirectoryState {
  const UserDirectoryLoaded({
    required this.users,
    required this.query,
    required this.role,
    required this.status,
  });

  final List<UserProfile> users;
  final String query;
  final String role;
  final String status;

  List<UserProfile> get visibleUsers => users
      .where((user) {
        final normalizedQuery = query.trim().toLowerCase();
        final matchesQuery =
            normalizedQuery.isEmpty ||
            user.fullName.toLowerCase().contains(normalizedQuery) ||
            user.email.toLowerCase().contains(normalizedQuery);
        final matchesRole = role == 'all' || user.role == role;
        final matchesStatus = status == 'all' || user.status == status;
        return matchesQuery && matchesRole && matchesStatus;
      })
      .toList(growable: false);
}

/// Mengelola satu langganan direktori pengguna dan filter halaman.
class UserDirectoryCubit extends Cubit<UserDirectoryState> {
  UserDirectoryCubit(this._service) : super(const UserDirectoryLoading());

  final UserManagementService _service;
  StreamSubscription<List<UserProfile>>? _subscription;
  List<UserProfile> _users = const [];
  String _query = '';
  String _role = 'all';
  String _status = 'all';

  void start() {
    if (_subscription != null) return;
    _subscription = _service.watchUsers().listen((users) {
      _users = List.unmodifiable(users);
      _emitLoaded();
    }, onError: (Object _) => emit(const UserDirectoryFailure()));
  }

  void setQuery(String value) {
    _query = value;
    _emitLoaded();
  }

  void setRole(String value) {
    _role = value;
    _emitLoaded();
  }

  void setStatus(String value) {
    _status = value;
    _emitLoaded();
  }

  void _emitLoaded() {
    emit(
      UserDirectoryLoaded(
        users: _users,
        query: _query,
        role: _role,
        status: _status,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
