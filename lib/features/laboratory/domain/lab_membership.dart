import 'package:cloud_firestore/cloud_firestore.dart';

class LabMembership {
  const LabMembership({
    required this.id,
    required this.userId,
    required this.labId,
    required this.role,
    required this.active,
  });

  final String id;
  final String userId;
  final String labId;
  final String role;
  final bool active;

  factory LabMembership.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw const FormatException(
        'Data membership laboratorium tidak ditemukan.',
      );
    }

    return LabMembership(
      id: document.id,
      userId: data['userId'] as String? ?? '',
      labId: data['labId'] as String? ?? '',
      role: data['role'] as String? ?? '',
      active: data['active'] as bool? ?? false,
    );
  }
}
