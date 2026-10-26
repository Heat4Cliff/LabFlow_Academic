import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/student/domain/student_models.dart';
import 'package:labflow/features/student/presentation/widgets/student_ui.dart';

void main() {
  testWidgets('Student asset grid card fits common phone widths', (
    tester,
  ) async {
    const asset = StudentAsset(
      id: 'asset-1',
      labId: 'lab-1',
      code: 'CAM-LAB-001',
      name: 'Kamera Mikroskop Digital Resolusi Tinggi',
      category: 'camera',
      description: 'Aset untuk praktikum.',
      location: 'Laboratorium Biologi',
      stock: 2,
      status: 'available',
      condition: 'good',
      qrValue: 'asset-1',
    );

    for (final viewportWidth in [360.0, 390.0, 412.0]) {
      tester.view.physicalSize = Size(viewportWidth, 844);
      tester.view.devicePixelRatio = 1;

      final cardWidth = (viewportWidth - 36 - 10) / 2;
      final cardHeight = cardWidth / .70;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: const StudentAssetCard(
                  asset: asset,
                  labName: 'Laboratorium Biologi dan Mikroskopi',
                  onTap: _noop,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'Grid card should fit at $viewportWidth dp.',
      );
    }

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}

void _noop() {}
