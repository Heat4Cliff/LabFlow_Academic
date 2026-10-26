import '../../domain/maintenance_record.dart';

enum MaintenanceDetailStatus { initial, loading, loaded, failure }

enum MaintenanceDetailActionStatus { idle, success, warning, failure }

class MaintenanceDetailState {
  const MaintenanceDetailState({
    this.status = MaintenanceDetailStatus.initial,
    this.record,
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = MaintenanceDetailActionStatus.idle,
    this.actionMessage = '',
  });

  final MaintenanceDetailStatus status;
  final MaintenanceRecord? record;
  final bool isProcessing;
  final String errorMessage;
  final MaintenanceDetailActionStatus actionStatus;
  final String actionMessage;

  MaintenanceDetailState copyWith({
    MaintenanceDetailStatus? status,
    MaintenanceRecord? record,
    bool? isProcessing,
    String? errorMessage,
    MaintenanceDetailActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return MaintenanceDetailState(
      status: status ?? this.status,
      record: record ?? this.record,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
