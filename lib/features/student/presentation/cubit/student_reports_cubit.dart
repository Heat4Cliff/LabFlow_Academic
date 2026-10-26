import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_report_service.dart';
import '../../../reporting/domain/lab_report.dart';
import 'student_data_state.dart';

class StudentReportsCubit extends Cubit<StudentDataState<List<LabReport>>> {
  StudentReportsCubit(this._service)
    : super(const StudentDataState<List<LabReport>>());

  final StudentReportService _service;
  StreamSubscription<List<LabReport>>? _subscription;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      await _subscription?.cancel();
      _subscription = _service.watchOwnReports().listen(
        (reports) => emit(
          StudentDataState<List<LabReport>>(
            status: StudentLoadStatus.success,
            data: reports,
          ),
        ),
        onError: (_) => emit(
          StudentDataState<List<LabReport>>(
            status: StudentLoadStatus.failure,
            errorMessage: 'Laporan tidak dapat dimuat.',
          ),
        ),
      );
    } catch (_) {
      emit(
        StudentDataState<List<LabReport>>(
          status: StudentLoadStatus.failure,
          errorMessage: 'Laporan tidak dapat dimuat.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
