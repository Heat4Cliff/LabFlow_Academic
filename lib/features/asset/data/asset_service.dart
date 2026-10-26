import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/laboratory_asset.dart';

class AssetService {
  AssetService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const Set<String> _allowedStatuses = {
    'available',

    'borrowed',

    'maintenance',

    'inactive',
  };

  static const Set<String> _allowedConditions = {
    'good',

    'minor_damage',

    'damaged',
  };

  /// Mengambil seluruh aset secara realtime.

  Stream<List<LaboratoryAsset>> watchAssets() {
    return _firestore.collection('assets').snapshots().map((snapshot) {
      final assets = snapshot.docs.map(LaboratoryAsset.fromDocument).toList();

      assets.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      return assets;
    });
  }

  /// Mengambil seluruh aset pada satu laboratorium.

  Stream<List<LaboratoryAsset>> watchAssetsByLaboratory(String laboratoryId) {
    return _firestore
        .collection('assets')
        .where('labId', isEqualTo: laboratoryId)
        .snapshots()
        .map((snapshot) {
          final assets = snapshot.docs
              .map(LaboratoryAsset.fromDocument)
              .toList();

          assets.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          return assets;
        });
  }

  /// Mengambil aset yang dapat digunakan Student.

  Stream<List<LaboratoryAsset>> watchAvailableAssetsByLaboratory(
    String laboratoryId,
  ) {
    return watchAssetsByLaboratory(laboratoryId).map(
      (assets) => assets
          .where(
            (asset) =>
                asset.status == 'available' &&
                asset.condition != 'damaged' &&
                asset.stock > 0,
          )
          .toList(),
    );
  }

  /// Mengambil satu aset berdasarkan document ID.

  Future<LaboratoryAsset> getAsset(String assetId) async {
    final document = await _firestore.collection('assets').doc(assetId).get();

    if (!document.exists) {
      throw const AssetException('Aset laboratorium tidak ditemukan.');
    }

    return LaboratoryAsset.fromDocument(document);
  }

  /// Mengambil satu aset berdasarkan nilai QR.

  Future<LaboratoryAsset> getAssetByQrValue(String qrValue) async {
    final cleanQrValue = qrValue.trim();

    if (cleanQrValue.isEmpty) {
      throw const AssetException('Kode QR aset tidak valid.');
    }

    final query = await _firestore
        .collection('assets')
        .where('qrValue', isEqualTo: cleanQrValue)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw const AssetException('Aset dengan QR tersebut tidak ditemukan.');
    }

