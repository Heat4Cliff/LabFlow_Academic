import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/app/app.dart';

void main() {
  testWidgets('menampilkan halaman onboarding LabFlow', (tester) async {
    // Menggunakan ukuran layar utama desain LabFlow.
    // Figma menggunakan frame Android 390 x 844 dp.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const LabFlowApp(initialLocation: '/onboarding'));

    await tester.pumpAndSettle();

    // Identitas aplikasi.
    expect(find.text('LabFlow.'), findsOneWidget);

    // Halaman pertama onboarding.
    expect(find.textContaining('Selamat Datang'), findsOneWidget);

    // Navigasi onboarding.
    expect(find.text('Lewati'), findsOneWidget);

    expect(find.text('Selanjutnya'), findsOneWidget);
  });
}
