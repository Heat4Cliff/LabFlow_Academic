import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/presentation/navigation/labflow_back_fallback.dart';

const studentBorrowRequestFormPath = '/student/borrowing/request';

String studentReportDocumentPath(String documentId) {
  final id = documentId.trim();
  if (id.isEmpty) {
    throw ArgumentError.value(documentId, 'documentId', 'must not be empty');
  }
  return '/student/reports/${Uri.encodeComponent(id)}';
}

void openCreatedStudentReport(BuildContext context, String documentId) {
  context.pushReplacement(studentReportDocumentPath(documentId));
}

void studentPopOrGo(BuildContext context, String fallbackPath) {
  popOrGo(context, fallbackPath);
}

class StudentBackFallback extends LabFlowBackFallback {
  const StudentBackFallback({
    required super.fallbackPath,
    required super.child,
    super.key,
  });
}

String studentBorrowingDocumentPath(String documentId) {
  final id = documentId.trim();
  if (id.isEmpty) {
    throw ArgumentError.value(documentId, 'documentId', 'must not be empty');
  }
  return '/student/borrowing/${Uri.encodeComponent(id)}';
}

String? studentNotificationTargetPath({
  required String targetType,
  required String targetId,
}) {
  final id = targetId.trim();
  if (id.isEmpty) return null;

  return switch (targetType) {
    'borrow_request' => studentBorrowingDocumentPath(id),
    'report' => studentReportDocumentPath(id),
    _ => null,
  };
}

String? studentNotificationBadgeLabel(int unreadCount) {
  if (unreadCount <= 0) return null;
  return unreadCount > 9 ? '9+' : '$unreadCount';
}
