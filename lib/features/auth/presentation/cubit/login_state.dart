import '../../domain/user_profile.dart';

/// State eksplisit untuk membedakan proses autentikasi dan hasilnya.
sealed class LoginState {
  const LoginState();
}

final class LoginInitial extends LoginState {
  const LoginInitial();
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess(this.profile);

  final UserProfile profile;
}

final class LoginFailure extends LoginState {
  const LoginFailure(
    this.message, {
    this.isUnexpected = false,
    this.isAccountSuspended = false,
  });

  final String message;
  final bool isUnexpected;
  final bool isAccountSuspended;
}
