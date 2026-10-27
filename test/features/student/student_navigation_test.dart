import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:labflow/features/student/data/student_notification_service.dart';
import 'package:labflow/features/student/domain/student_notification.dart';
import 'package:labflow/features/student/presentation/cubit/student_notification_cubit.dart';
import 'package:labflow/features/student/presentation/pages/student_notification_page.dart';
import 'package:labflow/features/student/presentation/student_navigation.dart';
import 'package:mocktail/mocktail.dart';

class _MockStudentNotificationService extends Mock
    implements StudentNotificationService {}

void main() {
  testWidgets('borrow form static route is not a borrowing document id', (
    tester,
  ) async {
    String? resolvedRequestId;
    final router = GoRouter(
      initialLocation: '$studentBorrowRequestFormPath?assetId=asset-1',
      routes: [
        GoRoute(
          path: studentBorrowRequestFormPath,
          builder: (_, _) => const Text('borrow-form'),
        ),
        GoRoute(
          path: '/student/borrowing/:requestId',
          builder: (_, state) {
            resolvedRequestId = state.pathParameters['requestId'];
            return const Text('borrowing-detail');
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('borrow-form'), findsOneWidget);
    expect(resolvedRequestId, isNull);

    router.go(studentBorrowingDocumentPath('actual-document-id'));
    await tester.pumpAndSettle();
    expect(find.text('borrowing-detail'), findsOneWidget);
    expect(resolvedRequestId, 'actual-document-id');
  });

  testWidgets(
    'notification detail navigation preserves back to notifications',
    (tester) async {
      final service = _MockStudentNotificationService();
      final notification = StudentNotification(
        id: 'notification-1',
        type: 'borrow_active',
        title: 'Peminjaman aktif',
        body: 'Pembaruan status.',
        targetType: 'borrow_request',
        targetId: 'request-document-id',
        read: false,
        createdAt: DateTime(2026, 10, 27),
      );
      when(() => service.watchMine())
          .thenAnswer((_) => Stream.value([notification]));
      when(() => service.markRead('notification-1')).thenAnswer((_) async {});
      final cubit = StudentNotificationCubit(service)..start();
      addTearDown(cubit.close);

      final router = GoRouter(
        initialLocation: '/student/notifications',
        routes: [
          GoRoute(
            path: '/student/notifications',
            builder: (_, _) => StudentNotificationPage(cubit: cubit),
          ),
          GoRoute(
            path: '/student/borrowing/:requestId',
            builder: (_, state) =>
                Text('borrowing:${state.pathParameters['requestId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(find.text('Peminjaman aktif'), findsOneWidget);

      await tester.tap(find.text('Peminjaman aktif'));
      await tester.pumpAndSettle();
      expect(find.text('borrowing:request-document-id'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Peminjaman aktif'), findsOneWidget);
    },
  );

  testWidgets('report create success replaces form and back returns to list', (
    tester,
  ) async {
    final router = _reportRouter('/student/reports');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buat Laporan'));
    await tester.pumpAndSettle();
    expect(find.text('Kirim Laporan'), findsOneWidget);

    await tester.tap(find.text('Kirim Laporan'));
    await tester.pumpAndSettle();
    expect(find.text('report:report-1'), findsOneWidget);

    await tester.tap(find.text('Kembali Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Laporan'), findsOneWidget);
    expect(find.text('Kirim Laporan'), findsNothing);
  });

  testWidgets('report opened from notification returns to notifications', (
    tester,
  ) async {
    final router = _reportRouter('/student/notifications');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Buka Notifikasi'));
    await tester.pumpAndSettle();
    expect(find.text('report:report-1'), findsOneWidget);

    await tester.tap(find.text('Kembali Detail'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar Notifikasi'), findsOneWidget);
  });

  testWidgets('direct report detail system back falls back to reports list', (
    tester,
  ) async {
    final router = _reportRouter('/student/reports/report-1');
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('report:report-1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Daftar Laporan'), findsOneWidget);
  });
}

GoRouter _reportRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/student/reports',
      builder: (context, state) => Scaffold(
        body: TextButton(
          onPressed: () => context.push('/student/reports/create'),
          child: const Text('Buat Laporan'),
        ),
        appBar: AppBar(title: const Text('Daftar Laporan')),
      ),
    ),
    GoRoute(
      path: '/student/reports/create',
      builder: (context, state) => Scaffold(
        body: TextButton(
          onPressed: () => openCreatedStudentReport(context, 'report-1'),
          child: const Text('Kirim Laporan'),
        ),
      ),
    ),
    GoRoute(
      path: '/student/reports/:reportId',
      builder: (context, state) => StudentBackFallback(
        fallbackPath: '/student/reports',
        child: Scaffold(
          body: Column(
            children: [
              Text('report:${state.pathParameters['reportId']}'),
              TextButton(
                onPressed: () => studentPopOrGo(context, '/student/reports'),
                child: const Text('Kembali Detail'),
              ),
            ],
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/student/notifications',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Daftar Notifikasi')),
        body: TextButton(
          onPressed: () => context.push('/student/reports/report-1'),
          child: const Text('Buka Notifikasi'),
        ),
      ),
    ),
  ],
);
