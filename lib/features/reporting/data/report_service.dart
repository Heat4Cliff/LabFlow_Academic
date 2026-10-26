import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/lab_report.dart';

class ReportService {
  ReportService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  Stream<List<LabReport>> watchByLaboratory(String laboratoryId) {
    final cleanLabId = laboratoryId.trim();

    if (cleanLabId.isEmpty) {
      return Stream.value(const <LabReport>[]);
    }

    return _firestore
        .collection('reports')
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final reports = snapshot.docs
              .map(LabReport.fromDocument)
              .toList(growable: false);

          reports.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return reports;
        });
  }

  Future<LabReport> getReport(String reportId) async {
    final cleanId = reportId.trim();

    if (cleanId.isEmpty) {
      throw const ReportException('ID laporan tidak valid.');
    }

    final snapshot = await _firestore.collection('reports').doc(cleanId).get();

    if (!snapshot.exists) {
      throw const ReportException('Laporan tidak ditemukan.');
    }

    return LabReport.fromDocument(snapshot);
  }

  Future<LabReport> updatePriority({
    required String reportId,
    required String priority,
  }) async {
    const validPriorities = <String>{'low', 'medium', 'high', 'critical'};

    if (!validPriorities.contains(priority)) {
      throw const ReportException('Priority laporan tidak valid.');
    }

    final reference = _firestore.collection('reports').doc(reportId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const ReportException('Laporan tidak ditemukan.');
        }

        final data = snapshot.data();
        final status = (data?['status'] as String? ?? '').trim();

        if (!{'open', 'acknowledged', 'in_progress'}.contains(status)) {
          throw const ReportException(
            'Priority laporan yang sudah selesai tidak dapat diubah.',
          );
        }

        transaction.update(reference, {
          'priority': priority,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseError(
        error,
        fallback: 'Priority laporan gagal diperbarui.',
      );
    }

    return getReport(reportId);
  }

  Future<LabReport> acknowledge(String reportId) async {
    final user = _requireUser();
    final reference = _firestore.collection('reports').doc(reportId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const ReportException('Laporan tidak ditemukan.');
        }

        final data = snapshot.data();

        if (data == null || data['status'] != 'open') {
          throw const ReportException(
            'Laporan sudah tidak berada pada status Menunggu.',
          );
        }

        transaction.update(reference, {
          'status': 'acknowledged',
          'assignedTo': user.uid,
          'acknowledgedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseError(error, fallback: 'Laporan gagal diterima.');
    }

    return getReport(reportId);
  }

  Future<LabReport> startProgress(String reportId) async {
    final user = _requireUser();
    final reference = _firestore.collection('reports').doc(reportId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const ReportException('Laporan tidak ditemukan.');
        }

        final data = snapshot.data();

        if (data == null || data['status'] != 'acknowledged') {
          throw const ReportException(
            'Laporan belum berada pada tahap siap ditangani.',
          );
        }

        final assignedTo = (data['assignedTo'] as String? ?? '').trim();

        if (assignedTo.isNotEmpty && assignedTo != user.uid) {
          throw const ReportException(
            'Laporan sedang ditangani Lab Admin lain.',
          );
        }

        transaction.update(reference, {
          'status': 'in_progress',
          'assignedTo': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseError(
        error,
        fallback: 'Penanganan laporan gagal dimulai.',
      );
    }

    return getReport(reportId);
  }

  Future<LabReport> resolve({
    required String reportId,
    required String response,
  }) async {
    final cleanResponse = response.trim();

    if (cleanResponse.isEmpty) {
      throw const ReportException('Tanggapan penyelesaian wajib diisi.');
    }

    final user = _requireUser();
    final reference = _firestore.collection('reports').doc(reportId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const ReportException('Laporan tidak ditemukan.');
        }

        final data = snapshot.data();

        if (data == null || data['status'] != 'in_progress') {
          throw const ReportException(
            'Laporan belum berada pada tahap penanganan.',
          );
        }

        final assignedTo = (data['assignedTo'] as String? ?? '').trim();

        if (assignedTo.isNotEmpty && assignedTo != user.uid) {
          throw const ReportException(
            'Laporan sedang ditangani Lab Admin lain.',
          );
        }

        transaction.update(reference, {
          'status': 'resolved',
          'assignedTo': user.uid,
          'adminResponse': cleanResponse,
          'resolvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseError(error, fallback: 'Laporan gagal diselesaikan.');
    }

    return getReport(reportId);
  }

  Future<LabReport> reject({
    required String reportId,
    required String response,
  }) async {
    final cleanResponse = response.trim();

    if (cleanResponse.isEmpty) {
      throw const ReportException('Alasan penolakan wajib diisi.');
    }

    final user = _requireUser();
    final reference = _firestore.collection('reports').doc(reportId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const ReportException('Laporan tidak ditemukan.');
        }

        final data = snapshot.data();
        final status = (data?['status'] as String? ?? '').trim();

        if (!{'acknowledged', 'in_progress'}.contains(status)) {
          throw const ReportException(
            'Laporan belum dapat ditolak pada status saat ini.',
          );
        }

        final assignedTo = (data?['assignedTo'] as String? ?? '').trim();

        if (assignedTo.isNotEmpty && assignedTo != user.uid) {
          throw const ReportException(
            'Laporan sedang ditangani Lab Admin lain.',
          );
        }

        transaction.update(reference, {
          'status': 'rejected',
          'assignedTo': user.uid,
          'adminResponse': cleanResponse,
          'closedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseError(error, fallback: 'Laporan gagal ditolak.');
    }

    return getReport(reportId);
  }

  Future<LabReport> closeResolved(String reportId) async {
    final reference = _firestore.collection('reports').doc(reportId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const ReportException('Laporan tidak ditemukan.');
        }

        final data = snapshot.data();

        if (data == null || data['status'] != 'resolved') {
          throw const ReportException(
            'Hanya laporan resolved yang dapat ditutup.',
          );
        }

        transaction.update(reference, {
          'status': 'closed',
          'closedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      throw _firebaseError(error, fallback: 'Laporan gagal ditutup.');
    }

    return getReport(reportId);
  }

  User _requireUser() {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const ReportException('Sesi Lab Admin tidak ditemukan.');
    }

    return user;
  }

  ReportException _firebaseError(
    FirebaseException error, {
    required String fallback,
  }) {
    if (error.code == 'permission-denied') {
      return const ReportException(
        'Firestore menolak operasi laporan. '
        'Periksa membership laboratorium dan rules.',
      );
    }

    if (error.code == 'aborted') {
      return const ReportException(
        'Data laporan berubah. Muat ulang lalu coba lagi.',
      );
    }

    return ReportException('$fallback (${error.code})');
  }
}

class ReportException implements Exception {
  const ReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
