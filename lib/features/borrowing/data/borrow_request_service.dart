import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/data/student_notification_writer.dart';
import '../domain/borrow_request.dart';

class BorrowRequestService {
  BorrowRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Memantau seluruh permintaan peminjaman berdasarkan laboratorium.
  Stream<List<BorrowRequest>> watchRequestsByLaboratory(String laboratoryId) {
    final cleanLabId = laboratoryId.trim();

    if (cleanLabId.isEmpty) {
      return Stream.value(const <BorrowRequest>[]);
    }

    return _firestore
        .collection('borrow_requests')
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map(BorrowRequest.fromDocument)
              .toList(growable: false);

          requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return requests;
        });
  }

  /// Mengambil satu permintaan peminjaman berdasarkan ID dokumen.
  Future<BorrowRequest> getRequest(String requestId) async {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      throw const BorrowRequestException(
        'ID permintaan peminjaman tidak valid.',
      );
    }

    final document = await _firestore
        .collection('borrow_requests')
        .doc(cleanId)
        .get();

    if (!document.exists) {
      throw const BorrowRequestException(
        'Permintaan peminjaman tidak ditemukan.',
      );
    }

    return BorrowRequest.fromDocument(document);
  }

  /// Memantau item yang diminta pada satu permintaan peminjaman.
  Stream<List<BorrowRequestItem>> watchRequestItems(String requestId) {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      return Stream.value(const <BorrowRequestItem>[]);
    }

    return _firestore
        .collection('borrow_requests')
        .doc(cleanId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(BorrowRequestItem.fromDocument)
              .toList(growable: false);

          items.sort(
            (a, b) =>
                a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
          );

          return items;
        });
  }

  /// Menyetujui permintaan peminjaman yang masih berstatus pending.
  Future<void> approveRequest(String requestId) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const BorrowRequestException('Sesi Lab Admin tidak ditemukan.');
    }

    final reference = _firestore.collection('borrow_requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw const BorrowRequestException(
          'Permintaan peminjaman tidak ditemukan.',
        );
      }

      final data = snapshot.data();

      if (data == null) {
        throw const BorrowRequestException(
          'Data permintaan peminjaman tidak valid.',
        );
      }

      if (data['status'] != 'pending') {
        throw const BorrowRequestException(
          'Permintaan ini sudah diproses. '
          'Muat ulang data sebelum melanjutkan.',
        );
      }

      transaction.update(reference, {
        'status': 'approved',
        'approvedBy': user.uid,
        'approvedAt': FieldValue.serverTimestamp(),
        'rejectionReason': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await StudentNotificationWriter(_firestore)
        .borrowing(requestId, 'borrow_approved');
  }

  /// Menolak permintaan peminjaman dan menyimpan alasan penolakan.
  Future<void> rejectRequest({
    required String requestId,
    required String reason,
  }) async {
    final cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      throw const BorrowRequestException('Alasan penolakan wajib diisi.');
    }

    final reference = _firestore.collection('borrow_requests').doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

      if (!snapshot.exists) {
        throw const BorrowRequestException(
          'Permintaan peminjaman tidak ditemukan.',
        );
      }

      final data = snapshot.data();

      if (data == null) {
        throw const BorrowRequestException(
          'Data permintaan peminjaman tidak valid.',
        );
      }

      if (data['status'] != 'pending') {
        throw const BorrowRequestException(
          'Permintaan ini sudah diproses. '
          'Muat ulang data sebelum melanjutkan.',
        );
      }

      transaction.update(reference, {
        'status': 'rejected',
        'rejectionReason': cleanReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await StudentNotificationWriter(_firestore)
        .borrowing(requestId, 'borrow_rejected');
  }
}

class BorrowRequestException implements Exception {
  const BorrowRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
