import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/asset/data/asset_service.dart';
import 'package:labflow/features/asset/domain/laboratory_asset.dart';
import 'package:labflow/features/lab_admin/presentation/cubit/asset_management_cubit.dart';
import 'package:labflow/features/lab_admin/presentation/cubit/asset_management_state.dart';
import 'package:labflow/features/laboratory/data/lab_membership_service.dart';
import 'package:labflow/features/laboratory/domain/lab_membership.dart';
import 'package:labflow/features/laboratory/domain/laboratory.dart';
import 'package:mocktail/mocktail.dart';

class _MockLabMembershipService extends Mock implements LabMembershipService {}

class _MockAssetService extends Mock implements AssetService {}

void main() {
  test(
    'AssetManagementCubit combines its streams and cancels on close',
    () async {
      final memberships = _MockLabMembershipService();
      final assets = _MockAssetService();
      final lab = Laboratory(
        id: 'lab-1',
        name: 'Lab IoT',
        code: 'IOT',
        description: '',
        location: 'Gedung A',
        status: 'active',
      );
      when(() => memberships.watchCurrentLabAdminMemberships()).thenAnswer(
        (_) => Stream.value([
          const LabMembership(
            id: 'admin-1__lab-1',
            userId: 'admin-1',
            labId: 'lab-1',
            role: 'lab_admin',
            active: true,
          ),
        ]),
      );
      when(() => memberships.watchActiveLaboratories())
          .thenAnswer((_) => Stream.value([lab]));
      when(() => assets.watchAssetsByLaboratory('lab-1'))
          .thenAnswer((_) => Stream.value(const <LaboratoryAsset>[]));

      final cubit = AssetManagementCubit(memberships, assets)..start();
      await expectLater(
        cubit.stream,
        emitsThrough(
          isA<AssetManagementState>().having(
            (state) => state.status,
            'status',
            AssetManagementStatus.loaded,
          ),
        ),
      );

      expect(cubit.state.selectedLaboratory?.name, 'Lab IoT');
      await cubit.close();
      verify(() => assets.watchAssetsByLaboratory('lab-1')).called(1);
    },
  );

  test('inventory filters search and status outside the page', () {
    const router = LaboratoryAsset(
      id: 'a1',
      labId: 'lab-1',
      code: 'RTR-1',
      name: 'Router Utama',
      category: 'network',
      description: '',
      location: 'Rak 1',
      stock: 1,
      status: 'available',
      condition: 'good',
      qrValue: 'asset:a1',
    );
    const laptop = LaboratoryAsset(
      id: 'a2',
      labId: 'lab-1',
      code: 'LTP-1',
      name: 'Laptop',
      category: 'computer',
      description: '',
      location: 'Meja 2',
      stock: 1,
      status: 'borrowed',
      condition: 'good',
      qrValue: 'asset:a2',
    );
    final state = AssetManagementState(
      assets: const [router, laptop],
      searchQuery: 'router',
      statusFilter: AssetStatusFilter.available,
    );

    expect(state.filteredAssets, [router]);
  });
}
