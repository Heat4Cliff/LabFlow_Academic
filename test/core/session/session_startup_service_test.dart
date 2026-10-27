import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/core/session/session_startup_service.dart';
import 'package:labflow/features/auth/data/auth_service.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';
import 'package:mocktail/mocktail.dart';

class _AuthServiceMock extends Mock implements AuthService {}

const _student = UserProfile(
  uid: 'student-1',
  email: 'student@example.com',
  fullName: 'Student LabFlow',
  role: 'student',
  status: 'active',
);

void main() {
  late _AuthServiceMock auth;

  setUp(() {
    auth = _AuthServiceMock();
    when(() => auth.signOut()).thenAnswer((_) async {});
  });

  test('Firebase user dan sesi valid menuju Student', () async {
    when(() => auth.currentUid).thenReturn('student-1');
    when(() => auth.getCurrentUserProfile()).thenAnswer((_) async => _student);
    expect(await SessionStartupService(auth).restoreRoute(), '/student');
    verifyNever(() => auth.signOut());
  });

  test('sesi kedaluwarsa menuju login dan signOut', () async {
    when(() => auth.currentUid).thenReturn('student-1');
    when(() => auth.getCurrentUserProfile()).thenThrow(
      const AuthServiceException(
        'Sesi berakhir',
        code: AuthServiceException.sessionNotFound,
      ),
    );
    expect(await SessionStartupService(auth).restoreRoute(), '/login');
    verify(() => auth.signOut()).called(1);
  });

  test('Firebase user hilang membersihkan sesi lokal', () async {
    when(() => auth.currentUid).thenReturn(null);
    expect(await SessionStartupService(auth).restoreRoute(), '/login');
    verify(() => auth.signOut()).called(1);
    verifyNever(() => auth.getCurrentUserProfile());
  });

  test('akun suspended dan role invalid ditolak', () async {
    when(() => auth.currentUid).thenReturn('student-1');
    when(() => auth.getCurrentUserProfile()).thenThrow(
      const AuthServiceException(
        'Suspended',
        code: AuthServiceException.accountSuspended,
      ),
    );
    expect(await SessionStartupService(auth).restoreRoute(), '/login');

    when(() => auth.getCurrentUserProfile()).thenAnswer(
      (_) async => const UserProfile(
        uid: 'student-1',
        email: '',
        fullName: 'Unknown',
        role: 'unknown',
        status: 'active',
      ),
    );
    expect(await SessionStartupService(auth).restoreRoute(), '/login');
    verify(() => auth.signOut()).called(2);
  });
}
