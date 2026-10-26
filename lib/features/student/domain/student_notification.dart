import 'package:cloud_firestore/cloud_firestore.dart';

class StudentNotification {
  const StudentNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.targetType,
    required this.targetId,
    required this.read,
    required this.createdAt,
  });
  final String id;
  final String type;
  final String title;
  final String body;
  final String targetType;
  final String targetId;
  final bool read;
  final DateTime? createdAt;

  factory StudentNotification.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final timestamp = data['createdAt'];
    return StudentNotification(
      id: document.id,
      type: (data['type'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? 'Pembaruan LabFlow').trim(),
      body: (data['body'] as String? ?? '').trim(),
      targetType: (data['targetType'] as String? ?? '').trim(),
      targetId: (data['targetId'] as String? ?? '').trim(),
      read: data['read'] == true,
      createdAt: timestamp is Timestamp ? timestamp.toDate() : null,
    );
  }
}
