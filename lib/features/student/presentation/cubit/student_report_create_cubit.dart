import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_report_service.dart';
import '../../domain/student_models.dart';
import 'student_report_create_state.dart';

class StudentReportCreateCubit extends Cubit<StudentReportCreateState> {
  StudentReportCreateCubit(this._service)
    : super(const StudentReportCreateState());
  final StudentReportService _service;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: StudentReportCreateStatus.loading,
        errorMessage: '',
      ),
    );
    try {
      final labs = await _service.loadLaboratories();
      final firstId = labs.isEmpty ? '' : labs.first.id;
      final assets = firstId.isEmpty
          ? <StudentAsset>[]
          : await _service.loadAssets(firstId);
      emit(
        state.copyWith(
          status: StudentReportCreateStatus.ready,
          laboratories: labs,
          assets: assets,
          labId: firstId,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StudentReportCreateStatus.failure,
          errorMessage: 'Data laboratorium tidak dapat dimuat.',
        ),
      );
    }
  }

  Future<void> selectLaboratory(String labId) async {
    emit(
      state.copyWith(
        status: StudentReportCreateStatus.loading,
        labId: labId,
        clearAsset: true,
        assets: const [],
      ),
    );
    try {
      final assets = await _service.loadAssets(labId);
      emit(
        state.copyWith(status: StudentReportCreateStatus.ready, assets: assets),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StudentReportCreateStatus.failure,
          errorMessage: 'Aset laboratorium tidak dapat dimuat.',
        ),
      );
    }
  }

  void setAsset(String? value) =>
      emit(state.copyWith(assetId: value, clearAsset: value == null));
  void setCategory(String value) => emit(state.copyWith(category: value));
  void setSeverity(String value) => emit(state.copyWith(severity: value));
  void setTitle(String value) => emit(state.copyWith(title: value));
  void setDescription(String value) => emit(state.copyWith(description: value));
  void setLocation(String value) => emit(state.copyWith(location: value));

  Future<void> submit() async {
    if (state.status == StudentReportCreateStatus.saving) return;
    final validation = StudentReportService.validate(
      labId: state.labId,
      category: state.category,
      title: state.title,
      description: state.description,
      location: state.location,
      severity: state.severity,
    );
    if (validation != null) {
      emit(state.copyWith(errorMessage: validation));
      return;
    }
    if (state.assetId != null &&
        !state.assets.any((asset) => asset.id == state.assetId)) {
      emit(
        state.copyWith(
          errorMessage: 'Pilih aset dari laboratorium yang dipilih.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: StudentReportCreateStatus.saving,
        errorMessage: '',
      ),
    );
    try {
      final id = await _service.createReport(
        labId: state.labId,
        assetId: state.assetId,
        category: state.category,
        title: state.title,
        description: state.description,
        location: state.location,
        severity: state.severity,
      );
      emit(
        state.copyWith(status: StudentReportCreateStatus.success, reportId: id),
      );
    } on StudentReportException catch (error) {
      emit(
        state.copyWith(
          status: StudentReportCreateStatus.ready,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: StudentReportCreateStatus.ready,
          errorMessage: 'Laporan gagal dikirim. Coba lagi.',
        ),
      );
    }
  }
}
