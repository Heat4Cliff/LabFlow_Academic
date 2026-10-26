import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/auth/domain/user_profile.dart';
import 'package:labflow/features/superadmin/data/user_management_service.dart';
import 'package:labflow/features/superadmin/presentation/cubit/user_directory_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _UserManagementServiceMock extends Mock
    implements UserManagementService {}

void main() {
  late _UserManagementServiceMock service;
  late StreamController<List<UserProfile>> controller;

  const users = [
    UserProfile(
      uid: '1',
      email: 'siswa@example.com',
      fullName: 'Siswa Lab',
      role: 'student',
      status: 'active',
    ),
    UserProfile(
      uid: '2',
      email: 'admin@example.com',
      fullName: 'Admin Lab',
      role: 'lab_admin',
      status: 'suspended',
    ),
  ];

  setUp(() {
    service = _UserManagementServiceMock();
    controller = StreamController<List<UserProfile>>.broadcast();
    when(() => service.watchUsers()).thenAnswer((_) => controller.stream);
  });

  tearDown(() async {
    await controller.close();
  });

  test('mengelola stream satu kali dan menerapkan filter pencarian', () async {
    final cubit = UserDirectoryCubit(service);
    cubit.start();
    cubit.start();

    controller.add(users);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isA<UserDirectoryLoaded>());
    expect((cubit.state as UserDirectoryLoaded).visibleUsers, hasLength(2));

    cubit.setQuery('admin');
    cubit.setRole('lab_admin');
    cubit.setStatus('suspended');

    final filtered = cubit.state as UserDirectoryLoaded;
    expect(filtered.visibleUsers, hasLength(1));
    expect(filtered.visibleUsers.single.uid, '2');
    verify(() => service.watchUsers()).called(1);

    await cubit.close();
    expect(controller.hasListener, isFalse);
  });
}
