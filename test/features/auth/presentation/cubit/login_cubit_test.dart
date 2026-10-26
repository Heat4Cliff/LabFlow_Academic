import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/auth/data/auth_service.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';
import 'package:labflow/features/auth/presentation/cubit/login_cubit.dart';
import 'package:labflow/features/auth/presentation/cubit/login_state.dart';
import 'package:mocktail/mocktail.dart';

class _AuthServiceMock extends Mock implements AuthService {}

void main() {
  late _AuthServiceMock authService;
  const profile = UserProfile(
    uid: 'user-1',
    email: 'student@example.com',
    fullName: 'Mahasiswa LabFlow',
    role: 'student',
    status: 'active',
  );

  setUp(() {
    authService = _AuthServiceMock();
  });

  test('state awal adalah LoginInitial', () {
    expect(LoginCubit(authService).state, isA<LoginInitial>());
  });

  blocTest<LoginCubit, LoginState>(
    'menghasilkan LoginLoading lalu LoginSuccess ketika autentikasi berhasil',
    build: () {
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => profile);
      return LoginCubit(authService);
    },
    act: (cubit) =>
        cubit.login(email: ' student@example.com ', password: 'password'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginSuccess>().having((state) => state.profile, 'profil', profile),
    ],
    verify: (_) => verify(
      () => authService.signIn(
        email: 'student@example.com',
        password: 'password',
      ),
    ).called(1),
  );

  blocTest<LoginCubit, LoginState>(
    'menghasilkan LoginFailure dengan pesan aman dari AuthServiceException',
    build: () {
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthServiceException('Email atau password tidak sesuai.'),
      );
      return LoginCubit(authService);
    },
    act: (cubit) =>
        cubit.login(email: 'student@example.com', password: 'wrong'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginFailure>().having(
        (state) => state.message,
        'pesan',
        'Email atau password tidak sesuai.',
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'menyembunyikan detail exception yang tidak dikenal',
    build: () {
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('detail internal'));
      return LoginCubit(authService);
    },
    act: (cubit) =>
        cubit.login(email: 'student@example.com', password: 'password'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginFailure>()
          .having(
            (state) => state.message,
            'pesan aman',
            'Terjadi kesalahan saat proses login.',
          )
          .having((state) => state.isUnexpected, 'exception tak dikenal', true),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'menandai akun suspended agar halaman mempertahankan tampilan khusus',
    build: () {
      when(
        () => authService.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(
        const AuthServiceException(
          'Akun Anda sedang dinonaktifkan. Hubungi Admin Lab.',
          code: AuthServiceException.accountSuspended,
        ),
      );
      return LoginCubit(authService);
    },
    act: (cubit) =>
        cubit.login(email: 'student@example.com', password: 'password'),
    expect: () => [
      isA<LoginLoading>(),
      isA<LoginFailure>().having(
        (state) => state.isAccountSuspended,
        'akun suspended',
        isTrue,
      ),
    ],
  );
}
