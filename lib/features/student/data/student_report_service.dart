import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../reporting/domain/lab_report.dart';
import '../domain/student_models.dart';

class StudentReportService {
  StudentReportService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const categories = <String>[
    'asset_damage',
    'asset_lost',
    'network',
    'computer',
    'software',
    'facility',
    'electricity',
    'other',
  ];

  static bool isOwner({required String authUid, required String reporterId}) =>
      authUid.isNotEmpty && authUid == reporterId;

  static String? validate({
    required String labId,
    required String category,
    required String title,
    required String description,
    required String location,
    required String severity,
  }) {
    if (labId.trim().isEmpty) return 'Pilih laboratorium.';
    if (!categories.contains(category)) return 'Kategori laporan tidak valid.';
    if (title.trim().isEmpty || title.trim().length > 120) {
      return 'Judul wajib diisi, maksimal 120 karakter.';
    }
    if (description.trim().isEmpty || description.trim().length > 2000) {
      return 'Deskripsi wajib diisi, maksimal 2000 karakter.';
    }
    if (location.trim().isEmpty || location.trim().length > 160) {
      return 'Lokasi wajib diisi, maksimal 160 karakter.';
    }
    if (!{'normal', 'urgent'}.contains(severity)) {
      return 'Tingkat urgensi tidak valid.';
    }
    return null;
  }

  Future<List<StudentLaboratory>> loadLaboratories() async {
    final snapshot = await _firestore
        .collection('laboratories')
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs
        .map(StudentLaboratory.fromDocument)
        .toList(growable: false);
  }

  Future<String> loadLaboratoryName(String labId) async {
    final snapshot = await _firestore
        .collection('laboratories')
        .doc(labId)
        .get();
    return (snapshot.data()?['name'] as String? ?? 'Laboratorium').trim();
  }

  Future<List<StudentAsset>> loadAssets(String labId) async {
    final snapshot = await _firestore
        .collection('assets')
        .where('labId', isEqualTo: labId)
        .get();
    return snapshot.docs.map(StudentAsset.fromDocument).toList(growable: false);
  }

  Stream<List<LabReport>> watchOwnReports() {
    final uid = _requireUid();
    return _firestore
        .collection('reports')
        .where('reporterId', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(LabReport.fromDocument).toList(growable: false),
        );
  }

  Stream<LabReport> watchOwnReport(String reportId) {
    final uid = _requireUid();
    return _firestore.collection('reports').doc(reportId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists ||
          !isOwner(
            authUid: uid,
            reporterId: snapshot.data()?['reporterId'] as String? ?? '',
          )) {
        throw const StudentReportException(
          'Laporan tidak ditemukan atau bukan milik Anda.',
        );
      }
      return LabReport.fromDocument(snapshot);
    });
  }

  Future<String> createReport({
    required String labId,
    String? assetId,
    required String category,
    required String title,
    required String description,
    required String location,
    required String severity,
  }) async {
    final error = validate(
      labId: labId,
      category: category,
      title: title,
      description: description,
      location: location,
      severity: severity,
    );
    if (error != null) throw StudentReportException(error);
    final uid = _requireUid();
    final cleanAssetId = assetId?.trim();
    final report = _firestore.collection('reports').doc();
    final number =
        'RPT-${DateTime.now().year}-${report.id.substring(0, 6).toUpperCase()}';
    await report.set({
      'reportNumber': number,
      'reporterId': uid,
      'labId': labId.trim(),
      'assetId': cleanAssetId == null || cleanAssetId.isEmpty
          ? null
          : cleanAssetId,
      'category': category,
      'title': title.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'severity': severity,
      'priority': 'medium',
      'status': 'open',
      'assignedTo': null,
      'adminResponse': null,
      'createdAt': FieldValue.serverTimestamp(),
      'acknowledgedAt': null,
      'resolvedAt': null,
      'closedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return report.id;
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const StudentReportException('Sesi mahasiswa tidak ditemukan.');
    }
    return uid;
  }
}

class StudentReportException implements Exception {
  const StudentReportException(this.message);
  final String message;
  @override
  String toString() => message;
}
