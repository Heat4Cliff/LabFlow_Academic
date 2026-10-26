import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import 'student_data_state.dart';

class StudentHomeCubit extends Cubit<StudentDataState<StudentHomeData>> {
  StudentHomeCubit(this._service)
    : super(const StudentDataState<StudentHomeData>());

  final StudentService _service;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      final data = await _service.loadHomeData();

      emit(
        StudentDataState<StudentHomeData>(
          status: StudentLoadStatus.success,
          data: data,
        ),
      );
    } catch (error) {
      emit(
        StudentDataState<StudentHomeData>(
          status: StudentLoadStatus.failure,
          errorMessage: _message(error),
        ),
      );
    }
  }

  String _message(Object error) {
    if (error is StudentServiceException) {
      return error.message;
    }

    return 'Data Student tidak dapat dimuat. Periksa koneksi lalu coba lagi.';
  }
}
