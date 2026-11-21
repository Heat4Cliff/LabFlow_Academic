import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:labflow/core/session/app_session_manager.dart';
import 'package:labflow/features/auth/data/auth_service.dart';
import 'package:labflow/features/auth/data/email_change_service.dart';
import 'package:labflow/features/auth/domain/email_change_request.dart';
import 'package:labflow/features/auth/presentation/pages/request_email_change_page.dart';
import 'package:labflow/features/lab_admin/data/lab_admin_profile_service.dart';
import 'package:labflow/features/lab_admin/presentation/pages/lab_admin_profile_page.dart';
import 'package:labflow/features/student/data/student_service.dart';
import 'package:labflow/features/student/presentation/pages/student_profile_page.dart';
import 'package:labflow/features/superadmin/presentation/pages/superadmin_profile_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/fake_firestore.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockUserCredential extends Mock implements UserCredential {}

class _MemorySessionStorage implements AppSessionStorage {
  AppSession? session;

  @override
  Future<AppSession?> read() async => session;

  @override
  Future<void> write(AppSession value) async => session = value;

  @override
  Future<void> clear() async => session = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime currentClock;
  late FakeMemoryFirestore firestore;
  late _MockFirebaseAuth firebaseAuth;
  late _MockUser user;
  late _MemorySessionStorage sessionStorage;
  late AppSessionManager sessionManager;
  late AuthService authService;
  late EmailChangeService emailChangeService;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    currentClock = DateTime.utc(2026, 11, 21, 11, 0, 0);
    firestore = FakeMemoryFirestore(clock: () => currentClock);
    firebaseAuth = _MockFirebaseAuth();
    user = _MockUser();
    sessionStorage = _MemorySessionStorage();
    sessionManager = AppSessionManager(
      storage: sessionStorage,
      now: () => currentClock,
    );

    AuthService.clearProfileCache();

