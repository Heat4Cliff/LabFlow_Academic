import 'package:cloud_firestore/cloud_firestore.dart';

class ReportMessage {
  const ReportMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.senderName = '',
    this.type = 'text',
    this.imageUrl,
    this.imagePublicId,
    this.deletedAt,
  });

  final String id;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime? createdAt;
  final DateTime? deletedAt;
  final String senderName;
  final String type;
  final String? imageUrl;
  final String? imagePublicId;

  bool get isDeleted => deletedAt != null;

  factory ReportMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return ReportMessage.fromData(
      document.id,
      document.data() ?? const <String, dynamic>{},
    );
  }

  factory ReportMessage.fromData(String id, Map<String, dynamic> data) {
    return ReportMessage(
      id: id,
      senderId: (data['senderId'] as String? ?? '').trim(),
      senderRole: (data['senderRole'] as String? ?? '').trim(),
      text: (data['text'] as String? ?? '').trim(),
      createdAt: _date(data['createdAt']),
      deletedAt: _date(data['deletedAt']),
      senderName: (data['senderName'] as String? ?? '').trim(),
      type: (data['type'] as String? ?? 'text').trim(),
      imageUrl: data['imageUrl'] as String?,
      imagePublicId: data['imagePublicId'] as String?,
    );
  }
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
