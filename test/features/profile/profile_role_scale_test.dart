import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/auth/data/auth_service.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';
import 'package:labflow/features/lab_admin/data/lab_admin_profile_service.dart';
import 'package:labflow/features/lab_admin/domain/lab_admin_profile.dart';
import 'package:labflow/features/lab_admin/presentation/pages/lab_admin_profile_page.dart';
import 'package:labflow/features/superadmin/presentation/pages/superadmin_profile_page.dart';
import 'package:mocktail/mocktail.dart';

class _LabAdminServiceMock extends Mock implements LabAdminProfileService {}

class _AuthServiceMock extends Mock implements AuthService {}

void main() {
  testWidgets('Lab Admin dan Superadmin Profile muat di layar umum', (
    tester,
  ) async {
    final labService = _LabAdminServiceMock();
    when(() => labService.loadProfile()).thenAnswer(
      (_) async => const LabAdminProfile(
        uid: 'lab-admin-1',
        fullName: 'Administrator Laboratorium dengan Nama Panjang',
        email: 'administrator.laboratorium@example.ac.id',
        role: 'lab_admin',
        status: 'active',
        laboratories: [
          LabAdminProfileLaboratory(
            id: 'lab-1',
            code: 'LAB-001',
            name: 'Laboratorium Jaringan Komputer dan Sistem Tertanam',
            location: 'Gedung Akademik Lantai Tiga',
          ),
        ],
      ),
    );
    final auth = _AuthServiceMock();
    when(() => auth.getCurrentUserProfile()).thenAnswer(
      (_) async => const UserProfile(
        uid: 'superadmin-1',
        email: 'superadmin.akademik@example.ac.id',
        fullName: 'Superadmin Akademik dengan Nama Panjang',
        role: 'superadmin',
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
        for (final page in [
          LabAdminProfilePage(service: labService),
          SuperadminProfilePage(authService: auth),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: page,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${page.runtimeType}: $width dp / $scale',
          );
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    }
  });
}
