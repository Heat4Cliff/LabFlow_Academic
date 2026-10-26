import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/report_service.dart';
import 'report_detail_state.dart';

class ReportDetailCubit extends Cubit<ReportDetailState> {
  ReportDetailCubit(this._service) : super(const ReportDetailState());

  final ReportService _service;

  Future<void> load(String reportId) async {
    emit(state.copyWith(status: ReportDetailStatus.loading, errorMessage: ''));

    try {
      final report = await _service.getReport(reportId);

      emit(
        state.copyWith(
          status: ReportDetailStatus.loaded,
          report: report,
          isProcessing: false,
        ),
      );
    } on ReportException catch (error) {
      emit(
        state.copyWith(
          status: ReportDetailStatus.failure,
          errorMessage: error.message,
          isProcessing: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ReportDetailStatus.failure,
          errorMessage: 'Detail laporan tidak dapat dimuat.',
          isProcessing: false,
        ),
      );
    }
  }

  Future<void> setPriority(String priority) async {
    final report = state.report;

    if (report == null || state.isProcessing) {
      return;
    }

    emit(state.copyWith(isProcessing: true));

    try {
      final updated = await _service.updatePriority(
        reportId: report.id,
        priority: priority,
      );

      emit(
        state.copyWith(
          report: updated,
          isProcessing: false,
          actionStatus: ReportDetailActionStatus.success,
          actionMessage: 'Priority laporan diperbarui.',
        ),
      );
    } on ReportException catch (error) {
      _emitWarning(error.message);
    } catch (_) {
      _emitFailure('Priority laporan gagal diperbarui.');
    }
  }

  Future<void> acknowledge() async {
    await _runAction(
      action: (id) => _service.acknowledge(id),
      successMessage: 'Laporan diterima dan siap ditangani.',
    );
  }

  Future<void> startProgress() async {
    await _runAction(
      action: (id) => _service.startProgress(id),
      successMessage: 'Penanganan laporan dimulai.',
    );
  }

  Future<void> resolve(String response) async {
    final report = state.report;

    if (report == null || state.isProcessing) {
      return;
    }

    emit(state.copyWith(isProcessing: true));

    try {
      final updated = await _service.resolve(
        reportId: report.id,
        response: response,
      );

      emit(
        state.copyWith(
          report: updated,
          isProcessing: false,
          actionStatus: ReportDetailActionStatus.success,
          actionMessage: 'Laporan berhasil diselesaikan.',
        ),
      );
    } on ReportException catch (error) {
      _emitWarning(error.message);
    } catch (_) {
      _emitFailure('Laporan gagal diselesaikan.');
    }
  }

  Future<void> reject(String response) async {
    final report = state.report;

    if (report == null || state.isProcessing) {
      return;
    }

    emit(state.copyWith(isProcessing: true));

    try {
      final updated = await _service.reject(
        reportId: report.id,
        response: response,
      );

      emit(
        state.copyWith(
          report: updated,
          isProcessing: false,
          actionStatus: ReportDetailActionStatus.success,
          actionMessage: 'Laporan ditolak dan alasan telah disimpan.',
        ),
      );
    } on ReportException catch (error) {
      _emitWarning(error.message);
    } catch (_) {
      _emitFailure('Laporan gagal ditolak.');
    }
  }

  Future<void> closeResolved() async {
    await _runAction(
      action: (id) => _service.closeResolved(id),
      successMessage: 'Laporan ditutup.',
    );
  }

  Future<void> _runAction({
    required Future<dynamic> Function(String id) action,
    required String successMessage,
  }) async {
    final report = state.report;

    if (report == null || state.isProcessing) {
      return;
    }

    emit(state.copyWith(isProcessing: true));

    try {
      final updated = await action(report.id);

      emit(
        state.copyWith(
          report: updated,
          isProcessing: false,
          actionStatus: ReportDetailActionStatus.success,
          actionMessage: successMessage,
        ),
      );
    } on ReportException catch (error) {
      _emitWarning(error.message);
    } catch (_) {
      _emitFailure('Operasi laporan gagal diproses.');
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        actionStatus: ReportDetailActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void _emitWarning(String message) {
    emit(
      state.copyWith(
        isProcessing: false,
        actionStatus: ReportDetailActionStatus.warning,
        actionMessage: message,
      ),
    );
  }

  void _emitFailure(String message) {
    emit(
      state.copyWith(
        isProcessing: false,
        actionStatus: ReportDetailActionStatus.failure,
        actionMessage: message,
      ),
    );
  }
}
