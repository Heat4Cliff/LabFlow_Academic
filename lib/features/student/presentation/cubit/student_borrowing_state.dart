import '../../domain/student_models.dart';
import 'student_data_state.dart';

class StudentBorrowingState {
  const StudentBorrowingState({
    this.status = StudentLoadStatus.initial,
    this.requests = const [],
    this.cancellingIds = const {},
    this.errorMessage = '',
    this.actionMessage = '',
  });

  final StudentLoadStatus status;
  final List<StudentBorrowRequest> requests;
  final Set<String> cancellingIds;
  final String errorMessage;
  final String actionMessage;

  StudentBorrowingState copyWith({
    StudentLoadStatus? status,
    List<StudentBorrowRequest>? requests,
    Set<String>? cancellingIds,
    String? errorMessage,
    String? actionMessage,
  }) {
    return StudentBorrowingState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      cancellingIds: cancellingIds ?? this.cancellingIds,
      errorMessage: errorMessage ?? this.errorMessage,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
