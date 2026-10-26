import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/maintenance_service.dart';
import '../../domain/maintenance_record.dart';
import 'maintenance_list_state.dart';

class MaintenanceListCubit extends Cubit<MaintenanceListState> {
  MaintenanceListCubit(this._membershipService, this._maintenanceService)
    : super(const MaintenanceListState());

  final LabMembershipService _membershipService;
  final MaintenanceService _maintenanceService;

  StreamSubscription<List<LabMembership>>? _membershipSubscription;
  StreamSubscription<List<Laboratory>>? _laboratorySubscription;
  StreamSubscription<List<MaintenanceRecord>>? _recordSubscription;

  List<LabMembership> _memberships = const <LabMembership>[];
  List<Laboratory> _allLaboratories = const <Laboratory>[];

  void start() {
    emit(
      state.copyWith(status: MaintenanceListStatus.loading, errorMessage: ''),
    );

    _membershipSubscription = _membershipService
        .watchCurrentLabAdminMemberships()
        .listen(
          (memberships) {
            _memberships = memberships.where((item) => item.active).toList();
            _rebuildLaboratories();
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: MaintenanceListStatus.failure,
                errorMessage: 'Assignment laboratorium tidak dapat dimuat.',
              ),
            );
          },
        );

    _laboratorySubscription = _membershipService
        .watchActiveLaboratories()
        .listen(
          (laboratories) {
            _allLaboratories = laboratories;
            _rebuildLaboratories();
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: MaintenanceListStatus.failure,
                errorMessage: 'Data laboratorium tidak dapat dimuat.',
              ),
            );
          },
        );
  }

  void _rebuildLaboratories() {
    final labIds = _memberships.map((item) => item.labId).toSet();

    final laboratories =
        _allLaboratories
            .where((laboratory) => labIds.contains(laboratory.id))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (laboratories.isEmpty) {
      _recordSubscription?.cancel();

      emit(
        state.copyWith(
          status: MaintenanceListStatus.loaded,
          laboratories: const <Laboratory>[],
          records: const <MaintenanceRecord>[],
          recordsLoading: false,
        ),
      );
      return;
    }

    var selectedLabId = state.selectedLabId;

    if (selectedLabId == null ||
        !laboratories.any((lab) => lab.id == selectedLabId)) {
      selectedLabId = laboratories.first.id;
    }

    emit(
      state.copyWith(
        status: MaintenanceListStatus.loaded,
        laboratories: laboratories,
        selectedLabId: selectedLabId,
      ),
    );

    _watchLab(selectedLabId);
  }

  void selectLaboratory(String laboratoryId) {
    final cleanId = laboratoryId.trim();

    if (cleanId.isEmpty || cleanId == state.selectedLabId) {
      return;
    }

    emit(
      state.copyWith(
        selectedLabId: cleanId,
        records: const <MaintenanceRecord>[],
        recordsLoading: true,
        errorMessage: '',
      ),
    );

    _watchLab(cleanId);
  }

  void setStatusFilter(String value) {
    emit(state.copyWith(statusFilter: value));
  }

  void setSearchQuery(String value) {
    emit(state.copyWith(searchQuery: value));
  }

  void _watchLab(String laboratoryId) {
    _recordSubscription?.cancel();

    emit(state.copyWith(recordsLoading: true));

    _recordSubscription = _maintenanceService
        .watchByLaboratory(laboratoryId)
        .listen(
          (records) {
            if (state.selectedLabId != laboratoryId) {
              return;
            }

            emit(
              state.copyWith(
                status: MaintenanceListStatus.loaded,
                records: records,
                recordsLoading: false,
                errorMessage: '',
              ),
            );
          },
          onError: (_) {
            if (state.selectedLabId != laboratoryId) {
              return;
            }

            emit(
              state.copyWith(
                status: MaintenanceListStatus.failure,
                recordsLoading: false,
                errorMessage: 'Daftar maintenance tidak dapat dimuat.',
              ),
            );
          },
        );
  }

  @override
  Future<void> close() async {
    await _membershipSubscription?.cancel();
    await _laboratorySubscription?.cancel();
    await _recordSubscription?.cancel();
    return super.close();
  }
}
