import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.entityType,
    required this.entityId,
    required this.route,
    this.eventId = '',
    this.actorId,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;
  final String entityType;
  final String entityId;
  final String route;
  final String eventId;
  final String? actorId;

  // Compatibility with the original Student notification document/model.
  bool get read => isRead;
  String get targetType => entityType;
  String get targetId => entityId;

  factory AppNotification.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    return AppNotification(
      id: document.id,
      type: _string(data['type']),
      title: _string(data['title'], fallback: 'Pembaruan LabFlow'),
      body: _string(data['body']),
      isRead:
          data['isRead'] == true ||
          (!data.containsKey('isRead') && data['read'] == true),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : createdAt is DateTime
          ? createdAt
          : null,
      entityType: _string(
        data['entityType'],
        fallback: _string(data['targetType']),
      ),
      entityId: _string(data['entityId'], fallback: _string(data['targetId'])),
      route: _string(data['route']),
      eventId: _string(data['eventId']),
      actorId: data['actorId'] is String ? data['actorId'] as String : null,
    );
  }
}

String _string(dynamic value, {String fallback = ''}) =>
    value is String && value.trim().isNotEmpty ? value.trim() : fallback;
