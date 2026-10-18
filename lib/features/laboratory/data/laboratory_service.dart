import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/laboratory.dart';

class LaboratoryService {
  LaboratoryService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Mengambil seluruh laboratorium secara realtime.
  Stream<List<Laboratory>> watchLaboratories() {
    return _firestore.collection('laboratories').snapshots().map((snapshot) {
      final laboratories = snapshot.docs.map(Laboratory.fromDocument).toList();

      laboratories.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return laboratories;
    });
  }

  /// Mengambil satu laboratorium berdasarkan document ID.
  Future<Laboratory> getLaboratory(String laboratoryId) async {
    final document = await _firestore
        .collection('laboratories')
        .doc(laboratoryId)
        .get();

    if (!document.exists) {
      throw const LaboratoryException('Laboratorium tidak ditemukan.');
    }

    return Laboratory.fromDocument(document);
  }

  /// Membuat laboratorium baru.
  Future<void> createLaboratory({
    required String name,
    required String code,
    required String description,
    required String location,
    required String status,
  }) async {
    final cleanName = name.trim();
    final cleanCode = code.trim().toUpperCase();
    final cleanDescription = description.trim();
    final cleanLocation = location.trim();

    _validateData(
      name: cleanName,
      code: cleanCode,
      location: cleanLocation,
      status: status,
    );

    final existingCode = await _firestore
        .collection('laboratories')
        .where('code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (existingCode.docs.isNotEmpty) {
      throw const LaboratoryException('Kode laboratorium sudah digunakan.');
    }

    final document = _firestore.collection('laboratories').doc();

    await document.set({
      'name': cleanName,
      'code': cleanCode,
      'description': cleanDescription,
      'location': cleanLocation,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Memperbarui data laboratorium.
  Future<void> updateLaboratory({
    required String laboratoryId,
    required String name,
    required String code,
    required String description,
    required String location,
    required String status,
  }) async {
    final cleanName = name.trim();
    final cleanCode = code.trim().toUpperCase();
    final cleanDescription = description.trim();
    final cleanLocation = location.trim();

    _validateData(
      name: cleanName,
      code: cleanCode,
      location: cleanLocation,
      status: status,
    );

    /// Mengecek apakah kode dipakai oleh laboratorium lain.
    final existingCode = await _firestore
        .collection('laboratories')
        .where('code', isEqualTo: cleanCode)
        .get();

    final duplicateExists = existingCode.docs.any(
      (document) => document.id != laboratoryId,
    );

    if (duplicateExists) {
      throw const LaboratoryException(
        'Kode laboratorium sudah digunakan oleh laboratorium lain.',
      );
    }

    final reference = _firestore.collection('laboratories').doc(laboratoryId);

    final existingLaboratory = await reference.get();

    if (!existingLaboratory.exists) {
      throw const LaboratoryException('Laboratorium tidak ditemukan.');
    }

    await reference.update({
      'name': cleanName,
      'code': cleanCode,
      'description': cleanDescription,
      'location': cleanLocation,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Menghapus laboratorium secara permanen.
  ///
  /// Hard-delete hanya diperbolehkan jika laboratorium
  /// belum pernah mempunyai membership.
  Future<void> deleteLaboratory(String laboratoryId) async {
    final laboratoryReference = _firestore
        .collection('laboratories')
        .doc(laboratoryId);

    final laboratory = await laboratoryReference.get();

    if (!laboratory.exists) {
      throw const LaboratoryException('Laboratorium tidak ditemukan.');
    }

    /// Cek relasi membership, termasuk membership
    /// yang sudah tidak aktif.
    final membershipQuery = await _firestore
        .collection('lab_memberships')
        .where('labId', isEqualTo: laboratoryId)
        .limit(1)
        .get();

    if (membershipQuery.docs.isNotEmpty) {
      throw const LaboratoryException(
        'Laboratorium sudah memiliki riwayat membership dan tidak dapat '
        'dihapus permanen. Ubah status menjadi Tidak Aktif.',
      );
    }

    await laboratoryReference.delete();
  }

  void _validateData({
    required String name,
    required String code,
    required String location,
    required String status,
  }) {
    if (name.isEmpty) {
      throw const LaboratoryException('Nama laboratorium wajib diisi.');
    }

    if (code.isEmpty) {
      throw const LaboratoryException('Kode laboratorium wajib diisi.');
    }

    if (location.isEmpty) {
      throw const LaboratoryException('Lokasi laboratorium wajib diisi.');
    }

    if (status != 'active' && status != 'inactive') {
      throw const LaboratoryException('Status laboratorium tidak valid.');
    }
  }
}

class LaboratoryException implements Exception {
  const LaboratoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
