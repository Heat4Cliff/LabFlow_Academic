import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.status,
  });

  final String uid;
  final String email;
  final String fullName;
  final String role;
  final String status;

  bool get isActive => status == 'active';

  bool get isSuperadmin => role == 'superadmin';

  bool get isLabAdmin => role == 'lab_admin';

  bool get isStudent => role == 'student';

  factory UserProfile.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw const FormatException('Data profil pengguna tidak ditemukan.');
    }

    return UserProfile(
      uid: document.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      role: data['role'] as String? ?? '',
      status: data['status'] as String? ?? '',
    );
  }
}
