import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/student_notification.dart';

class StudentNotificationService {
  StudentNotificationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<StudentNotification>> watchMine() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.error(
        const StudentNotificationException('Sesi mahasiswa tidak ditemukan.'),
      );
    }
    return _firestore
        .collection('notifications')
        .where('studentId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(StudentNotification.fromDocument)
              .toList(growable: false),
        );
  }

  Future<void> markRead(String id) =>
      _firestore.collection('notifications').doc(id).update({'read': true});
}

class StudentNotificationException implements Exception {
  const StudentNotificationException(this.message);
  final String message;
  @override
  String toString() => message;
}
