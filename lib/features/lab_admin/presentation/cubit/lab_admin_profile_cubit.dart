import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/lab_admin_profile_service.dart';
import 'lab_admin_profile_state.dart';

class LabAdminProfileCubit extends Cubit<LabAdminProfileState> {
  LabAdminProfileCubit(this._service) : super(const LabAdminProfileState());

  final LabAdminProfileService _service;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: LabAdminProfileStatus.loading,
        errorMessage: '',
        actionStatus: LabAdminProfileActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      final profile = await _service.loadProfile();

      emit(
        state.copyWith(
          status: LabAdminProfileStatus.loaded,
          profile: profile,
          errorMessage: '',
        ),
      );
    } on LabAdminProfileException catch (error) {
      emit(
        state.copyWith(
          status: LabAdminProfileStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: LabAdminProfileStatus.failure,
          errorMessage: 'Profil Lab Admin tidak dapat dimuat.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    if (state.isSigningOut) {
      return;
    }

    emit(
      state.copyWith(
        isSigningOut: true,
        actionStatus: LabAdminProfileActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _service.signOut();

      emit(
        state.copyWith(
          isSigningOut: false,
          actionStatus: LabAdminProfileActionStatus.signedOut,
          actionMessage: 'Logout berhasil.',
        ),
      );
    } on LabAdminProfileException catch (error) {
      emit(
        state.copyWith(
          isSigningOut: false,
          actionStatus: LabAdminProfileActionStatus.failure,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isSigningOut: false,
          actionStatus: LabAdminProfileActionStatus.failure,
          actionMessage: 'Logout gagal. Coba lagi.',
        ),
      );
    }
  }

  void clearAction() {
    emit(
      state.copyWith(
        actionStatus: LabAdminProfileActionStatus.idle,
        actionMessage: '',
      ),
    );
  }
}
