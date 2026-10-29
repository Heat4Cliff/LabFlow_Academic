import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_notification.dart';

/// Converts authorized Firestore source documents into deterministic feed events.
/// Authorization still comes from Firestore Rules and source queries.
class NotificationFeedMapper {
  const NotificationFeedMapper._();

  static AppNotification? borrowing({
    required String role,
    required String uid,
    required Set<String> labIds,
    required String documentId,
    required Map<String, dynamic> data,
    required Set<String> readStateIds,
  }) {
    final labId = _string(data['labId']);
    if (role == 'student' && data['studentId'] != uid) return null;
    if (role == 'lab_admin' && !labIds.contains(labId)) return null;
    if (!{'student', 'lab_admin'}.contains(role)) return null;
    final status = _string(data['status']);
    final updated = _date(data['updatedAt']) ?? _date(data['createdAt']);
    final eventId =
        'borrow:$documentId:$status:${updated?.microsecondsSinceEpoch ?? 0}';
    return AppNotification(
      id: stateId(eventId),
      eventId: eventId,
      type: 'borrow',
      title: role == 'student'
          ? 'Pembaruan peminjaman'
          : 'Permintaan peminjaman baru',
      body:
          'Permintaan ${_safeRef(data['requestNumber'])} berstatus ${_status(status)}.',
      isRead: readStateIds.contains(stateId(eventId)),
      createdAt: updated,
      entityType: 'borrow_request',
      entityId: documentId,
      route: '',
    );
  }

  static AppNotification? report({
    required String role,
    required String uid,
    required Set<String> labIds,
    required String documentId,
    required Map<String, dynamic> data,
    required Set<String> readStateIds,
  }) {
    final labId = _string(data['labId']);
    if (role == 'student' && data['reporterId'] != uid) return null;
    if (role == 'lab_admin' && !labIds.contains(labId)) return null;
    if (!{'student', 'lab_admin'}.contains(role)) return null;
    final status = _string(data['status']);
    final updated = _date(data['updatedAt']) ?? _date(data['createdAt']);
    final eventId =
        'report:$documentId:$status:${updated?.microsecondsSinceEpoch ?? 0}';
    return AppNotification(
      id: stateId(eventId),
      eventId: eventId,
      type: 'report',
      title: role == 'student'
          ? 'Pembaruan laporan'
          : 'Laporan laboratorium baru',
      body:
          'Laporan ${_safeRef(data['reportNumber'])} diperbarui: ${_status(status)}.',
      isRead: readStateIds.contains(stateId(eventId)),
      createdAt: updated,
      entityType: 'report',
      entityId: documentId,
      route: '',
    );
  }

  static AppNotification? chat({
    required String role,
    required String uid,
    required Set<String> labIds,
    required String reportId,
    required String reportOwnerId,
    required String labId,
    required String messageId,
    required Map<String, dynamic> data,
    required Set<String> readStateIds,
  }) {
    final expectedSender = role == 'student' ? 'lab_admin' : 'student';
    if (role == 'student' && reportOwnerId != uid) return null;
    if (role == 'lab_admin' && !labIds.contains(labId)) return null;
    if (!{'student', 'lab_admin'}.contains(role) ||
        data['senderRole'] != expectedSender) {
      return null;
    }
    final eventId = 'message:$reportId:$messageId';
    return AppNotification(
      id: stateId(eventId),
      eventId: eventId,
      type: 'chat',
      title: 'Pesan baru pada laporan',
      body: 'Ada pesan baru dalam percakapan laporan.',
      isRead: readStateIds.contains(stateId(eventId)),
      createdAt: _date(data['createdAt']),
      entityType: 'report',
      entityId: reportId,
      route: '',
    );
  }

  static AppNotification? activity({
    required String role,
    required String documentId,
    required Map<String, dynamic> data,
    required Set<String> readStateIds,
  }) {
    if (role != 'superadmin') return null;
    final created = _date(data['createdAt']);
    final eventId =
        'activity:$documentId:${created?.microsecondsSinceEpoch ?? 0}';
    return AppNotification(
      id: stateId(eventId),
      eventId: eventId,
      type: 'admin_activity',
      title: _safeRef(data['title'], fallback: 'Aktivitas administratif'),
      body: _safeRef(data['description']),
      isRead: readStateIds.contains(stateId(eventId)),
      createdAt: created,
      entityType: 'admin_activity',
      entityId: documentId,
      route: '/superadmin/activity',
    );
  }

  static String stateId(String eventId) =>
      base64Url.encode(utf8.encode(eventId)).replaceAll('=', '');
  static DateTime? _date(dynamic value) => value is Timestamp
      ? value.toDate()
      : value is DateTime
      ? value
      : null;
  static String _string(dynamic value) => value is String ? value.trim() : '';
  static String _safeRef(dynamic value, {String fallback = 'data'}) =>
      value is String && value.trim().isNotEmpty ? value.trim() : fallback;
  static String _status(String status) => switch (status) {
    'pending' => 'menunggu ditinjau',
    'approved' => 'disetujui',
    'waiting_pickup' => 'menunggu pengambilan',
    'active' => 'sedang dipinjam',
    'returned' => 'dikembalikan',
    'open' => 'terbuka',
    'in_progress' => 'sedang ditangani',
    'resolved' => 'selesai',
    'rejected' => 'ditolak',
    'closed' => 'ditutup',
    _ => 'diperbarui',
  };
}
