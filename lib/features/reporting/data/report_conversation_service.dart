import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../shared/data/student_notification_writer.dart';
import '../domain/report_message.dart';

class ReportConversationService {
  ReportConversationService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static String? validateMessage(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Pesan tidak boleh kosong.';
    if (text.length > 1000) return 'Pesan maksimal 1000 karakter.';
    return null;
  }

  Stream<List<ReportMessage>> watchMessages(String reportId) => _firestore
      .collection('reports')
      .doc(reportId)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map(ReportMessage.fromDocument)
            .toList(growable: false),
      );

  Future<void> send(String reportId, String rawText) async {
    final validation = validateMessage(rawText);
    if (validation != null) throw ReportConversationException(validation);
    final user = _auth.currentUser;
    if (user == null) {
      throw const ReportConversationException('Sesi pengguna tidak ditemukan.');
    }
    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data();
    final role = (data?['role'] as String? ?? '').trim();
    if (data?['status'] != 'active' ||
        !{'student', 'lab_admin'}.contains(role)) {
      throw const ReportConversationException(
        'Akun tidak dapat mengirim pesan.',
      );
    }
    await _firestore
        .collection('reports')
        .doc(reportId)
        .collection('messages')
        .add({
          'senderId': user.uid,
          'senderRole': role,
          'text': rawText.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'deletedAt': null,
        });
    if (role == 'lab_admin') {
      await StudentNotificationWriter(_firestore)
          .report(reportId, message: true);
    }
  }

  Future<void> softDelete(String reportId, String messageId) async {
    await _firestore
        .collection('reports')
        .doc(reportId)
        .collection('messages')
        .doc(messageId)
        .update({'deletedAt': FieldValue.serverTimestamp()});
  }
}

class ReportConversationException implements Exception {
  const ReportConversationException(this.message);
  final String message;
  @override
  String toString() => message;
}
