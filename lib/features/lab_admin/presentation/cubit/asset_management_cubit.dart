import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../asset/data/asset_service.dart';
import '../../../asset/domain/laboratory_asset.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import 'asset_management_state.dart';

class AssetManagementCubit extends Cubit<AssetManagementState> {
  AssetManagementCubit(this._membershipService, this._assetService)
    : super(const AssetManagementState());

  final LabMembershipService _membershipService;
  final AssetService _assetService;
  StreamSubscription<List<LabMembership>>? _membershipSubscription;
  StreamSubscription<List<Laboratory>>? _laboratorySubscription;
  StreamSubscription<List<LaboratoryAsset>>? _assetSubscription;
  List<LabMembership> _memberships = const [];
  List<Laboratory> _activeLaboratories = const [];
  bool _membershipsReady = false;
  bool _laboratoriesReady = false;

  void start() {
    if (_membershipSubscription != null || _laboratorySubscription != null) {
      return;
    }
    emit(
      state.copyWith(status: AssetManagementStatus.loading, errorMessage: ''),
    );
    _membershipSubscription = _membershipService
        .watchCurrentLabAdminMemberships()
        .listen(
          (memberships) {
            _memberships = memberships;
            _membershipsReady = true;
            _refreshLaboratories();
          },
          onError: (_) => _fail(
            'Assignment laboratorium tidak dapat dimuat. Periksa koneksi.',
          ),
        );
    _laboratorySubscription = _membershipService
        .watchActiveLaboratories()
        .listen(
          (laboratories) {
            _activeLaboratories = laboratories;
            _laboratoriesReady = true;
            _refreshLaboratories();
          },
          onError: (_) =>
              _fail('Data laboratorium tidak dapat dimuat. Periksa koneksi.'),
        );
  }

  void _refreshLaboratories() {
    if (!_membershipsReady || !_laboratoriesReady) return;
    if (_memberships.isEmpty) {
      unawaited(_assetSubscription?.cancel());
      _assetSubscription = null;
      emit(
        state.copyWith(
          status: AssetManagementStatus.noMembership,
          laboratories: const [],
          assets: const [],
        ),
      );
      return;
    }
    final labIds = _memberships.map((membership) => membership.labId).toSet();
    final laboratories =
        _activeLaboratories
            .where((laboratory) => labIds.contains(laboratory.id))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    if (laboratories.isEmpty) {
      unawaited(_assetSubscription?.cancel());
      _assetSubscription = null;
      emit(
        state.copyWith(
          status: AssetManagementStatus.noLaboratory,
          laboratories: const [],
          assets: const [],
        ),
      );
      return;
    }
    final oldLabId = state.selectedLabId;
    final selectedLabId = laboratories.any((lab) => lab.id == oldLabId)
        ? oldLabId!
        : laboratories.first.id;
    emit(
      state.copyWith(
        status:
            state.status == AssetManagementStatus.initial ||
                state.status == AssetManagementStatus.loading
            ? AssetManagementStatus.loading
            : state.status,
        laboratories: laboratories,
        selectedLabId: selectedLabId,
      ),
    );
    if (selectedLabId != oldLabId || _assetSubscription == null) {
      _watchAssets(selectedLabId);
    }
  }

  void _watchAssets(String labId) {
    unawaited(_assetSubscription?.cancel());
    _assetSubscription = _assetService
        .watchAssetsByLaboratory(labId)
        .listen(
          (assets) => emit(
            state.copyWith(
              status: AssetManagementStatus.loaded,
              assets: assets,
              errorMessage: '',
            ),
          ),
          onError: (_) =>
              _fail('Inventaris tidak dapat dimuat. Periksa koneksi.'),
        );
  }

  void selectLaboratory(String labId) {
    if (state.selectedLabId == labId ||
        !state.laboratories.any((lab) => lab.id == labId)) {
      return;
    }
    emit(
      state.copyWith(
        selectedLabId: labId,
        searchQuery: '',
        statusFilter: AssetStatusFilter.all,
        assets: const [],
      ),
    );
    _watchAssets(labId);
  }

  void updateSearch(String query) => emit(state.copyWith(searchQuery: query));

  void selectStatus(AssetStatusFilter filter) =>
      emit(state.copyWith(statusFilter: filter));

  Future<void> retry() async {
    await _membershipSubscription?.cancel();
    await _laboratorySubscription?.cancel();
    await _assetSubscription?.cancel();
    _membershipSubscription = null;
    _laboratorySubscription = null;
    _assetSubscription = null;
    _membershipsReady = false;
    _laboratoriesReady = false;
    start();
  }

  void _fail(String message) => emit(
    state.copyWith(
      status: AssetManagementStatus.failure,
      errorMessage: message,
    ),
  );

  @override
  Future<void> close() async {
    await _membershipSubscription?.cancel();
    await _laboratorySubscription?.cancel();
    await _assetSubscription?.cancel();
    return super.close();
  }
}
