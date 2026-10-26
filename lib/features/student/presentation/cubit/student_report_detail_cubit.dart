import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reporting/domain/lab_report.dart';
import '../../data/student_report_service.dart';
import 'student_report_detail_state.dart';

class StudentReportDetailCubit extends Cubit<StudentReportDetailState> {
  StudentReportDetailCubit(this._service)
    : super(const StudentReportDetailState());
  final StudentReportService _service;
  StreamSubscription<LabReport>? _subscription;
  String? _currentLabId;

  void watch(String reportId) {
    emit(
      state.copyWith(
        status: StudentReportDetailStatus.loading,
        errorMessage: '',
      ),
    );
    _subscription?.cancel();
    _subscription = _service.watchOwnReport(reportId).listen(
      (report) {
        _currentLabId = report.labId;
        emit(
          state.copyWith(
            status: StudentReportDetailStatus.loaded,
            report: report,
          ),
        );
        unawaited(_loadLaboratoryName(report.labId));
      },
      onError: (_) => emit(
        state.copyWith(
          status: StudentReportDetailStatus.failure,
          errorMessage: 'Laporan tidak ditemukan atau tidak dapat dimuat.',
        ),
      ),
    );
  }

  Future<void> _loadLaboratoryName(String labId) async {
    try {
      final name = await _service.loadLaboratoryName(labId);
      if (isClosed || _currentLabId != labId) return;
      emit(state.copyWith(laboratoryName: name));
    } catch (_) {
      if (isClosed || _currentLabId != labId) return;
      emit(state.copyWith(laboratoryName: 'Laboratorium'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
