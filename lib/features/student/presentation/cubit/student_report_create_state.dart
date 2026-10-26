import '../../domain/student_models.dart';

enum StudentReportCreateStatus { loading, ready, saving, success, failure }

class StudentReportCreateState {
  const StudentReportCreateState({
    this.status = StudentReportCreateStatus.loading,
    this.laboratories = const [],
    this.assets = const [],
    this.labId = '',
    this.assetId,
    this.category = 'other',
    this.severity = 'normal',
    this.title = '',
    this.description = '',
    this.location = '',
    this.reportId,
    this.errorMessage = '',
  });

  final StudentReportCreateStatus status;
  final List<StudentLaboratory> laboratories;
  final List<StudentAsset> assets;
  final String labId;
  final String? assetId;
  final String category;
  final String severity;
  final String title;
  final String description;
  final String location;
  final String? reportId;
  final String errorMessage;

  StudentReportCreateState copyWith({
    StudentReportCreateStatus? status,
    List<StudentLaboratory>? laboratories,
    List<StudentAsset>? assets,
    String? labId,
    String? assetId,
    bool clearAsset = false,
    String? category,
    String? severity,
    String? title,
    String? description,
    String? location,
    String? reportId,
    String? errorMessage,
  }) => StudentReportCreateState(
    status: status ?? this.status,
    laboratories: laboratories ?? this.laboratories,
    assets: assets ?? this.assets,
    labId: labId ?? this.labId,
    assetId: clearAsset ? null : assetId ?? this.assetId,
    category: category ?? this.category,
    severity: severity ?? this.severity,
    title: title ?? this.title,
    description: description ?? this.description,
    location: location ?? this.location,
    reportId: reportId ?? this.reportId,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
