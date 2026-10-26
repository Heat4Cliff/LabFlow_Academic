import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../borrowing/domain/borrow_request.dart';
import '../domain/student_borrowing_detail.dart';

class StudentBorrowingDetailService {
  StudentBorrowingDetailService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const StudentBorrowingDetailException(
        'Sesi mahasiswa tidak ditemukan.',
      );
    }
    return uid;
  }

  Stream<BorrowRequest> watchRequest(String requestId) {
    return _firestore
        .collection('borrow_requests')
        .doc(requestId)
        .snapshots()
        .map((document) {
          if (!document.exists || document.data()?['studentId'] != _uid) {
            throw const StudentBorrowingDetailException(
              'Pengajuan tidak ditemukan atau bukan milik Anda.',
            );
          }
          return BorrowRequest.fromDocument(document);
        });
  }

  Stream<List<BorrowRequestItem>> watchItems(String requestId) {
    return _firestore
        .collection('borrow_requests')
        .doc(requestId)
        .collection('items')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(BorrowRequestItem.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<List<StudentAssignedBorrowing>> watchAssignments(String requestId) {
    return _firestore
        .collection('borrowings')
        .where('requestId', isEqualTo: requestId)
        .where('studentId', isEqualTo: _uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StudentAssignedBorrowing.fromDocument)
              .toList(growable: false),
        );
  }

  Future<String> loadLaboratoryName(String labId) async {
    final document = await _firestore
        .collection('laboratories')
        .doc(labId)
        .get();
    return (document.data()?['name'] as String? ?? 'Laboratorium').trim();
  }
}

class StudentBorrowingDetailException implements Exception {
  const StudentBorrowingDetailException(this.message);
  final String message;
  @override
  String toString() => message;
}
