import 'package:cloud_firestore/cloud_firestore.dart';

class ReportMessage {
  const ReportMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.deletedAt,
  });

  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime? createdAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  factory ReportMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return ReportMessage(
      id: document.id,
      senderId: (data['senderId'] as String? ?? '').trim(),
      senderRole: (data['senderRole'] as String? ?? '').trim(),
      text: (data['text'] as String? ?? '').trim(),
      createdAt: _date(data['createdAt']),
      deletedAt: _date(data['deletedAt']),
    );
  }
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
