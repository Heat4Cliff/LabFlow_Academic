import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import 'student_data_state.dart';

class StudentProfileCubit extends Cubit<StudentDataState<StudentProfile>> {
  StudentProfileCubit(this._service)
    : super(const StudentDataState<StudentProfile>());

  final StudentService _service;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      final profile = await _service.loadProfile();

      emit(
        StudentDataState<StudentProfile>(
          status: StudentLoadStatus.success,
          data: profile,
        ),
      );
    } catch (error) {
      emit(
        StudentDataState<StudentProfile>(
          status: StudentLoadStatus.failure,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Profil mahasiswa tidak dapat dimuat.',
        ),
      );
    }
  }

  Future<void> signOut() => _service.signOut();
}
