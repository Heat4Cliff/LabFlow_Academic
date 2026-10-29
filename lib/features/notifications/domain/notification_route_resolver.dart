class NotificationRouteResolver {
  const NotificationRouteResolver();

  String resolve({
    required String role,
    required Map<String, Object?> payload,
  }) {
    final entityType = _value(payload['entityType'] ?? payload['targetType']);
    final entityId = _value(payload['entityId'] ?? payload['targetId']);
    if (entityId.isNotEmpty) {
      final id = Uri.encodeComponent(entityId);
      if (entityType == 'borrow_request') {
        if (role == 'student') return '/student/borrowing/$id';
        if (role == 'lab_admin') return '/lab-admin/borrowing/$id';
      }
      if (entityType == 'report') {
        if (role == 'student') return '/student/reports/$id';
        if (role == 'lab_admin') return '/lab-admin/reports/$id';
      }
      if (entityType == 'admin_activity' && role == 'superadmin') {
        return '/superadmin/activity';
      }
    }
    return switch (role) {
      'student' => '/student/notifications',
      'lab_admin' => '/lab-admin/notifications',
      'superadmin' => '/superadmin/notifications',
      _ => '/login',
    };
  }

  String resolvePath({
    required String role,
    required String entityType,
    required String entityId,
  }) => resolve(
    role: role,
    payload: {'entityType': entityType, 'entityId': entityId},
  );

  String _value(Object? value) => value is String ? value.trim() : '';
}
