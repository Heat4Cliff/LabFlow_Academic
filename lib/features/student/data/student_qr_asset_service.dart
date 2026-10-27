import 'package:cloud_firestore/cloud_firestore.dart';

abstract class StudentAssetLookup {
  Future<String?> findByQrValue(String value);
  Future<bool> existsById(String documentId);
  Future<String?> findByCode(String code);
}

class FirestoreStudentAssetLookup implements StudentAssetLookup {
  FirestoreStudentAssetLookup({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<String?> findByQrValue(String value) async {
    final result = await _firestore
        .collection('assets')
        .where('qrValue', isEqualTo: value)
        .limit(1)
        .get();
    return result.docs.isEmpty ? null : result.docs.first.id;
  }

  @override
  Future<bool> existsById(String documentId) async =>
      (await _firestore.collection('assets').doc(documentId).get()).exists;

  @override
  Future<String?> findByCode(String code) async {
    final result = await _firestore
        .collection('assets')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    return result.docs.isEmpty ? null : result.docs.first.id;
  }
}

enum StudentQrResolutionStatus { found, invalid, notFound }

class StudentQrResolution {
  const StudentQrResolution(this.status, {this.assetId});

  final StudentQrResolutionStatus status;
  final String? assetId;
}

class StudentQrAssetResolver {
  StudentQrAssetResolver(this._lookup);

  final StudentAssetLookup _lookup;

  static final RegExp _assetQr = RegExp(r'^asset:([A-Za-z0-9_-]{1,150})$');

  static String? documentIdFromCanonicalQr(String value) {
    return _assetQr.firstMatch(value.trim())?.group(1);
  }

  Future<StudentQrResolution> resolve(String raw, {bool manual = false}) async {
    final value = raw.trim();
    if (value.isEmpty || value.length > 512) {
      return const StudentQrResolution(StudentQrResolutionStatus.invalid);
    }

    // The database, never the QR payload, supplies the route document ID.
    final exactId = await _lookup.findByQrValue(value);
    if (exactId != null) {
      return StudentQrResolution(
        StudentQrResolutionStatus.found,
        assetId: exactId,
      );
    }

    final documentId = documentIdFromCanonicalQr(value);
    if (documentId != null) {
      if (await _lookup.existsById(documentId)) {
        return StudentQrResolution(
          StudentQrResolutionStatus.found,
          assetId: documentId,
        );
      }
      return const StudentQrResolution(StudentQrResolutionStatus.notFound);
    }

    if (!manual) {
      return const StudentQrResolution(StudentQrResolutionStatus.invalid);
    }

    final codeId = await _lookup.findByCode(value.toUpperCase());
    if (codeId == null) {
      return const StudentQrResolution(StudentQrResolutionStatus.notFound);
    }
    return StudentQrResolution(
      StudentQrResolutionStatus.found,
      assetId: codeId,
    );
  }
}