    return LaboratoryAsset.fromDocument(query.docs.first);
  }

  /// Membuat aset baru.

  ///

  /// Status awal selalu available.

  Future<void> createAsset({
    required String laboratoryId,

    required String code,

    required String name,

    required String category,

    required String description,

    required String location,

    required int stock,

    required String condition,

    String imageUrl = '',
  }) async {
    final cleanLaboratoryId = laboratoryId.trim();

    final cleanCode = code.trim().toUpperCase();

    final cleanName = name.trim();

    final cleanCategory = category.trim();

    final cleanDescription = description.trim();

    final cleanLocation = location.trim();

    final cleanImageUrl = imageUrl.trim();

    _validateData(
      laboratoryId: cleanLaboratoryId,

      code: cleanCode,

      name: cleanName,

      category: cleanCategory,

      location: cleanLocation,

      stock: stock,

      status: 'available',

      condition: condition,
    );

    await _validateLaboratory(cleanLaboratoryId);

    /// Kode aset unik di dalam satu laboratorium.

    ///

    /// Query juga tetap berada dalam scope lab membership

    /// sehingga sesuai dengan Firestore Security Rules.

    final existingCode = await _firestore
        .collection('assets')
        .where('labId', isEqualTo: cleanLaboratoryId)
        .where('code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (existingCode.docs.isNotEmpty) {
      throw const AssetException(
        'Kode aset sudah digunakan pada laboratorium ini.',
      );
    }

    final document = _firestore.collection('assets').doc();

    await document.set({
      'labId': cleanLaboratoryId,

      'code': cleanCode,

      'name': cleanName,

      'category': cleanCategory,

      'description': cleanDescription,

      'location': cleanLocation,

      'stock': stock,

      'status': 'available',

      'condition': condition,

      'imageUrl': cleanImageUrl,

      'qrValue': 'asset:${document.id}',

      'createdAt': FieldValue.serverTimestamp(),

      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Memperbarui informasi aset.

  ///

  /// labId tidak dapat diganti melalui proses edit biasa.

  Future<void> updateAsset({
    required String assetId,

    required String code,

    required String name,

    required String category,

    required String description,

    required String location,

    required int stock,

    required String status,

    required String condition,
    String? imageUrl,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    final cleanName = name.trim();

    final cleanCategory = category.trim();

    final cleanDescription = description.trim();

    final cleanLocation = location.trim();
    final cleanImageUrl = imageUrl?.trim();

    final reference = _firestore.collection('assets').doc(assetId);

    final existingAsset = await reference.get();

    if (!existingAsset.exists) {
      throw const AssetException('Aset laboratorium tidak ditemukan.');
    }

    final currentAsset = LaboratoryAsset.fromDocument(existingAsset);

    _validateData(
      laboratoryId: currentAsset.labId,

      code: cleanCode,

      name: cleanName,

      category: cleanCategory,

      location: cleanLocation,

      stock: stock,

      status: status,

      condition: condition,
    );

    await _validateLaboratoryExists(currentAsset.labId);

    final existingCode = await _firestore
        .collection('assets')
        .where('labId', isEqualTo: currentAsset.labId)
        .where('code', isEqualTo: cleanCode)
        .get();

    final duplicateExists = existingCode.docs.any(
      (document) => document.id != assetId,
    );

    if (duplicateExists) {
      throw const AssetException(
        'Kode aset sudah digunakan oleh aset lain '
        'pada laboratorium ini.',
      );
    }

    await reference.update({
      'code': cleanCode,
      'name': cleanName,
      'category': cleanCategory,
      'description': cleanDescription,
      'location': cleanLocation,
      'stock': stock,
      'status': status,
      'condition': condition,
      'imageUrl': ?cleanImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Menghapus aset secara permanen.

  /// Hard-delete hanya diperbolehkan jika aset belum pernah

  /// memiliki riwayat peminjaman.

  Future<void> deleteAsset(String assetId) async {
    final reference = _firestore.collection('assets').doc(assetId);

    final assetDocument = await reference.get();

    if (!assetDocument.exists) {
      throw const AssetException('Aset laboratorium tidak ditemukan.');
    }

    final asset = LaboratoryAsset.fromDocument(assetDocument);

    if (asset.isBorrowed) {
      throw const AssetException(
        'Aset yang sedang dipinjam tidak dapat dihapus.',
      );
    }

    // Riwayat peminjaman harus tetap dapat diaudit. Query menggunakan
    // labId + assetId supaya akses dapat dibatasi oleh Firestore Rules.
    final borrowingQuery = await _firestore
        .collection('borrowings')
        .where('labId', isEqualTo: asset.labId)
        .where('assetId', isEqualTo: assetId)
        .limit(1)
        .get();

    if (borrowingQuery.docs.isNotEmpty) {
      throw const AssetException(
        'Aset sudah memiliki riwayat peminjaman dan tidak dapat '
        'dihapus permanen. Ubah status menjadi Tidak Aktif.',
      );
    }

    await reference.delete();
  }

  /// Memastikan laboratorium tersedia dan aktif.

  Future<void> _validateLaboratory(String laboratoryId) async {
    final laboratory = await _firestore
        .collection('laboratories')
        .doc(laboratoryId)
        .get();

    if (!laboratory.exists) {
      throw const AssetException('Laboratorium tidak ditemukan.');
    }

    final data = laboratory.data();

    if (data == null) {
      throw const AssetException('Data laboratorium tidak ditemukan.');
    }

    final status = data['status'] as String? ?? '';

    if (status != 'active') {
      throw const AssetException(
        'Aset hanya dapat ditambahkan ke laboratorium yang aktif.',
      );
    }
  }

  /// Memastikan relasi laboratorium pada aset masih valid.

  Future<void> _validateLaboratoryExists(String laboratoryId) async {
    final laboratory = await _firestore
        .collection('laboratories')
        .doc(laboratoryId)
        .get();

    if (!laboratory.exists) {
      throw const AssetException('Laboratorium aset tidak ditemukan.');
    }
  }

  void _validateData({
    required String laboratoryId,

    required String code,

    required String name,

    required String category,

    required String location,

    required int stock,

    required String status,

    required String condition,
  }) {
    if (laboratoryId.isEmpty) {
      throw const AssetException('Laboratorium wajib dipilih.');
    }

    if (code.isEmpty) {
      throw const AssetException('Kode aset wajib diisi.');
    }

    if (name.isEmpty) {
      throw const AssetException('Nama aset wajib diisi.');
    }

    if (category.isEmpty) {
      throw const AssetException('Kategori aset wajib diisi.');
    }

    if (location.isEmpty) {
      throw const AssetException('Lokasi aset wajib diisi.');
    }

    if (stock <= 0) {
      throw const AssetException('Stock aset minimal 1.');
    }

    if (!_allowedStatuses.contains(status)) {
      throw const AssetException('Status aset tidak valid.');
    }

    if (!_allowedConditions.contains(condition)) {
      throw const AssetException('Kondisi aset tidak valid.');
    }
  }
}

class AssetException implements Exception {
  const AssetException(this.message);

  final String message;

  @override
  String toString() => message;
}
