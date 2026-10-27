import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/profile_edit_service.dart';

enum ProfileEditStatus { loading, editing, saving, success, failure }

class ProfileEditState {
  const ProfileEditState({
    this.status = ProfileEditStatus.loading,
    this.profile,
    this.fullName = '',
    this.phoneNumber = '',
    this.photoUrl,
    this.photo,
    this.removePhoto = false,
    this.errorMessage = '',
  });

  final ProfileEditStatus status;
  final UserProfile? profile;
  final String fullName;
  final String phoneNumber;
  final String? photoUrl;
  final XFile? photo;
  final bool removePhoto;
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
          phoneNumber: profile.phoneNumber ?? '',
          photoUrl: profile.profilePhotoUrl,
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

  void setPhoneNumber(String value) => _edit(phoneNumber: value);
  void setPhoto(XFile? value) => _edit(photo: value, removePhoto: false);
  void removeProfilePhoto() {
    if (state.profile == null || state.status == ProfileEditStatus.saving) {
      return;
    }
    emit(
      ProfileEditState(
        status: ProfileEditStatus.editing,
        profile: state.profile,
        fullName: state.fullName,
        phoneNumber: state.phoneNumber,
        photoUrl: state.photoUrl,
        removePhoto: true,
      ),
    );
  }

  void _edit({String? phoneNumber, XFile? photo, bool? removePhoto}) {
    if (state.profile == null || state.status == ProfileEditStatus.saving) {
      return;
    }
    emit(
      ProfileEditState(
        status: ProfileEditStatus.editing,
        profile: state.profile,
        fullName: state.fullName,
        phoneNumber: phoneNumber ?? state.phoneNumber,
        photoUrl: state.photoUrl,
        photo: photo ?? state.photo,
        removePhoto: removePhoto ?? state.removePhoto,
      ),
    );
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
        phoneNumber: state.phoneNumber,
        photoUrl: state.photoUrl,
        photo: state.photo,
        removePhoto: state.removePhoto,
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
          phoneNumber: state.phoneNumber,
          photoUrl: state.photoUrl,
          photo: state.photo,
          removePhoto: state.removePhoto,
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
      final profile = await _service.saveProfile(
        fullName: state.fullName,
        phoneNumber: state.phoneNumber,
        photo: state.photo,
        removePhoto: state.removePhoto,
      );
      emit(
        ProfileEditState(
          status: ProfileEditStatus.success,
          profile: profile,
          fullName: profile.fullName,
          phoneNumber: profile.phoneNumber ?? '',
          photoUrl: profile.profilePhotoUrl,
        ),
      );
    } on ProfileEditException catch (exception) {
      emit(
        ProfileEditState(
          status: ProfileEditStatus.failure,
          profile: state.profile,
          fullName: state.fullName,
          phoneNumber: state.phoneNumber,
          photoUrl: state.photoUrl,
          photo: state.photo,
          removePhoto: state.removePhoto,
          errorMessage: exception.message,
        ),
      );
    } catch (_) {
      emit(
        ProfileEditState(
          status: ProfileEditStatus.failure,
          profile: state.profile,
          fullName: state.fullName,
          phoneNumber: state.phoneNumber,
          photoUrl: state.photoUrl,
          photo: state.photo,
          removePhoto: state.removePhoto,
          errorMessage: 'Profil tidak dapat disimpan. Coba lagi.',
        ),
      );
    }
  }
}
