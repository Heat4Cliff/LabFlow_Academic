import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/user_management_service.dart';

sealed class UserDetailState {
  const UserDetailState();
}

final class UserDetailLoading extends UserDetailState {
  const UserDetailLoading();
}

final class UserDetailFailure extends UserDetailState {
  const UserDetailFailure();
}

final class UserDetailLoaded extends UserDetailState {
  const UserDetailLoaded(this.profile);

  final UserProfile profile;
}

/// Memuat satu profil untuk form edit melalui UserManagementService.
class UserDetailCubit extends Cubit<UserDetailState> {
  UserDetailCubit(this._service) : super(const UserDetailLoading());

  final UserManagementService _service;

  Future<void> load(String userId) async {
    emit(const UserDetailLoading());
    try {
      emit(UserDetailLoaded(await _service.getUser(userId)));
    } catch (_) {
      emit(const UserDetailFailure());
    }
  }
}
