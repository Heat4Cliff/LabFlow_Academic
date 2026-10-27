import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/shared/presentation/notifications/labflow_notification.dart';

void main() {
  testWidgets('notification appears near the safe top and can be dismissed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Header')),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLabFlowNotification(
                context: context,
                message: 'Profil tersimpan',
                type: LabFlowNotificationType.success,
              ),
              child: const Text('Tampilkan'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tampilkan'));
    await tester.pumpAndSettle();

    final message = find.text('Profil tersimpan');
    expect(message, findsOneWidget);
    expect(tester.getTopLeft(message).dy, lessThan(150));

    await tester.tap(find.byKey(const ValueKey('labflow-notification-close')));
    await tester.pumpAndSettle();
    expect(message, findsNothing);
  });

  testWidgets('a new notification replaces the current notification', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showLabFlowNotification(
                    context: context,
                    message: 'Pertama',
                  ),
                  child: const Text('Satu'),
                ),
                TextButton(
                  onPressed: () => showLabFlowNotification(
                    context: context,
                    message: 'Kedua',
                  ),
                  child: const Text('Dua'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Satu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dua'));
    await tester.pumpAndSettle();

    expect(find.text('Pertama'), findsNothing);
    expect(find.text('Kedua'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('labflow-notification-close')));
    await tester.pumpAndSettle();
  });

  testWidgets('notification is removed after its duration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showLabFlowNotification(
                context: context,
                message: 'Sementara',
                duration: const Duration(milliseconds: 300),
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Sementara'), findsNothing);
  });
}
