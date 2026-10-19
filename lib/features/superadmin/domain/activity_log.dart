import 'package:cloud_firestore/cloud_firestore.dart';

/// Representasi satu aktivitas/audit di LabFlow.
///
/// Activity Log digunakan untuk mencatat perubahan penting
/// seperti:
/// - perubahan pengguna
/// - assignment membership
/// - perubahan laboratorium
/// - peminjaman
/// - maintenance
class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.actorName,
    required this.createdAt,
    this.actorUid,
    this.reference,
  });

  final String id;

  /// Contoh:
  /// user
  /// laboratory
  /// membership
  /// borrowing
  /// maintenance
  final String type;

  final String title;
  final String description;

  final String actorName;
  final String? actorUid;

  /// Referensi opsional seperti:
  /// LAB-KOM-01
  /// MKT-R01
  /// UID pengguna
  final String? reference;

  final DateTime createdAt;

  factory ActivityLog.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final timestamp = data['createdAt'];

    return ActivityLog(
      id: document.id,
      type: data['type']?.toString() ?? 'system',
      title: data['title']?.toString() ?? 'Aktivitas',
      description: data['description']?.toString() ?? '',
      actorName: data['actorName']?.toString() ?? 'Sistem',
      actorUid: data['actorUid']?.toString(),
      reference: data['reference']?.toString(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}
