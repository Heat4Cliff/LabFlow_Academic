const studentBorrowRequestFormPath = '/student/borrowing/request';

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
    'report' => '/student/reports/${Uri.encodeComponent(id)}',
    _ => null,
  };
}

String? studentNotificationBadgeLabel(int unreadCount) {
  if (unreadCount <= 0) return null;
  return unreadCount > 9 ? '9+' : '$unreadCount';
}
