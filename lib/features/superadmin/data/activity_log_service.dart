import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/activity_log.dart';

class ActivityLogService {
  ActivityLogService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Membaca maksimal 100 aktivitas terbaru.
  Stream<List<ActivityLog>> watchActivities() {
    return _firestore
        .collection('activity_logs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ActivityLog.fromFirestore).toList(),
        );
  }

  /// Menulis satu Activity Log ke Firestore.
  ///
  /// Actor tidak perlu dikirim dari UI.
  /// Service akan membaca user yang sedang login melalui Firebase Auth
  /// kemudian mengambil nama profilnya dari collection `users`.
  ///
  /// Method mengembalikan:
  /// true  -> log berhasil dibuat.
  /// false -> log gagal dibuat.
  ///
  /// Kegagalan Activity Log tidak membatalkan operasi bisnis
  /// yang sebelumnya sudah berhasil dilakukan.
  Future<bool> createActivity({
    required String type,
    required String title,
    required String description,
    String? reference,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;

      if (currentUser == null) {
        return false;
      }

      final profileDocument = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final profileData = profileDocument.data();

      final fullName = profileData?['fullName']?.toString().trim();

      final actorName = fullName != null && fullName.isNotEmpty
          ? fullName
          : currentUser.email ?? 'Superadmin';

      await _firestore.collection('activity_logs').add({
        'type': type,
        'title': title,
        'description': description,
        'actorName': actorName,
        'actorUid': currentUser.uid,
        'reference': reference,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (_) {
      /// Activity Log bersifat audit tambahan.
      /// Jika pencatatan gagal, operasi utama tidak ikut dibatalkan.
      return false;
    }
  }

  // ============================================================
  // USER MANAGEMENT ACTIVITY
  // ============================================================

  /// Mencatat pembuatan akun baru oleh Superadmin.
  Future<bool> logUserCreated({
    required String fullName,
    required String email,
    required String role,
  }) {
    return createActivity(
      type: 'user',
      title: 'Pengguna dibuat',
      description: 'Akun $fullName dibuat sebagai ${_roleLabel(role)}.',
      reference: email,
    );
  }

  /// Mencatat perubahan data umum pengguna.
  ///
  /// Digunakan ketika data seperti nama berubah,
  /// tetapi role pengguna tidak berubah.
  Future<bool> logUserUpdated({
    required String fullName,
    required String email,
  }) {
    return createActivity(
      type: 'user',
      title: 'Data pengguna diperbarui',
      description: 'Data akun $fullName berhasil diperbarui.',
      reference: email,
    );
  }

  /// Mencatat perubahan role pengguna.
  ///
  /// Contoh:
  /// Student -> Lab Admin.
  Future<bool> logUserRoleChanged({
    required String fullName,
    required String email,
    required String oldRole,
    required String newRole,
  }) {
    return createActivity(
      type: 'user',
      title: 'Role pengguna diubah',
      description:
          'Role $fullName diubah dari ${_roleLabel(oldRole)} '
          'menjadi ${_roleLabel(newRole)}.',
      reference: email,
    );
  }

  /// Mencatat akun yang dinonaktifkan / suspended.
  Future<bool> logUserSuspended({
    required String fullName,
    required String email,
  }) {
    return createActivity(
      type: 'user',
      title: 'Pengguna dinonaktifkan',
      description: 'Akun $fullName dinonaktifkan.',
      reference: email,
    );
  }

  /// Mencatat akun yang diaktifkan kembali.
  Future<bool> logUserActivated({
    required String fullName,
    required String email,
  }) {
    return createActivity(
      type: 'user',
      title: 'Pengguna diaktifkan kembali',
      description: 'Akun $fullName diaktifkan kembali.',
      reference: email,
    );
  }

  // ============================================================
  // LAB MEMBERSHIP ACTIVITY
  // ============================================================

  /// Mencatat ketika Lab Admin diberikan akses
  /// terhadap suatu laboratorium.
  Future<bool> logMembershipAssigned({
    required String userId,
    required String labId,
  }) async {
    final data = await _resolveMembershipContext(userId: userId, labId: labId);

    return createActivity(
      type: 'membership',
      title: 'Lab Admin ditugaskan',
      description: '${data.adminName} ditugaskan ke ${data.labName}.',
      reference: data.labCode,
    );
  }

  /// Mencatat ketika akses Lab Admin
  /// terhadap laboratorium dicabut.
  Future<bool> logMembershipRevoked({
    required String userId,
    required String labId,
  }) async {
    final data = await _resolveMembershipContext(userId: userId, labId: labId);

    return createActivity(
      type: 'membership',
      title: 'Akses laboratorium dicabut',
      description: 'Akses ${data.adminName} ke ${data.labName} dicabut.',
      reference: data.labCode,
    );
  }

  /// Mengambil nama Lab Admin dan data laboratorium
  /// supaya Activity Log menampilkan informasi yang mudah dibaca,
  /// bukan UID atau document ID Firestore.
  Future<_MembershipActivityContext> _resolveMembershipContext({
    required String userId,
    required String labId,
  }) async {
    final results = await Future.wait([
      _firestore.collection('users').doc(userId).get(),
      _firestore.collection('laboratories').doc(labId).get(),
    ]);

    final userData = results[0].data();
    final labData = results[1].data();

    final adminName = userData?['fullName']?.toString().trim() ?? '';

    final labName = labData?['name']?.toString().trim() ?? '';

    final labCode = labData?['code']?.toString().trim() ?? '';

    return _MembershipActivityContext(
      adminName: adminName.isEmpty ? 'Lab Admin' : adminName,
      labName: labName.isEmpty ? 'laboratorium' : labName,
      labCode: labCode.isEmpty ? labId : labCode,
    );
  }

  // ============================================================
  // HELPER
  // ============================================================

  /// Mengubah kode role Firestore menjadi label
  /// yang mudah dibaca di Activity Log.
  String _roleLabel(String role) {
    switch (role) {
      case 'superadmin':
        return 'Superadmin';

      case 'lab_admin':
        return 'Lab Admin';

      case 'student':
        return 'Student';

      default:
        return role;
    }
  }
}

/// Object internal yang hanya digunakan ActivityLogService.
///
/// Tidak dimasukkan ke folder domain karena object ini
/// hanya membantu pembuatan teks Activity Log Membership.
class _MembershipActivityContext {
  const _MembershipActivityContext({
    required this.adminName,
    required this.labName,
    required this.labCode,
  });

  final String adminName;
  final String labName;
  final String labCode;
}
