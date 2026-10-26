import '../../../reporting/domain/lab_report.dart';

enum StudentReportDetailStatus { initial, loading, loaded, failure }

class StudentReportDetailState {
  const StudentReportDetailState({
    this.status = StudentReportDetailStatus.initial,
    this.report,
    this.laboratoryName = 'Laboratorium',
    this.errorMessage = '',
  });
  final StudentReportDetailStatus status;
  final LabReport? report;
  final String laboratoryName;
  final String errorMessage;
  StudentReportDetailState copyWith({
    StudentReportDetailStatus? status,
    LabReport? report,
    String? laboratoryName,
    String? errorMessage,
  }) => StudentReportDetailState(
    status: status ?? this.status,
    report: report ?? this.report,
    laboratoryName: laboratoryName ?? this.laboratoryName,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
