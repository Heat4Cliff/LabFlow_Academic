import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';
import 'package:labflow/features/profile/data/profile_edit_service.dart';
import 'package:labflow/features/profile/presentation/pages/profile_edit_page.dart';
import 'package:image_picker/image_picker.dart';

class _ProfileEditor implements ProfileEditor {
  _ProfileEditor(this.role);

  final String role;

  @override
  Future<UserProfile> load() async => UserProfile(
    uid: 'user-1',
    email: 'user@example.invalid',
    fullName: 'Nama Pengguna',
    role: role,
    status: 'active',
  );

  @override
  Future<UserProfile> saveProfile({
    required String fullName,
    required String phoneNumber,
    required String nim,
    required String studyProgram,
    required int? semester,
    required String nip,
    required String nidn,
    XFile? photo,
    bool removePhoto = false,
  }) async => load();
}

void main() {
  for (final role in ['student', 'lab_admin']) {
    testWidgets('Edit Profile $role tidak overflow pada ukuran umum', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/edit',
        routes: [
          GoRoute(
            path: '/edit',
            builder: (_, _) => ProfileEditPage(
              returnPath: '/edit',
              editor: _ProfileEditor(role),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      for (final width in [360.0, 390.0, 412.0]) {
        for (final scale in [1.0, 1.15]) {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, 840);
          await tester.pumpWidget(
            MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(width, 840),
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Nama Lengkap'), findsOneWidget);
          expect(find.text('Nomor HP'), findsOneWidget);
          if (role == 'student') {
            expect(find.text('NIM'), findsOneWidget);
            expect(find.text('Program Studi'), findsOneWidget);
            expect(find.text('Semester'), findsOneWidget);
          } else {
            expect(find.text('NIP'), findsOneWidget);
            expect(find.text('NIDN'), findsOneWidget);
          }
          await tester.ensureVisible(find.text('Simpan Perubahan'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });
  }
}
