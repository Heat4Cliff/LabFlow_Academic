import 'package:cloud_firestore/cloud_firestore.dart';

class Laboratory {
  const Laboratory({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.location,
    required this.status,
  });

  final String id;
  final String name;
  final String code;
  final String description;
  final String location;
  final String status;

  bool get isActive => status == 'active';

  factory Laboratory.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw const FormatException('Data laboratorium tidak ditemukan.');
    }

    return Laboratory(
      id: document.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      description: data['description'] as String? ?? '',
      location: data['location'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }
}
