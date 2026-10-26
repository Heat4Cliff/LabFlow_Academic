import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/maintenance_service.dart';
import '../../domain/maintenance_record.dart';
import 'maintenance_detail_state.dart';

class MaintenanceDetailCubit extends Cubit<MaintenanceDetailState> {
  MaintenanceDetailCubit(this._service) : super(const MaintenanceDetailState());

  final MaintenanceService _service;

  Future<void> load(String maintenanceId) async {
    emit(
      state.copyWith(status: MaintenanceDetailStatus.loading, errorMessage: ''),
    );

    try {
      final record = await _service.getRecord(maintenanceId);

      emit(
        state.copyWith(
          status: MaintenanceDetailStatus.loaded,
          record: record,
          isProcessing: false,
          errorMessage: '',
        ),
      );
    } on MaintenanceException catch (error) {
      emit(
        state.copyWith(
          status: MaintenanceDetailStatus.failure,
          errorMessage: error.message,
          isProcessing: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MaintenanceDetailStatus.failure,
          errorMessage: 'Detail maintenance tidak dapat dimuat.',
          isProcessing: false,
        ),
      );
    }
  }

  Future<void> startMaintenance() async {
    final record = state.record;

    if (record == null || state.isProcessing) {
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: MaintenanceDetailActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      final updated = await _service.startMaintenance(record.id);

      emit(
        state.copyWith(
          status: MaintenanceDetailStatus.loaded,
          record: updated,
          isProcessing: false,
          actionStatus: MaintenanceDetailActionStatus.success,
          actionMessage: 'Maintenance mulai dikerjakan.',
        ),
      );
    } on MaintenanceException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: MaintenanceDetailActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: MaintenanceDetailActionStatus.failure,
          actionMessage: 'Maintenance gagal dimulai.',
        ),
      );
    }
  }

  Future<void> completeMaintenance({
    required MaintenanceResolution resolution,
    required String note,
  }) async {
    final record = state.record;

    if (record == null || state.isProcessing) {
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: MaintenanceDetailActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      final updated = await _service.completeMaintenance(
        maintenanceId: record.id,
        resolution: resolution,
        note: note,
      );

      emit(
        state.copyWith(
          status: MaintenanceDetailStatus.loaded,
          record: updated,
          isProcessing: false,
          actionStatus: MaintenanceDetailActionStatus.success,
          actionMessage: resolution == MaintenanceResolution.repaired
              ? 'Maintenance selesai dan unit kembali tersedia.'
              : 'Maintenance selesai. Unit ditandai tidak dapat diperbaiki.',
        ),
      );
    } on MaintenanceException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: MaintenanceDetailActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: MaintenanceDetailActionStatus.failure,
          actionMessage: 'Maintenance gagal diselesaikan.',
        ),
      );
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        actionStatus: MaintenanceDetailActionStatus.idle,
        actionMessage: '',
      ),
    );
  }
}
