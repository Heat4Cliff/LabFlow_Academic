import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/domain/user_profile.dart';
import '../domain/lab_membership.dart';
import '../domain/laboratory.dart';

class LabMembershipService {
  LabMembershipService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Mengambil user yang mempunyai role Lab Admin.
  Stream<List<UserProfile>> watchLabAdmins() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'lab_admin')
        .snapshots()
        .map((snapshot) {
          final admins = snapshot.docs
              .map(UserProfile.fromDocument)
              .where((user) => user.isActive)
              .toList();

          admins.sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

          return admins;
        });
  }

  /// Mengambil laboratorium yang masih aktif.
  Stream<List<Laboratory>> watchActiveLaboratories() {
    return _firestore
        .collection('laboratories')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final labs = snapshot.docs.map(Laboratory.fromDocument).toList();

          labs.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          return labs;
        });
  }

  /// Mengambil seluruh assignment Lab Admin secara realtime.
  Stream<List<LabMembership>> watchMemberships() {
    return _firestore.collection('lab_memberships').snapshots().map((snapshot) {
      return snapshot.docs.map(LabMembership.fromDocument).toList();
    });
  }

  /// Mengambil membership aktif milik Lab Admin yang sedang login.
  ///
  /// Query hanya berdasarkan UID agar tidak membutuhkan composite
  /// index tambahan. Filter active dan role dilakukan di client.
  Stream<List<LabMembership>> watchCurrentLabAdminMemberships() {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      return Stream<List<LabMembership>>.error(
        const LabMembershipException(
          'Sesi Lab Admin tidak ditemukan. Silakan masuk kembali.',
        ),
      );
    }

    return _firestore
        .collection('lab_memberships')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
          final memberships = snapshot.docs
              .map(LabMembership.fromDocument)
              .where(
                (membership) =>
                    membership.active && membership.role == 'lab_admin',
              )
              .toList();

          memberships.sort((a, b) => a.labId.compareTo(b.labId));

          return memberships;
        });
  }

  /// Menghubungkan Lab Admin dengan laboratorium.
  Future<void> assignLabAdmin({
    required String userId,
    required String labId,
  }) async {
    final currentUser = _firebaseAuth.currentUser;

    if (currentUser == null) {
      throw const LabMembershipException('Sesi Superadmin tidak ditemukan.');
    }

    final membershipId = '${userId}__$labId';

    final membershipReference = _firestore
        .collection('lab_memberships')
        .doc(membershipId);

    await _firestore.runTransaction((transaction) async {
      final userReference = _firestore.collection('users').doc(userId);
      final labReference = _firestore.collection('laboratories').doc(labId);

      final userDocument = await transaction.get(userReference);
      final labDocument = await transaction.get(labReference);
      final membershipDocument = await transaction.get(membershipReference);

      if (!userDocument.exists) {
        throw const LabMembershipException('Akun Lab Admin tidak ditemukan.');
      }

      if (!labDocument.exists) {
        throw const LabMembershipException('Laboratorium tidak ditemukan.');
      }

      final userData = userDocument.data()!;
      final labData = labDocument.data()!;

      if (userData['role'] != 'lab_admin') {
        throw const LabMembershipException(
          'User yang dipilih bukan Lab Admin.',
        );
      }

      if (userData['status'] != 'active') {
        throw const LabMembershipException('Akun Lab Admin tidak aktif.');
      }

      if (labData['status'] != 'active') {
        throw const LabMembershipException('Laboratorium tidak aktif.');
      }

      if (membershipDocument.exists &&
          membershipDocument.data()?['active'] == true) {
        throw const LabMembershipException(
          'Lab Admin sudah ditugaskan ke laboratorium tersebut.',
        );
      }

      transaction.set(membershipReference, {
        'userId': userId,
        'labId': labId,
        'role': 'lab_admin',
        'active': true,
        'assignedBy': currentUser.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Menonaktifkan assignment tanpa menghapus riwayat membership.
  Future<void> deactivateMembership(String membershipId) async {
    await _firestore.collection('lab_memberships').doc(membershipId).update({
      'active': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class LabMembershipException implements Exception {
  const LabMembershipException(this.message);

  final String message;

  @override
  String toString() => message;
}
