import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';

void main() {
  test('legacy user profile parses without optional identity fields', () {
    final profile = UserProfile.fromData('student-1', {
      'email': 'demo@example.invalid',
      'fullName': 'Student Demo',
      'role': 'student',
      'status': 'active',
    });

    expect(profile.uid, 'student-1');
    expect(profile.profilePhotoUrl, isNull);
    expect(profile.phoneNumber, isNull);
    expect(profile.nim, isNull);
    expect(profile.semester, isNull);
  });

  test('student and staff identity fields parse as optional strings', () {
    final profile = UserProfile.fromData('admin-1', {
      'email': '',
      'fullName': 'Admin Demo',
      'role': 'lab_admin',
      'status': 'active',
      'nip': '001234',
      'nidn': '009876',
      'phoneNumber': '+62 812',
      'profilePhotoUrl': 'https://example.invalid/avatar.jpg',
    });

    expect(profile.nip, '001234');
    expect(profile.nidn, '009876');
    expect(profile.phoneNumber, '+62 812');
  });
}
