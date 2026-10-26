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
}
