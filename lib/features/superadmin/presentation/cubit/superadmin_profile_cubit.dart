import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/user_profile.dart';

sealed class SuperadminProfileState {
  const SuperadminProfileState();
}

final class SuperadminProfileLoading extends SuperadminProfileState {
  const SuperadminProfileLoading();
}

final class SuperadminProfileFailure extends SuperadminProfileState {
  const SuperadminProfileFailure({this.isSuspended = false});

  final bool isSuspended;
}

final class SuperadminProfileLoaded extends SuperadminProfileState {
  const SuperadminProfileLoaded(this.profile);

  final UserProfile profile;
}

/// Memisahkan pemuatan profil backend dari state dialog dan navigasi halaman.
class SuperadminProfileCubit extends Cubit<SuperadminProfileState> {
  SuperadminProfileCubit(this._authService)
    : super(const SuperadminProfileLoading());

  final AuthService _authService;

  Future<void> load() async {
    emit(const SuperadminProfileLoading());
    try {
      emit(SuperadminProfileLoaded(await _authService.getCurrentUserProfile()));
    } on AuthServiceException catch (error) {
      emit(SuperadminProfileFailure(isSuspended: error.isAccountSuspended));
    } catch (_) {
      emit(const SuperadminProfileFailure());
    }
  }
}
