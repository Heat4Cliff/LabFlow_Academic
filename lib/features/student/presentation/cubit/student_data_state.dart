enum StudentLoadStatus { initial, loading, success, failure }

class StudentDataState<T> {
  const StudentDataState({
    this.status = StudentLoadStatus.initial,
    this.data,
    this.errorMessage = '',
  });

  final StudentLoadStatus status;
  final T? data;
  final String errorMessage;

  StudentDataState<T> copyWith({
    StudentLoadStatus? status,
    T? data,
    String? errorMessage,
  }) {
    return StudentDataState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
