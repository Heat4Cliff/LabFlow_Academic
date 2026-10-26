import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import 'student_data_state.dart';

class StudentReportsCubit extends Cubit<StudentDataState<List<StudentReport>>> {
  StudentReportsCubit(this._service)
    : super(const StudentDataState<List<StudentReport>>());

  final StudentService _service;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      final reports = await _service.loadReports();

      emit(
        StudentDataState<List<StudentReport>>(
          status: StudentLoadStatus.success,
          data: reports,
        ),
      );
    } catch (error) {
      emit(
        StudentDataState<List<StudentReport>>(
          status: StudentLoadStatus.failure,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Laporan tidak dapat dimuat.',
        ),
      );
    }
  }
}
