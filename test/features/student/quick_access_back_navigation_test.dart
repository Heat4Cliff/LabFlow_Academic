import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:labflow/features/student/presentation/student_navigation.dart';
import 'package:labflow/shared/presentation/navigation/labflow_back_fallback.dart';

void main() {
  group('Bug #2 Quick Access Navigation & Android Back Behavior Tests', () {
    testWidgets(
      'Pushing Pinjaman Saya from Quick Access enables back button and Android back returns to Home',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/student',
          routes: [
            GoRoute(
              path: '/student',
              builder: (context, _) => Scaffold(
                body: Column(
                  children: [
                    const Text('Student Home Page'),
                    ElevatedButton(
                      onPressed: () => context.push('/student/borrowing'),
                      child: const Text('Quick Access: Pinjaman Saya'),
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/student/borrowing',
              builder: (context, _) => LabFlowBackFallback(
                fallbackPath: '/student',
                child: Scaffold(
                  body: Row(
                    children: [
                      if (context.canPop())
                        IconButton(
                          tooltip: 'Kembali',
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => studentPopOrGo(context, '/student'),
                        ),
                      const Text('Pinjaman Saya'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.text('Student Home Page'), findsOneWidget);

        // Tap Quick Access "Pinjaman Saya"
        await tester.tap(find.text('Quick Access: Pinjaman Saya'));
        await tester.pumpAndSettle();
        expect(find.text('Pinjaman Saya'), findsOneWidget);
        expect(find.byTooltip('Kembali'), findsOneWidget);

        // Simulate physical/system Android Back button
        final handled = await tester.binding.handlePopRoute();
        expect(handled, isTrue);
        await tester.pumpAndSettle();

        // Must return to Student Home Page cleanly without exiting
        expect(find.text('Student Home Page'), findsOneWidget);
        expect(find.text('Pinjaman Saya'), findsNothing);
      },
    );

    testWidgets(
      'UI Back button in Pinjaman Saya behaves identically to Android System Back',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/student',
          routes: [
            GoRoute(
              path: '/student',
              builder: (context, _) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => context.push('/student/borrowing'),
                  child: const Text('Quick Access: Pinjaman Saya'),
                ),
              ),
            ),
            GoRoute(
              path: '/student/borrowing',
              builder: (context, _) => LabFlowBackFallback(
                fallbackPath: '/student',
                child: Scaffold(
                  body: Row(
                    children: [
                      if (context.canPop())
                        IconButton(
                          tooltip: 'Kembali',
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => studentPopOrGo(context, '/student'),
                        ),
                      const Text('Pinjaman Saya'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Quick Access: Pinjaman Saya'));
        await tester.pumpAndSettle();
        expect(find.text('Pinjaman Saya'), findsOneWidget);

        // Tap UI Back button
        await tester.tap(find.byTooltip('Kembali'));
        await tester.pumpAndSettle();

        expect(find.text('Quick Access: Pinjaman Saya'), findsOneWidget);
        expect(find.text('Pinjaman Saya'), findsNothing);
      },
    );

    testWidgets(
      'Direct navigation to Pinjaman Saya without history uses LabFlowBackFallback on Android Back',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/student/borrowing',
          routes: [
            GoRoute(
              path: '/student',
              builder: (context, _) => const Scaffold(
                body: Text('Student Home Page'),
              ),
            ),
            GoRoute(
              path: '/student/borrowing',
              builder: (context, _) => LabFlowBackFallback(
                fallbackPath: '/student',
                child: Scaffold(
                  body: Row(
                    children: [
                      if (context.canPop())
                        IconButton(
                          tooltip: 'Kembali',
                          icon: const Icon(Icons.arrow_back_rounded),
                          onPressed: () => studentPopOrGo(context, '/student'),
                        ),
                      const Text('Pinjaman Saya'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.text('Pinjaman Saya'), findsOneWidget);
        // Because canPop is false, no back button in header (tab-style view)
        expect(find.byTooltip('Kembali'), findsNothing);

        // Simulate physical/system Android Back button
        final handled = await tester.binding.handlePopRoute();
        expect(handled, isTrue);
        await tester.pumpAndSettle();

        // Must redirect to Student Home Page via fallbackPath
        expect(find.text('Student Home Page'), findsOneWidget);
        expect(find.text('Pinjaman Saya'), findsNothing);
      },
    );

    testWidgets(
      'Quick Access Cari Peralatan and Lihat Semua return cleanly on Android Back',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/student',
          routes: [
            GoRoute(
              path: '/student',
              builder: (context, _) => Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => context.push('/student/assets'),
                      child: const Text('Cari Peralatan'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/student/borrowing'),
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
              ),
            ),
            GoRoute(
              path: '/student/assets',
              builder: (context, _) => LabFlowBackFallback(
                fallbackPath: '/student',
                child: const Scaffold(body: Text('Inventory Catalog')),
              ),
            ),
            GoRoute(
              path: '/student/borrowing',
              builder: (context, _) => LabFlowBackFallback(
                fallbackPath: '/student',
                child: const Scaffold(body: Text('Pinjaman Saya')),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Test Cari Peralatan
        await tester.tap(find.text('Cari Peralatan'));
        await tester.pumpAndSettle();
        expect(find.text('Inventory Catalog'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Cari Peralatan'), findsOneWidget);

        // Test Lihat Semua
        await tester.tap(find.text('Lihat Semua'));
        await tester.pumpAndSettle();
        expect(find.text('Pinjaman Saya'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Lihat Semua'), findsOneWidget);
      },
    );

    testWidgets(
      'Multi-role consistency: Lab Admin and Superadmin routes fall back to role dashboard on Android Back',
      (tester) async {
        final router = GoRouter(
          initialLocation: '/lab-admin/borrowing',
          routes: [
            GoRoute(
              path: '/lab-admin',
              builder: (_, _) => const Scaffold(body: Text('Lab Admin Dashboard')),
            ),
            GoRoute(
              path: '/lab-admin/borrowing',
              builder: (_, _) => const LabFlowBackFallback(
                fallbackPath: '/lab-admin',
                child: Scaffold(body: Text('Admin Borrowing Queue')),
              ),
            ),
            GoRoute(
              path: '/superadmin',
              builder: (_, _) => const Scaffold(body: Text('Superadmin Dashboard')),
            ),
            GoRoute(
              path: '/superadmin/users',
              builder: (_, _) => const LabFlowBackFallback(
                fallbackPath: '/superadmin',
                child: Scaffold(body: Text('Superadmin Users Management')),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
        expect(find.text('Admin Borrowing Queue'), findsOneWidget);

        // Android back from /lab-admin/borrowing returns to /lab-admin
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Lab Admin Dashboard'), findsOneWidget);

        // Switch to superadmin users
        router.go('/superadmin/users');
        await tester.pumpAndSettle();
        expect(find.text('Superadmin Users Management'), findsOneWidget);

        // Android back from /superadmin/users returns to /superadmin
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Superadmin Dashboard'), findsOneWidget);
      },
    );
  });
}
