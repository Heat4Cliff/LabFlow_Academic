import '../../domain/student_notification.dart';

enum StudentNotificationStatus { initial, loading, loaded, failure }

class StudentNotificationState {
  const StudentNotificationState({
    this.status = StudentNotificationStatus.initial,
    this.notifications = const [],
    this.readingIds = const {},
    this.errorMessage = '',
  });
  final StudentNotificationStatus status;
  final List<StudentNotification> notifications;
  final Set<String> readingIds;
  final String errorMessage;
  int get unreadCount => notifications.where((item) => !item.read).length;

  StudentNotificationState copyWith({
    StudentNotificationStatus? status,
    List<StudentNotification>? notifications,
    Set<String>? readingIds,
    String? errorMessage,
  }) => StudentNotificationState(
    status: status ?? this.status,
    notifications: notifications ?? this.notifications,
    readingIds: readingIds ?? this.readingIds,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
