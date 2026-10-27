import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/profile_edit_service.dart';

enum ProfileEditStatus { loading, editing, saving, success, failure }

class ProfileEditState {
  const ProfileEditState({
    this.status = ProfileEditStatus.loading,
    this.profile,
    this.fullName = '',
    this.errorMessage = '',
  });

  final ProfileEditStatus status;
  final UserProfile? profile;
  final String fullName;
  final String errorMessage;
}

class ProfileEditCubit extends Cubit<ProfileEditState> {
  ProfileEditCubit(this._service) : super(const ProfileEditState());

  final ProfileEditor _service;

  Future<void> load() async {
    emit(const ProfileEditState());
    try {
      final profile = await _service.load();
      emit(
        ProfileEditState(
          status: ProfileEditStatus.editing,
          profile: profile,
          fullName: profile.fullName,
        ),
      );
    } catch (_) {
      emit(
        const ProfileEditState(
          status: ProfileEditStatus.failure,
          errorMessage: 'Profil tidak dapat dimuat. Coba lagi.',
        ),
      );
    }
  }

  void setFullName(String value) {
    if (state.profile == null || state.status == ProfileEditStatus.saving) {
      return;
    }
    emit(
      ProfileEditState(
        status: ProfileEditStatus.editing,
        profile: state.profile,
        fullName: value,
      ),
    );
  }

  Future<void> save() async {
    if (state.profile == null || state.status == ProfileEditStatus.saving) {
      return;
    }
    final error = ProfileEditService.validateFullName(state.fullName);
    if (error != null) {
      emit(
        ProfileEditState(
          status: ProfileEditStatus.editing,
          profile: state.profile,
          fullName: state.fullName,
          errorMessage: error,
        ),
      );
      return;
    }

    emit(
      ProfileEditState(
        status: ProfileEditStatus.saving,
        profile: state.profile,
        fullName: state.fullName,
      ),
    );
    try {
      final profile = await _service.saveFullName(state.fullName);
      emit(
        ProfileEditState(
          status: ProfileEditStatus.success,
          profile: profile,
          fullName: profile.fullName,
        ),
      );
    } on ProfileEditException catch (exception) {
      emit(
        ProfileEditState(
          status: ProfileEditStatus.failure,
          profile: state.profile,
          fullName: state.fullName,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        ProfileEditState(
          status: ProfileEditStatus.failure,
          profile: state.profile,
          fullName: state.fullName,
          errorMessage: 'Profil tidak dapat disimpan. Coba lagi.',
        ),
      );
    }
  }
}
