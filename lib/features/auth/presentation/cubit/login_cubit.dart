import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/auth_service.dart';
import 'login_state.dart';

/// Mengelola state autentikasi dan mendelegasikan akses Firebase ke AuthService.
class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._authService) : super(const LoginInitial());

  /// Dependency diinjeksi agar alur login dapat diuji tanpa Firebase.
  final AuthService _authService;

  /// Menjalankan satu permintaan login dan mengabaikan submit saat masih memuat.
  Future<void> login({required String email, required String password}) async {
    if (state is LoginLoading) return;

    emit(const LoginLoading());

    try {
      final profile = await _authService.signIn(
        email: email.trim(),
        password: password,
      );
      emit(LoginSuccess(profile));
    } on AuthServiceException catch (error) {
      emit(
        LoginFailure(
          error.message,
          isAccountSuspended: error.isAccountSuspended,
        ),
      );
    } catch (_) {
      emit(
        const LoginFailure(
          'Terjadi kesalahan saat proses login.',
          isUnexpected: true,
        ),
      );
    }
  }

  /// Mengembalikan alur login ke kondisi awal setelah role tidak dikenali.
  void reset() => emit(const LoginInitial());
}
