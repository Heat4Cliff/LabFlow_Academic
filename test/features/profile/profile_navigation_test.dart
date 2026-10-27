import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:labflow/core/session/app_session_manager.dart';
import 'package:labflow/features/auth/data/auth_service.dart';
import 'package:labflow/features/profile/presentation/pages/about_labflow_page.dart';
import 'package:labflow/features/profile/presentation/pages/application_guide_page.dart';
import 'package:labflow/features/profile/presentation/pages/labflow_settings_page.dart';
import 'package:labflow/features/student/data/student_service.dart';
import 'package:labflow/features/student/domain/student_models.dart';
import 'package:labflow/features/student/presentation/pages/student_profile_page.dart';
import 'package:mocktail/mocktail.dart';

class _StudentServiceMock extends Mock implements StudentService {}

class _AuthServiceMock extends Mock implements AuthService {}

class _MemoryStorage implements AppSessionStorage {
  AppSession? value;

  @override
  Future<AppSession?> read() async => value;

  @override
  Future<void> write(AppSession session) async {
    value = session;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

void main() {
  late _StudentServiceMock studentService;
  late _AuthServiceMock authService;
  late AppSessionManager sessionManager;

  setUp(() async {
    studentService = _StudentServiceMock();
    authService = _AuthServiceMock();
    when(() => authService.currentUid).thenReturn('student-1');
    sessionManager = AppSessionManager(storage: _MemoryStorage());
    await sessionManager.start('student-1');
    when(() => studentService.loadProfile()).thenAnswer(
      (_) async => const StudentProfile(
        uid: 'student-1',
        fullName: 'Nama Lama',
        email: 'student@example.com',
        status: 'active',
      ),
    );
  });

  GoRouter router() => GoRouter(
    initialLocation: '/student/profile',
    routes: [
      GoRoute(
        path: '/student/profile',
        builder: (_, _) => StudentProfilePage(service: studentService),
      ),
      GoRoute(
        path: '/student/profile/edit',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.pop(true),
            child: const Text('Simpan'),
          ),
        ),
      ),
      GoRoute(
        path: '/student/profile/guide',
        builder: (_, _) => const ApplicationGuidePage(
          role: 'student',
          returnPath: '/student/profile',
        ),
      ),
      GoRoute(
        path: '/student/profile/settings',
        builder: (_, _) => LabFlowSettingsPage(
          role: 'student',
          returnPath: '/student/profile',
          authService: authService,
          sessionManager: sessionManager,
        ),
      ),
      GoRoute(
        path: '/student/profile/about',
        builder: (_, _) =>
            const AboutLabFlowPage(returnPath: '/student/profile'),
      ),
    ],
  );

  testWidgets('Panduan, Pengaturan, dan Tentang kembali ke Profil', (
    tester,
  ) async {
    final appRouter = router();
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pumpAndSettle();

    for (final (label, pageContent) in [
      ('Panduan Aplikasi', 'Cara menggunakan LabFlow'),
      ('Pengaturan', 'Keamanan & Sesi'),
      ('Tentang LabFlow', 'Tentang aplikasi'),
    ]) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(find.text(pageContent), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.text('Profil'), findsWidgets);
    }
  });

  testWidgets('Edit Profil memuat ulang nama dan inisial setelah save', (
    tester,
  ) async {
    var loads = 0;
    when(() => studentService.loadProfile()).thenAnswer((_) async {
      loads++;
      return StudentProfile(
        uid: 'student-1',
        fullName: loads == 1 ? 'Nama Lama' : 'Nama Baru',
        email: 'student@example.com',
        status: 'active',
      );
    });
    final appRouter = router();
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pumpAndSettle();
    expect(find.text('NL'), findsOneWidget);

    await tester.tap(find.text('Edit Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('Nama Baru'), findsOneWidget);
    expect(find.text('NB'), findsOneWidget);
    expect(loads, 2);
  });

  testWidgets('Panduan yang dibuka langsung memakai fallback ke Profil', (
    tester,
  ) async {
    final appRouter = GoRouter(
      initialLocation: '/student/profile/guide',
      routes: [
        GoRoute(
          path: '/student/profile',
          builder: (_, _) => StudentProfilePage(service: studentService),
        ),
        GoRoute(
          path: '/student/profile/guide',
          builder: (_, _) => const ApplicationGuidePage(
            role: 'student',
            returnPath: '/student/profile',
          ),
        ),
      ],
    );
    addTearDown(appRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: appRouter));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('Student Profile tidak overflow di lebar dan text scale umum', (
    tester,
  ) async {
    when(() => studentService.loadProfile()).thenAnswer(
      (_) async => const StudentProfile(
        uid: 'student-1',
        fullName: 'Mahasiswa Laboratorium dengan Nama yang Cukup Panjang',
        email: 'mahasiswa.laboratorium.dengan.email.panjang@example.ac.id',
        status: 'active',
      ),
    );
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    for (final width in [360.0, 390.0, 412.0]) {
      for (final scale in [1.0, 1.15, 1.30]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        final appRouter = router();
        await tester.pumpWidget(
          MaterialApp.router(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            routerConfig: appRouter,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$width dp / $scale');
        await tester.pumpWidget(const SizedBox.shrink());
        appRouter.dispose();
      }
    }
  });
}
