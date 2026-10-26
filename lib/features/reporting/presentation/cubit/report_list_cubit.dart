import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/report_service.dart';
import '../../domain/lab_report.dart';
import 'report_list_state.dart';

class ReportListCubit extends Cubit<ReportListState> {
  ReportListCubit(this._membershipService, this._reportService)
    : super(const ReportListState());

  final LabMembershipService _membershipService;
  final ReportService _reportService;

  StreamSubscription<List<LabMembership>>? _membershipSubscription;
  StreamSubscription<List<Laboratory>>? _laboratorySubscription;
  StreamSubscription<List<LabReport>>? _reportSubscription;

  List<LabMembership> _memberships = const <LabMembership>[];
  List<Laboratory> _allLaboratories = const <Laboratory>[];

  void start() {
    emit(state.copyWith(status: ReportListStatus.loading, errorMessage: ''));

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
                status: ReportListStatus.failure,
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
                status: ReportListStatus.failure,
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
      _reportSubscription?.cancel();

      emit(
        state.copyWith(
          status: ReportListStatus.loaded,
          laboratories: const <Laboratory>[],
          reports: const <LabReport>[],
          reportsLoading: false,
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
        status: ReportListStatus.loaded,
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
        reports: const <LabReport>[],
        reportsLoading: true,
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
    _reportSubscription?.cancel();

    emit(state.copyWith(reportsLoading: true));

    _reportSubscription = _reportService
        .watchByLaboratory(laboratoryId)
        .listen(
          (reports) {
            if (state.selectedLabId != laboratoryId) {
              return;
            }

            emit(
              state.copyWith(
                status: ReportListStatus.loaded,
                reports: reports,
                reportsLoading: false,
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
                status: ReportListStatus.failure,
                reportsLoading: false,
                errorMessage: 'Daftar laporan tidak dapat dimuat.',
              ),
            );
          },
        );
  }

  @override
  Future<void> close() async {
    await _membershipSubscription?.cancel();
    await _laboratorySubscription?.cancel();
    await _reportSubscription?.cancel();
    return super.close();
  }
}
