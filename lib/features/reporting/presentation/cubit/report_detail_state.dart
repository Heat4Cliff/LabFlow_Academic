import '../../domain/lab_report.dart';

enum ReportDetailStatus { initial, loading, loaded, failure }

enum ReportDetailActionStatus { idle, success, warning, failure }

class ReportDetailState {
  const ReportDetailState({
    this.status = ReportDetailStatus.initial,
    this.report,
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = ReportDetailActionStatus.idle,
    this.actionMessage = '',
  });

  final ReportDetailStatus status;
  final LabReport? report;
  final bool isProcessing;
  final String errorMessage;
  final ReportDetailActionStatus actionStatus;
  final String actionMessage;

  ReportDetailState copyWith({
    ReportDetailStatus? status,
    LabReport? report,
    bool? isProcessing,
    String? errorMessage,
    ReportDetailActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return ReportDetailState(
      status: status ?? this.status,
      report: report ?? this.report,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
