import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';
import 'package:labflow/features/profile/data/profile_edit_service.dart';
import 'package:labflow/features/profile/presentation/cubit/profile_edit_cubit.dart';

class _ProfileEditor implements ProfileEditor {
  UserProfile profile = const UserProfile(
    uid: 'student-1',
    email: 'student@example.invalid',
    fullName: 'Nama Awal',
    role: 'student',
    status: 'active',
  );
  String? savedName;

  @override
  Future<UserProfile> load() async => profile;

  @override
  Future<UserProfile> saveFullName(String fullName) async {
    savedName = fullName;
    profile = UserProfile(
      uid: profile.uid,
      email: profile.email,
      fullName: fullName.trim(),
      role: profile.role,
      status: profile.status,
    );
    return profile;
  }
}

void main() {
  test('profile edit trims name and keeps identity fields read-only', () async {
    final service = _ProfileEditor();
    final cubit = ProfileEditCubit(service);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.status, ProfileEditStatus.editing);

    cubit.setFullName('  Nama Baru  ');
    await cubit.save();
    expect(cubit.state.status, ProfileEditStatus.success);
    expect(service.savedName, '  Nama Baru  ');
    expect(cubit.state.profile!.fullName, 'Nama Baru');
    expect(cubit.state.profile!.uid, 'student-1');
    expect(cubit.state.profile!.role, 'student');
  });

  test('empty or overlong fullName never invokes update', () async {
    final service = _ProfileEditor();
    final cubit = ProfileEditCubit(service);
    addTearDown(cubit.close);
    await cubit.load();
    cubit.setFullName('   ');
    await cubit.save();
    expect(cubit.state.errorMessage, 'Nama lengkap wajib diisi.');
    expect(service.savedName, isNull);

    cubit.setFullName('a' * 101);
    await cubit.save();
    expect(cubit.state.errorMessage, 'Nama lengkap maksimal 100 karakter.');
    expect(service.savedName, isNull);
  });
}
