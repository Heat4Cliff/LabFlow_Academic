import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/maintenance_record.dart';

class MaintenanceService {
  MaintenanceService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  Stream<List<MaintenanceRecord>> watchByLaboratory(String laboratoryId) {
    final cleanLabId = laboratoryId.trim();

    if (cleanLabId.isEmpty) {
      return Stream.value(const <MaintenanceRecord>[]);
    }

    return _firestore
        .collection('maintenance_records')
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map(MaintenanceRecord.fromDocument)
              .toList(growable: false);

          records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return records;
        });
  }

  Stream<List<MaintenanceAssetOption>> watchAvailableAssets(
    String laboratoryId,
  ) {
    final cleanLabId = laboratoryId.trim();

    if (cleanLabId.isEmpty) {
      return Stream.value(const <MaintenanceAssetOption>[]);
    }

    return _firestore
        .collection('assets')
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final assets = snapshot.docs
              .map(MaintenanceAssetOption.fromDocument)
              .where((asset) => asset.canCreateMaintenance)
              .toList(growable: false);

          assets.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

          return assets;
        });
  }

  Future<MaintenanceRecord> getRecord(String maintenanceId) async {
    final cleanId = maintenanceId.trim();

    if (cleanId.isEmpty) {
      throw const MaintenanceException('ID maintenance tidak valid.');
    }

    final document = await _firestore
        .collection('maintenance_records')
        .doc(cleanId)
        .get();

    if (!document.exists) {
      throw const MaintenanceException('Data maintenance tidak ditemukan.');
    }

    return MaintenanceRecord.fromDocument(document);
  }

  /// Membuat maintenance manual dan mengeluarkan unit yang ditangani dari
  /// stok tersedia. Dengan demikian stok tidak dapat dipinjam selama unit
  /// tersebut berada pada proses maintenance.
  Future<void> createManualMaintenance({
    required String laboratoryId,
    required String assetId,
    required int quantity,
    required MaintenanceIssueCondition condition,
    required String description,
    String sourceType = 'manual',
    String? sourceId,
  }) async {
    final cleanLabId = laboratoryId.trim();
    final cleanAssetId = assetId.trim();
    final cleanDescription = description.trim();
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const MaintenanceException('Sesi Lab Admin tidak ditemukan.');
    }

    if (cleanLabId.isEmpty || cleanAssetId.isEmpty) {
      throw const MaintenanceException('Laboratorium dan aset wajib dipilih.');
    }

    if (quantity < 1) {
      throw const MaintenanceException('Jumlah unit maintenance minimal 1.');
    }

    if (cleanDescription.isEmpty) {
      throw const MaintenanceException('Deskripsi masalah wajib diisi.');
    }

    if (!{'manual', 'report'}.contains(sourceType)) {
      throw const MaintenanceException('Sumber maintenance tidak valid.');
    }

    final cleanSourceId = sourceId?.trim();

    if (sourceType == 'report' &&
        (cleanSourceId == null || cleanSourceId.isEmpty)) {
      throw const MaintenanceException(
        'ID laporan sumber maintenance tidak valid.',
      );
    }

    final assetReference = _firestore.collection('assets').doc(cleanAssetId);
    final maintenanceReference = sourceType == 'report'
        ? _firestore
              .collection('maintenance_records')
              .doc('report__$cleanSourceId')
        : _firestore.collection('maintenance_records').doc();

    try {
      await _firestore.runTransaction((transaction) async {
        final assetSnapshot = await transaction.get(assetReference);

        if (!assetSnapshot.exists) {
          throw const MaintenanceException(
            'Aset laboratorium tidak ditemukan.',
          );
        }

        final assetData = assetSnapshot.data();

        if (assetData == null) {
          throw const MaintenanceException(
            'Data aset laboratorium tidak valid.',
          );
        }

        final assetLabId = (assetData['labId'] as String? ?? '').trim();
        final stock = (assetData['stock'] as num?)?.toInt() ?? 0;
        final status = (assetData['status'] as String? ?? '').trim();

        if (assetLabId != cleanLabId) {
          throw const MaintenanceException(
            'Aset tidak berasal dari laboratorium yang dipilih.',
          );
        }

        if (status != 'available') {
          throw const MaintenanceException(
            'Maintenance manual hanya dapat dibuat dari aset yang tersedia.',
          );
        }

        if (stock < quantity) {
          throw MaintenanceException(
            'Stok aset hanya $stock unit. Jumlah maintenance terlalu besar.',
          );
        }

        final remainingStock = stock - quantity;

        transaction.update(assetReference, {
          'stock': remainingStock,
          'status': remainingStock == 0 ? 'maintenance' : 'available',
          'condition': remainingStock == 0
              ? condition.firestoreValue
              : (assetData['condition'] as String? ?? 'good'),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(maintenanceReference, {
          'labId': cleanLabId,
          'assetId': cleanAssetId,
          'assetCode': (assetData['code'] as String? ?? '').trim(),
          'assetName': (assetData['name'] as String? ?? '').trim(),
          'quantity': quantity,
          'condition': condition.firestoreValue,
          'description': cleanDescription,
          'status': 'pending',
          'sourceType': sourceType,
          'sourceId': sourceType == 'report' ? cleanSourceId : null,
          'createdBy': user.uid,
          'startedBy': null,
          'startedAt': null,
          'resolution': null,
          'resolutionNote': null,
          'completedBy': null,
          'completedAt': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const MaintenanceException(
          'Firestore menolak pembuatan maintenance. '
          'Periksa membership laboratorium dan rules.',
        );
      }

      if (error.code == 'aborted') {
        throw const MaintenanceException(
          'Data aset berubah saat maintenance dibuat. Muat ulang lalu coba lagi.',
        );
      }

      throw MaintenanceException('Maintenance gagal dibuat (${error.code}).');
    }
  }

  Future<MaintenanceRecord> startMaintenance(String maintenanceId) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const MaintenanceException('Sesi Lab Admin tidak ditemukan.');
    }

    final reference = _firestore
        .collection('maintenance_records')
        .doc(maintenanceId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(reference);

        if (!snapshot.exists) {
          throw const MaintenanceException('Data maintenance tidak ditemukan.');
        }

        final data = snapshot.data();

        if (data == null || data['status'] != 'pending') {
          throw const MaintenanceException(
            'Maintenance sudah tidak menunggu penanganan.',
          );
        }

        transaction.update(reference, {
          'status': 'in_progress',
          'startedBy': user.uid,
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const MaintenanceException(
          'Anda tidak memiliki izin memulai maintenance ini.',
        );
      }

      throw MaintenanceException('Maintenance gagal dimulai (${error.code}).');
    }

    return getRecord(maintenanceId);
  }

  /// Menyelesaikan maintenance.
  ///
  /// Jika berhasil diperbaiki, unit yang sebelumnya dikeluarkan dari stok
  /// dikembalikan ke stok tersedia. Jika tidak dapat diperbaiki, stok tetap.
  Future<MaintenanceRecord> completeMaintenance({
    required String maintenanceId,
    required MaintenanceResolution resolution,
    required String note,
  }) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const MaintenanceException('Sesi Lab Admin tidak ditemukan.');
    }

    final maintenanceReference = _firestore
        .collection('maintenance_records')
        .doc(maintenanceId);

    try {
      await _firestore.runTransaction((transaction) async {
        final maintenanceSnapshot = await transaction.get(maintenanceReference);

        if (!maintenanceSnapshot.exists) {
          throw const MaintenanceException('Data maintenance tidak ditemukan.');
        }

        final maintenanceData = maintenanceSnapshot.data();

        if (maintenanceData == null ||
            maintenanceData['status'] != 'in_progress') {
          throw const MaintenanceException(
            'Maintenance belum berada pada tahap penanganan.',
          );
        }

        final assetId = (maintenanceData['assetId'] as String? ?? '').trim();
        final labId = (maintenanceData['labId'] as String? ?? '').trim();
        final quantity = (maintenanceData['quantity'] as num?)?.toInt() ?? 1;

        if (assetId.isEmpty || labId.isEmpty || quantity < 1) {
          throw const MaintenanceException(
            'Relasi aset maintenance tidak valid.',
          );
        }

        final assetReference = _firestore.collection('assets').doc(assetId);
        final assetSnapshot = await transaction.get(assetReference);

        if (!assetSnapshot.exists) {
          throw const MaintenanceException('Aset maintenance tidak ditemukan.');
        }

        final assetData = assetSnapshot.data();

        if (assetData == null ||
            (assetData['labId'] as String? ?? '').trim() != labId) {
          throw const MaintenanceException(
            'Aset maintenance tidak sesuai dengan laboratorium.',
          );
        }

        final currentStock = (assetData['stock'] as num?)?.toInt() ?? 0;

        if (resolution == MaintenanceResolution.repaired) {
          final nextStock = currentStock + quantity;

          transaction.update(assetReference, {
            'stock': nextStock,
            'status': 'available',
            'condition': 'good',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.update(assetReference, {
            'status': currentStock > 0 ? 'available' : 'inactive',
            'condition': currentStock > 0
                ? (assetData['condition'] as String? ?? 'good')
                : 'damaged',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(maintenanceReference, {
          'status': 'completed',
          'resolution': resolution.firestoreValue,
          'resolutionNote': note.trim().isEmpty ? null : note.trim(),
          'completedBy': user.uid,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const MaintenanceException(
          'Firestore menolak penyelesaian maintenance. '
          'Periksa rules dan relasi aset.',
        );
      }

      if (error.code == 'aborted') {
        throw const MaintenanceException(
          'Data berubah saat maintenance diselesaikan. Muat ulang lalu coba lagi.',
        );
      }

      throw MaintenanceException(
        'Maintenance gagal diselesaikan (${error.code}).',
      );
    }

    return getRecord(maintenanceId);
  }
}

class MaintenanceException implements Exception {
  const MaintenanceException(this.message);

  final String message;

  @override
  String toString() => message;
}
