import '../../domain/student_borrowing_detail.dart';
import '../../../borrowing/domain/borrow_request.dart';

enum StudentBorrowingDetailStatus { initial, loading, loaded, failure }

class StudentBorrowingDetailState {
  const StudentBorrowingDetailState({
    this.status = StudentBorrowingDetailStatus.initial,
    this.request,
    this.items = const [],
    this.assignments = const [],
    this.laboratoryName = '',
    this.errorMessage = '',
  });

  final StudentBorrowingDetailStatus status;
  final BorrowRequest? request;
  final List<BorrowRequestItem> items;
  final List<StudentAssignedBorrowing> assignments;
  final String laboratoryName;
  final String errorMessage;

  StudentBorrowingDetailState copyWith({
    StudentBorrowingDetailStatus? status,
    BorrowRequest? request,
    List<BorrowRequestItem>? items,
    List<StudentAssignedBorrowing>? assignments,
    String? laboratoryName,
    String? errorMessage,
  }) => StudentBorrowingDetailState(
    status: status ?? this.status,
    request: request ?? this.request,
    items: items ?? this.items,
    assignments: assignments ?? this.assignments,
    laboratoryName: laboratoryName ?? this.laboratoryName,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
