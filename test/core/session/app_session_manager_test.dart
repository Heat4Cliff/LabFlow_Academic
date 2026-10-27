import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/core/session/app_session_manager.dart';
import 'package:labflow/features/auth/data/auth_service.dart';
import 'package:mocktail/mocktail.dart';

class _MemorySessionStorage implements AppSessionStorage {
  AppSession? session;
  bool corrupt = false;

  @override
  Future<AppSession?> read() async {
    if (corrupt) throw const FormatException('corrupt');
    return session;
  }

  @override
  Future<void> write(AppSession value) async {
    session = value;
  }

  @override
  Future<void> clear() async {
    session = null;
  }
}

class _FirebaseAuthMock extends Mock implements FirebaseAuth {}

class _FirestoreMock extends Mock implements FirebaseFirestore {}

void main() {
  late _MemorySessionStorage storage;
  late DateTime now;
  late AppSessionManager manager;

  setUp(() {
    storage = _MemorySessionStorage();
    now = DateTime.utc(2026, 10, 27, 9);
    manager = AppSessionManager(storage: storage, now: () => now);
  });

  test('login 09:00 berakhir tepat 10:00 tanpa sliding expiry', () async {
    final session = await manager.start('student-1');
    expect(session.expiresAt, DateTime.utc(2026, 10, 27, 10));
    expect(await manager.validFor('student-1'), isNotNull);

    now = DateTime.utc(2026, 10, 27, 9, 59);
    expect(await manager.validFor('student-1'), isNotNull);
    expect(storage.session!.expiresAt, DateTime.utc(2026, 10, 27, 10));

    now = DateTime.utc(2026, 10, 27, 10);
    expect(await manager.validFor('student-1'), isNull);
    expect(storage.session, isNull);
  });

  test('setelah expiry 10:01 ditolak', () async {
    await manager.start('student-1');
    now = DateTime.utc(2026, 10, 27, 10, 1);
    expect(await manager.validFor('student-1'), isNull);
  });

  test('session missing, UID berbeda, dan clock mundur ditolak', () async {
    expect(await manager.validFor('student-1'), isNull);
    await manager.start('student-1');
    expect(await manager.validFor('other-user'), isNull);
    await manager.start('student-1');
    now = DateTime.utc(2026, 10, 27, 8, 59);
    expect(await manager.validFor('student-1'), isNull);
  });

  test('session corrupt dan durasi manipulasi fail closed', () async {
    storage.corrupt = true;
    expect(await manager.validFor('student-1'), isNull);
    storage.corrupt = false;
    storage.session = AppSession(
      uid: 'student-1',
      startedAtUtcMs: now.millisecondsSinceEpoch,
      expiresAtUtcMs: now.add(const Duration(days: 1)).millisecondsSinceEpoch,
    );
    expect(await manager.validFor('student-1'), isNull);
  });

  test('logout Firebase membersihkan timestamp sesi', () async {
    await manager.start('student-1');
    final firebaseAuth = _FirebaseAuthMock();
    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});
    final service = AuthService(
      firebaseAuth: firebaseAuth,
      firestore: _FirestoreMock(),
      sessionManager: manager,
    );
    await service.signOut();
    expect(storage.session, isNull);
    verify(() => firebaseAuth.signOut()).called(1);
  });
}