    when(() => user.uid).thenReturn('student-1');
    when(() => user.email).thenReturn('lama@labflow.test');
    when(() => user.displayName).thenReturn('Budi Mahasiswa');
    when(() => user.emailVerified).thenReturn(false);
    when(() => user.reload()).thenAnswer((_) async {});
    when(() => user.getIdToken(any())).thenAnswer((_) async => 'fresh-token');
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => firebaseAuth.signOut()).thenAnswer((_) async {});

    firestore.seedDoc('users', 'student-1', {
      'uid': 'student-1',
      'email': 'lama@labflow.test',
      'emailVerified': true,
      'fullName': 'Budi Mahasiswa',
      'role': 'student',
      'status': 'active',
      'nim': '202401001',
      'studyProgram': 'Informatika',
      'semester': 5,
    });

    firestore.seedDoc('email_change_requests', 'req-1', {
      'uid': 'student-1',
      'currentEmail': 'lama@labflow.test',
      'requestedEmail': 'baru@labflow.test',
      'reason': 'Email lama tidak aktif lagi',
      'status': 'approved',
      'requestedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 20, 8, 0)),
      'reviewedBy': 'superadmin-1',
      'reviewedAt': Timestamp.fromDate(DateTime.utc(2026, 11, 20, 9, 0)),
    });

    authService = AuthService(
      firebaseAuth: firebaseAuth,
      firestore: firestore,
      sessionManager: sessionManager,
    );
    emailChangeService = EmailChangeService(
      firestore: firestore,
      auth: firebaseAuth,
    );
  });

  group('Bug #5 Email Profile Synchronization After Approved Email Change', () {
    test(
      'Test 1 — Successful Email Synchronization: updates users/{uid}, invalidates cache, preserves role/status/uid, and completes request',
      () async {
        await sessionManager.start('student-1');
        // Isi cache awal dengan email lama
        final initialProfile = await authService.getCurrentUserProfile();
        expect(initialProfile.email, 'lama@labflow.test');
        expect(
          AuthService.debugCachedProfile('student-1')?.email,
          'lama@labflow.test',
        );

        // Simulasikan pengguna telah mengklik tautan verifikasi di inbox
        when(() => user.reload()).thenAnswer((_) async {
          when(() => user.email).thenReturn('baru@labflow.test');
          when(() => user.emailVerified).thenReturn(true);
        });

        final req = EmailChangeRequest(
          id: 'req-1',
          uid: 'student-1',
          currentEmail: 'lama@labflow.test',
          requestedEmail: 'baru@labflow.test',
          reason: 'Email lama tidak aktif lagi',
          status: 'approved',
          requestedAt: DateTime.utc(2026, 11, 20, 8, 0),
          reviewedBy: 'superadmin-1',
          reviewedAt: DateTime.utc(2026, 11, 20, 9, 0),
        );

        final synced = await emailChangeService.checkAndSyncVerifiedEmail(req);
        expect(synced, isTrue);

        // Cache harus dibersihkan agar Profil tidak memakai email lama
        expect(AuthService.debugCachedProfile('student-1'), isNull);

        // Periksa field yang ditulis ke users/{uid}
        final userWrites = firestore.writesFor('users', 'student-1');
        expect(userWrites, hasLength(1));
        expect(
          userWrites.single.payload.keys.toSet(),
          equals({'email', 'emailVerified', 'updatedAt'}),
        );

        final updatedUser = firestore.peekDoc('users', 'student-1')!;
        expect(updatedUser['email'], 'baru@labflow.test');
        expect(updatedUser['emailVerified'], isTrue);
        expect(updatedUser['role'], 'student');
        expect(updatedUser['status'], 'active');
        expect(updatedUser['uid'], 'student-1');
        expect(updatedUser['nim'], '202401001');

        // Permohonan berubah menjadi completed dan audit trail tetap terjaga
        final updatedReq =
            firestore.peekDoc('email_change_requests', 'req-1')!;
        expect(updatedReq['status'], 'completed');
        expect(updatedReq['reviewedBy'], 'superadmin-1');
        expect(updatedReq['completedAt'], isNotNull);

        // Pembacaan profil berikutnya dari AuthService langsung mendapat email baru
        final refreshed = await authService.getCurrentUserProfile();
        expect(refreshed.email, 'baru@labflow.test');
      },
    );

    testWidgets(
      'Test 2a — Profile Refresh (Student): kembali dari Keamanan Akun memperbarui email pada StudentProfilePage',
      (tester) async {
        await sessionManager.start('student-1');
        final studentService = StudentService(
          firestore: firestore,
          firebaseAuth: firebaseAuth,
        );

        final router = GoRouter(
          initialLocation: '/student/profile',
          routes: [
            GoRoute(
              path: '/student/profile',
              builder: (_, _) => StudentProfilePage(service: studentService),
            ),
            GoRoute(
              path: '/student/profile/security',
              builder: (context, _) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Simulasikan sync email berhasil dilakukan saat di halaman keamanan
                      when(() => user.email).thenReturn('baru@labflow.test');
                      when(() => user.emailVerified).thenReturn(true);
                      await emailChangeService.checkAndSyncVerifiedEmail(
                        EmailChangeRequest(
                          id: 'req-1',
                          uid: 'student-1',
                          currentEmail: 'lama@labflow.test',
                          requestedEmail: 'baru@labflow.test',
                          reason: 'Email lama tidak aktif lagi',
                          status: 'approved',
                          requestedAt: DateTime.utc(2026, 11, 20, 8, 0),
                        ),
                      );
                      if (context.mounted) context.pop();
                    },
                    child: const Text('Selesaikan Verifikasi'),
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        expect(find.text('lama@labflow.test'), findsOneWidget);

        await tester.tap(find.text('Keamanan Akun'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Selesaikan Verifikasi'));
        await tester.pumpAndSettle();

        expect(find.text('baru@labflow.test'), findsOneWidget);
        expect(find.text('lama@labflow.test'), findsNothing);
      },
    );

    testWidgets(
      'Test 2b — Profile Refresh (Lab Admin & Superadmin): kembali dari Keamanan Akun memperbarui email pada kedua role',
      (tester) async {
        // Bagian 1: Lab Admin
        when(() => user.uid).thenReturn('admin-1');
        when(() => user.email).thenReturn('admin-lama@labflow.test');
        when(() => user.emailVerified).thenReturn(true);
        await sessionManager.start('admin-1');

        firestore.seedDoc('users', 'admin-1', {
          'uid': 'admin-1',
          'email': 'admin-lama@labflow.test',
          'emailVerified': true,
          'fullName': 'Lab Admin',
          'role': 'lab_admin',
          'status': 'active',
        });

        final adminProfileService = LabAdminProfileService(
          firestore: firestore,
          firebaseAuth: firebaseAuth,
        );

        final adminRouter = GoRouter(
          initialLocation: '/lab-admin/profile',
          routes: [
            GoRoute(
              path: '/lab-admin/profile',
              builder: (_, _) =>
                  LabAdminProfilePage(service: adminProfileService),
            ),
            GoRoute(
              path: '/lab-admin/profile/security',
              builder: (context, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    when(() => user.email).thenReturn('admin-baru@labflow.test');
                    context.pop();
                  },
                  child: const Text('Simulasi Sync Lab Admin'),
                ),
              ),
            ),
          ],
        );
        addTearDown(adminRouter.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: adminRouter));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('admin-lama@labflow.test'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('admin-lama@labflow.test'), findsWidgets);

        await tester.scrollUntilVisible(
          find.text('Keamanan Akun'),
          -250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Keamanan Akun'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simulasi Sync Lab Admin'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('admin-baru@labflow.test'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('admin-baru@labflow.test'), findsWidgets);

        // Bagian 2: Superadmin (melewati cache AuthService!)
        AuthService.clearProfileCache();
        when(() => user.uid).thenReturn('super-1');
        when(() => user.email).thenReturn('super-lama@labflow.test');
        await sessionManager.start('super-1');
        firestore.seedDoc('users', 'super-1', {
          'uid': 'super-1',
          'email': 'super-lama@labflow.test',
          'emailVerified': true,
          'fullName': 'Super Admin',
          'role': 'superadmin',
          'status': 'active',
        });

        final superRouter = GoRouter(
          initialLocation: '/superadmin/profile',
          routes: [
            GoRoute(
              path: '/superadmin/profile',
              builder: (_, _) =>
                  SuperadminProfilePage(authService: authService),
            ),
            GoRoute(
              path: '/superadmin/profile/security',
              builder: (context, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    when(() => user.email).thenReturn('super-baru@labflow.test');
                    context.pop();
                  },
                  child: const Text('Simulasi Sync Superadmin'),
                ),
              ),
            ),
          ],
        );
        addTearDown(superRouter.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: superRouter));
        await tester.pumpAndSettle();
        expect(find.text('super-lama@labflow.test'), findsWidgets);

        await tester.scrollUntilVisible(
          find.text('Keamanan Akun'),
          -250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Keamanan Akun'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Simulasi Sync Superadmin'));
        await tester.pumpAndSettle();
        expect(find.text('super-baru@labflow.test'), findsWidgets);
        expect(find.text('super-lama@labflow.test'), findsNothing);
      },
    );

    test(
      'Test 3 — App Restart / Re-login with New Email: signIn otomatis menyinkronkan users/{uid} dan cache tetap konsisten setelah restart',
      () async {
        final cred = _MockUserCredential();
        when(
          () => firebaseAuth.signInWithEmailAndPassword(
            email: 'baru@labflow.test',
            password: 'Password123!',
          ),
        ).thenAnswer((_) async {
          // Firebase Auth sudah menyimpan email baru yang terverifikasi di server
          when(() => user.email).thenReturn('baru@labflow.test');
          when(() => user.emailVerified).thenReturn(true);
          return cred;
        });

        // Pengguna login dengan email baru sementara users/{uid} masih berisi email lama
        final signedInProfile = await authService.signIn(
          email: 'baru@labflow.test',
          password: 'Password123!',
        );

        expect(signedInProfile.email, 'baru@labflow.test');
        expect(signedInProfile.role, 'student');
        expect(signedInProfile.status, 'active');

        // Firestore users/{uid} dan status permohonan harus ikut tersinkron
        final persistedUser = firestore.peekDoc('users', 'student-1')!;
        expect(persistedUser['email'], 'baru@labflow.test');
        expect(persistedUser['emailVerified'], isTrue);
        final req = firestore.peekDoc('email_change_requests', 'req-1')!;
        expect(req['status'], 'completed');

        // Simulasikan app restart (clear in-memory cache + instance AuthService baru)
        AuthService.clearProfileCache();
        final restartedAuthService = AuthService(
          firebaseAuth: firebaseAuth,
          firestore: firestore,
          sessionManager: sessionManager,
        );
        final restoredProfile = await restartedAuthService
            .getCurrentUserProfile();
        expect(restoredProfile.email, 'baru@labflow.test');
      },
    );

    test(
      'Test 4 — Unverified Email: email baru belum terverifikasi tidak menyinkronkan Firestore atau menandai selesai',
      () async {
        await sessionManager.start('student-1');
        // Misal emailAuth sudah atau belum berubah, tetapi emailVerified == false
        when(() => user.email).thenReturn('baru@labflow.test');
        when(() => user.emailVerified).thenReturn(false);

        final req = EmailChangeRequest(
          id: 'req-1',
          uid: 'student-1',
          currentEmail: 'lama@labflow.test',
          requestedEmail: 'baru@labflow.test',
          reason: 'Email lama tidak aktif lagi',
          status: 'approved',
          requestedAt: DateTime.utc(2026, 11, 20, 8, 0),
        );

        final synced = await emailChangeService.checkAndSyncVerifiedEmail(req);
        expect(synced, isFalse);

        // Tidak ada write ke users/{uid} atau email_change_requests
        expect(firestore.writesFor('users', 'student-1'), isEmpty);
        expect(
          firestore.peekDoc('users', 'student-1')!['email'],
          'lama@labflow.test',
        );
        expect(
          firestore.peekDoc('email_change_requests', 'req-1')!['status'],
          'approved',
        );

        // Bahkan saat getCurrentUserProfile / StudentService.loadProfile berjalan, email lama dipertahankan
        final profile = await authService.getCurrentUserProfile(
          forceRefresh: true,
        );
        expect(profile.email, 'lama@labflow.test');
      },
    );

    testWidgets(
      'Test 4b — RequestEmailChangePage menampilkan feedback belum terverifikasi dan mempertahankan email aktif lama',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: RequestEmailChangePage(
              emailChangeService: emailChangeService,
              firebaseAuth: firebaseAuth,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('lama@labflow.test'), findsOneWidget);
        expect(find.textContaining('baru@labflow.test'), findsOneWidget);

        await tester.tap(find.text('Sinkronkan'));
        await tester.pumpAndSettle();

        expect(find.text('Belum Terverifikasi'), findsOneWidget);
        expect(
          firestore.peekDoc('users', 'student-1')!['email'],
          'lama@labflow.test',
        );

        await tester.pump(const Duration(seconds: 4));
      },
    );

    test(
      'Test 5 — Firestore Synchronization Failure: error ditangani jelas, tidak menutupi UI, dan pemulihan aman dapat diulang',
      () async {
        await sessionManager.start('student-1');
        when(() => user.email).thenReturn('baru@labflow.test');
        when(() => user.emailVerified).thenReturn(true);

        firestore.failWritesWithError = FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Simulated failure',
        );

        final req = EmailChangeRequest(
          id: 'req-1',
          uid: 'student-1',
          currentEmail: 'lama@labflow.test',
          requestedEmail: 'baru@labflow.test',
          reason: 'Email lama tidak aktif lagi',
          status: 'approved',
          requestedAt: DateTime.utc(2026, 11, 20, 8, 0),
        );

        await expectLater(
          emailChangeService.checkAndSyncVerifiedEmail(req),
          throwsA(
            isA<EmailChangeException>().having(
              (e) => e.code,
              'code',
              'permission-denied',
            ),
          ),
        );

        // Email di Firestore dan request tidak berubah; tidak dimanipulasi lokal
        expect(
          firestore.peekDoc('users', 'student-1')!['email'],
          'lama@labflow.test',
        );
        expect(
          firestore.peekDoc('email_change_requests', 'req-1')!['status'],
          'approved',
        );
        final profileAfterFail = await authService.getCurrentUserProfile(
          forceRefresh: true,
        );
        expect(profileAfterFail.email, 'lama@labflow.test');
        expect(profileAfterFail.role, 'student');
        expect(profileAfterFail.status, 'active');

        // Pulihkan jaringan/Firestore, lalu coba sinkronkan kembali
        firestore.failWritesWithError = null;
        final recovered = await emailChangeService.checkAndSyncVerifiedEmail(
          req,
        );
        expect(recovered, isTrue);
        expect(
          firestore.peekDoc('users', 'student-1')!['email'],
          'baru@labflow.test',
        );
        expect(
          firestore.peekDoc('email_change_requests', 'req-1')!['status'],
          'completed',
        );
      },
    );

    test(
      'Test 6 & 7 & 8 — Unauthorized Update & Account/Role Regression: menolak sync UID lain dan tidak mengubah role/status/logout',
      () async {
        await sessionManager.start('student-1');
        when(() => user.uid).thenReturn('student-1');
        when(() => user.email).thenReturn('baru@labflow.test');
        when(() => user.emailVerified).thenReturn(true);

        firestore.seedDoc('users', 'victim-uid', {
          'uid': 'victim-uid',
          'email': 'victim@labflow.test',
          'role': 'superadmin',
          'status': 'active',
        });

        final forgedRequest = EmailChangeRequest(
          id: 'req-forged',
          uid: 'victim-uid',
          currentEmail: 'victim@labflow.test',
          requestedEmail: 'baru@labflow.test',
          reason: 'Percobaan perubahan milik orang lain',
          status: 'approved',
          requestedAt: DateTime.utc(2026, 11, 20, 8, 0),
        );

        await expectLater(
          emailChangeService.checkAndSyncVerifiedEmail(forgedRequest),
          throwsA(isA<EmailChangeException>()),
        );
        expect(firestore.writesFor('users', 'victim-uid'), isEmpty);

        // Logout tetap membersihkan cache dan session cleanly
        await authService.getCurrentUserProfile();
        await authService.signOut();
        expect(AuthService.debugCachedProfile('student-1'), isNull);
        expect(sessionStorage.session, isNull);
      },
    );
  });
}
