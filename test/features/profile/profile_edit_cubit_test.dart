import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
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
  String? savedPhone;
  XFile? savedPhoto;
  String? savedNim;
  String? savedProgram;
  int? savedSemester;

  @override
  Future<UserProfile> load() async => profile;

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
  }) async {
    savedName = fullName;
    savedPhone = phoneNumber;
    savedPhoto = photo;
    savedNim = nim;
    savedProgram = studyProgram;
    savedSemester = semester;
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
  test('profile edit trims name and passes student profile fields', () async {
    final service = _ProfileEditor();
    final cubit = ProfileEditCubit(service);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.status, ProfileEditStatus.editing);

    cubit.setFullName('  Nama Baru  ');
    cubit.setNim('  000123  ');
    cubit.setStudyProgram(' Informatika ');
    cubit.setSemester(7);
    await cubit.save();
    expect(cubit.state.status, ProfileEditStatus.success);
    expect(service.savedName, '  Nama Baru  ');
    expect(service.savedNim, '  000123  ');
    expect(service.savedProgram, ' Informatika ');
    expect(service.savedSemester, 7);
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

  test(
    'saving preserves phone and selected photo in the saving state',
    () async {
      final service = _ProfileEditor();
      final cubit = ProfileEditCubit(service);
      addTearDown(cubit.close);
      await cubit.load();
      final photo = XFile('profile.jpg');
      cubit.setPhoneNumber('+62 812 1234');
      cubit.setPhoto(photo);
      await cubit.save();
      expect(service.savedPhone, '+62 812 1234');
      expect(service.savedPhoto, same(photo));
      expect(cubit.state.status, ProfileEditStatus.success);
    },
  );
}
