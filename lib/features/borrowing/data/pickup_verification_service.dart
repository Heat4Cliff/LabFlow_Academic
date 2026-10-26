import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/data/student_notification_writer.dart';
import '../domain/pickup_borrowing.dart';

class PickupVerificationService {
  PickupVerificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Memantau seluruh aset yang sudah dialokasikan pada satu request.
  ///
  /// `labId` ikut menjadi constraint query agar query sesuai dengan model
  /// otorisasi Firestore Rules milik Lab Admin.
  Stream<List<PickupBorrowing>> watchAssignments({
    required String requestId,
    required String laboratoryId,
  }) {
    final cleanRequestId = requestId.trim();
    final cleanLabId = laboratoryId.trim();

    if (cleanRequestId.isEmpty || cleanLabId.isEmpty) {
      return Stream.value(const <PickupBorrowing>[]);
    }

    return _firestore
        .collection('borrowings')
        .where('requestId', isEqualTo: cleanRequestId)
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final assignments = snapshot.docs
              .map(PickupBorrowing.fromDocument)
              .toList(growable: false);

          assignments.sort((a, b) {
            final nameCompare = a.assetName.toLowerCase().compareTo(
              b.assetName.toLowerCase(),
            );

            if (nameCompare != 0) {
              return nameCompare;
            }

            return a.assetCode.toLowerCase().compareTo(
              b.assetCode.toLowerCase(),
            );
          });

          return assignments;
        });
  }

  /// Mengonfirmasi bahwa aset benar-benar telah diserahkan kepada mahasiswa.
  ///
  /// Perubahan dilakukan atomik:
  /// - seluruh borrowing: waiting_pickup -> active
  /// - pickupVerifiedBy diisi UID Lab Admin
  /// - pickupVerifiedAt diisi server timestamp
  /// - request induk: waiting_pickup -> active
  Future<void> confirmPickup({
    required String requestId,
    required String laboratoryId,
  }) async {
    final cleanRequestId = requestId.trim();
    final cleanLabId = laboratoryId.trim();
    final user = _firebaseAuth.currentUser;

    if (cleanRequestId.isEmpty) {
      throw const PickupVerificationException(
        'ID permintaan peminjaman tidak valid.',
      );
    }

    if (cleanLabId.isEmpty) {
      throw const PickupVerificationException(
        'Laboratorium permintaan tidak valid.',
      );
    }

    if (user == null) {
      throw const PickupVerificationException(
        'Sesi Lab Admin tidak ditemukan.',
      );
    }

    final requestReference = _firestore
        .collection('borrow_requests')
        .doc(cleanRequestId);

    // Query awal hanya mencari document yang sudah ada. Setiap document akan
    // dibaca ulang di dalam transaction sebelum perubahan ditulis.
    final assignmentQuery = await _firestore
        .collection('borrowings')
        .where('requestId', isEqualTo: cleanRequestId)
        .where('labId', isEqualTo: cleanLabId)
        .get();

    if (assignmentQuery.docs.isEmpty) {
      throw const PickupVerificationException(
        'Belum ada aset yang ditugaskan pada permintaan ini.',
      );
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestReference);

        if (!requestSnapshot.exists) {
          throw const PickupVerificationException(
            'Permintaan peminjaman tidak ditemukan.',
          );
        }

        final requestData = requestSnapshot.data();

        if (requestData == null) {
          throw const PickupVerificationException(
            'Data permintaan peminjaman tidak valid.',
          );
        }

        final requestStatus = (requestData['status'] as String? ?? '').trim();
        final requestLabId = (requestData['labId'] as String? ?? '').trim();

        if (requestStatus != 'waiting_pickup') {
          throw const PickupVerificationException(
            'Permintaan sudah tidak berada pada tahap pengambilan.',
          );
        }

        if (requestLabId != cleanLabId) {
          throw const PickupVerificationException(
            'Laboratorium request tidak sesuai dengan sesi verifikasi.',
          );
        }

        final assignmentSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

        // READ PHASE
        for (final assignmentDocument in assignmentQuery.docs) {
          final assignmentSnapshot = await transaction.get(
            assignmentDocument.reference,
          );

          if (!assignmentSnapshot.exists) {
            throw const PickupVerificationException(
              'Salah satu data penugasan aset sudah tidak tersedia.',
            );
          }

          final assignmentData = assignmentSnapshot.data();

          if (assignmentData == null) {
            throw const PickupVerificationException(
              'Salah satu data penugasan aset tidak valid.',
            );
          }

          final assignmentRequestId =
              (assignmentData['requestId'] as String? ?? '').trim();
          final assignmentLabId = (assignmentData['labId'] as String? ?? '')
              .trim();
          final assignmentStudentId =
              (assignmentData['studentId'] as String? ?? '').trim();
          final requestStudentId = (requestData['studentId'] as String? ?? '')
              .trim();
          final assignmentStatus = (assignmentData['status'] as String? ?? '')
              .trim();

          if (assignmentRequestId != cleanRequestId ||
              assignmentLabId != cleanLabId ||
              assignmentStudentId != requestStudentId) {
            throw const PickupVerificationException(
              'Relasi data penugasan aset tidak sesuai dengan request.',
            );
          }

          if (assignmentStatus != 'waiting_pickup') {
            throw const PickupVerificationException(
              'Salah satu aset sudah tidak menunggu proses pengambilan.',
            );
          }

          assignmentSnapshots.add(assignmentSnapshot);
        }

        // WRITE PHASE
        for (final assignmentSnapshot in assignmentSnapshots) {
          transaction.update(assignmentSnapshot.reference, {
            'status': 'active',
            'pickupVerifiedBy': user.uid,
            'pickupVerifiedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(requestReference, {
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      await StudentNotificationWriter(_firestore)
          .borrowing(cleanRequestId, 'borrow_active');
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const PickupVerificationException(
          'Firestore menolak verifikasi pengambilan. '
          'Periksa rules dan relasi data request.',
        );
      }

      if (error.code == 'aborted') {
        throw const PickupVerificationException(
          'Data berubah saat verifikasi diproses. Muat ulang lalu coba lagi.',
        );
      }

      throw PickupVerificationException(
        'Verifikasi pengambilan gagal diproses (${error.code}).',
      );
    }
  }
}

class PickupVerificationException implements Exception {
  const PickupVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
