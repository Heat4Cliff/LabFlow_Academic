import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_service.dart';
import 'student_catalog_state.dart';
import 'student_data_state.dart';

class StudentCatalogCubit extends Cubit<StudentCatalogState> {
  StudentCatalogCubit(this._service) : super(const StudentCatalogState());

  final StudentService _service;

  Future<void> load() async {
    emit(state.copyWith(status: StudentLoadStatus.loading, errorMessage: ''));

    try {
      final results = await Future.wait<dynamic>([
        _service.loadAssets(),
        _service.loadActiveLaboratories(),
      ]);

      emit(
        state.copyWith(
          status: StudentLoadStatus.success,
          assets: results[0],
          laboratories: results[1],
          errorMessage: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: StudentLoadStatus.failure,
          errorMessage: error is StudentServiceException
              ? error.message
              : 'Katalog aset tidak dapat dimuat.',
        ),
      );
    }
  }

  void setQuery(String value) {
    emit(state.copyWith(query: value));
  }

  void setCategory(String value) {
    emit(state.copyWith(category: value));
  }

  void setLaboratory(String value) {
    emit(state.copyWith(labId: value));
  }
}
