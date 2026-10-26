import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/pickup_borrowing.dart';
import '../domain/return_inspection.dart';

class ReturnVerificationService {
  ReturnVerificationService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Memantau seluruh borrowing aktif pada satu request.
  Stream<List<PickupBorrowing>> watchActiveBorrowings({
    required String requestId,
    required String laboratoryId,
  }) {
    final cleanRequestId = requestId.trim();
    final cleanLabId = laboratoryId.trim();

    if (cleanRequestId.isEmpty || cleanLabId.isEmpty) {
      return Stream.value(const <PickupBorrowing>[]);
    }

    return _firestore
        .collection('borrowings')
        .where('requestId', isEqualTo: cleanRequestId)
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final borrowings = snapshot.docs
              .map(PickupBorrowing.fromDocument)
              .where((borrowing) => borrowing.status == 'active')
              .toList(growable: false);

          borrowings.sort((a, b) {
            final byName = a.assetName.toLowerCase().compareTo(
              b.assetName.toLowerCase(),
            );

            if (byName != 0) {
              return byName;
            }

            return a.assetCode.toLowerCase().compareTo(
              b.assetCode.toLowerCase(),
            );
          });

          return borrowings;
        });
  }

  /// Menyelesaikan pengembalian dan pemeriksaan kondisi secara atomik.
  ///
  /// Aturan stok:
  /// - Baik: kuantitas dikembalikan ke stok tersedia.
  /// - Rusak ringan / Rusak / Hilang: tidak menambah stok tersedia.
  ///
  /// Jika tidak ada stok tersedia setelah pengembalian:
  /// - Rusak ringan / Rusak -> maintenance.
  /// - Hilang -> inactive.
  Future<void> completeReturn({
    required String requestId,
    required String laboratoryId,
    required Map<String, ReturnCondition> conditionByBorrowing,
    required Map<String, String> noteByBorrowing,
  }) async {
    final cleanRequestId = requestId.trim();
    final cleanLabId = laboratoryId.trim();
    final user = _firebaseAuth.currentUser;

    if (cleanRequestId.isEmpty) {
      throw const ReturnVerificationException(
        'ID permintaan peminjaman tidak valid.',
      );
    }

    if (cleanLabId.isEmpty) {
      throw const ReturnVerificationException(
        'Laboratorium permintaan tidak valid.',
      );
    }

    if (user == null) {
      throw const ReturnVerificationException(
        'Sesi Lab Admin tidak ditemukan.',
      );
    }

    try {
      final borrowingQuery = await _firestore
          .collection('borrowings')
          .where('requestId', isEqualTo: cleanRequestId)
          .where('labId', isEqualTo: cleanLabId)
          .get();

      if (borrowingQuery.docs.isEmpty) {
        throw const ReturnVerificationException(
          'Data peminjaman aktif tidak ditemukan.',
        );
      }

      final activeDocuments = borrowingQuery.docs
          .where((document) {
            final data = document.data();
            return (data['status'] as String? ?? '').trim() == 'active';
          })
          .toList(growable: false);

      if (activeDocuments.isEmpty) {
        throw const ReturnVerificationException(
          'Tidak ada aset aktif yang dapat dikembalikan.',
        );
      }

      final activeIds = activeDocuments.map((document) => document.id).toSet();

      if (conditionByBorrowing.length != activeIds.length ||
          !activeIds.containsAll(conditionByBorrowing.keys)) {
        throw const ReturnVerificationException(
          'Kondisi seluruh aset wajib diperiksa sebelum pengembalian diselesaikan.',
        );
      }

      final requestReference = _firestore
          .collection('borrow_requests')
          .doc(cleanRequestId);

      await _firestore.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestReference);

        if (!requestSnapshot.exists) {
          throw const ReturnVerificationException(
            'Permintaan peminjaman tidak ditemukan.',
          );
        }

        final requestData = requestSnapshot.data();

        if (requestData == null) {
          throw const ReturnVerificationException(
            'Data permintaan peminjaman tidak valid.',
          );
        }

        final requestStatus = (requestData['status'] as String? ?? '').trim();
        final requestLabId = (requestData['labId'] as String? ?? '').trim();
        final requestStudentId = (requestData['studentId'] as String? ?? '')
            .trim();

        if (requestStatus != 'active') {
          throw const ReturnVerificationException(
            'Peminjaman sudah tidak berada pada status aktif.',
          );
        }

        if (requestLabId != cleanLabId) {
          throw const ReturnVerificationException(
            'Laboratorium request tidak sesuai dengan sesi pengembalian.',
          );
        }

        // =============================================================
        // READ PHASE
        // =============================================================

        final borrowingSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

        for (final document in activeDocuments) {
          final snapshot = await transaction.get(document.reference);

          if (!snapshot.exists) {
            throw const ReturnVerificationException(
              'Salah satu data peminjaman sudah tidak tersedia.',
            );
          }

          final data = snapshot.data();

          if (data == null) {
            throw const ReturnVerificationException(
              'Salah satu data peminjaman tidak valid.',
            );
          }

          final borrowingRequestId = (data['requestId'] as String? ?? '')
              .trim();
          final borrowingLabId = (data['labId'] as String? ?? '').trim();
          final borrowingStudentId = (data['studentId'] as String? ?? '')
              .trim();
          final borrowingStatus = (data['status'] as String? ?? '').trim();

          if (borrowingRequestId != cleanRequestId ||
              borrowingLabId != cleanLabId ||
              borrowingStudentId != requestStudentId) {
            throw const ReturnVerificationException(
              'Relasi data peminjaman tidak sesuai dengan request.',
            );
          }

          if (borrowingStatus != 'active') {
            throw const ReturnVerificationException(
              'Salah satu aset sudah tidak berstatus aktif.',
            );
          }

          if (!conditionByBorrowing.containsKey(snapshot.id)) {
            throw const ReturnVerificationException(
              'Kondisi salah satu aset belum diperiksa.',
            );
          }

          borrowingSnapshots.add(snapshot);
        }

        final assetSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};

        for (final borrowingSnapshot in borrowingSnapshots) {
          final data = borrowingSnapshot.data()!;
          final assetId = (data['assetId'] as String? ?? '').trim();

          if (assetId.isEmpty) {
            throw const ReturnVerificationException(
              'Aset pada data peminjaman tidak valid.',
            );
          }

          if (assetSnapshots.containsKey(assetId)) {
            continue;
          }

          final assetReference = _firestore.collection('assets').doc(assetId);
          final assetSnapshot = await transaction.get(assetReference);

          if (!assetSnapshot.exists) {
            throw const ReturnVerificationException(
              'Salah satu aset inventaris tidak ditemukan.',
            );
          }

          final assetData = assetSnapshot.data();

          if (assetData == null ||
              (assetData['labId'] as String? ?? '').trim() != cleanLabId) {
            throw const ReturnVerificationException(
              'Data aset inventaris tidak sesuai dengan laboratorium.',
            );
          }

          assetSnapshots[assetId] = assetSnapshot;
        }

        // Hitung dampak pengembalian per aset.
        final goodQuantityByAsset = <String, int>{};
        final hasMinorDamageByAsset = <String, bool>{};
        final hasDamageByAsset = <String, bool>{};
        final hasLostByAsset = <String, bool>{};

        for (final borrowingSnapshot in borrowingSnapshots) {
          final data = borrowingSnapshot.data()!;
          final assetId = (data['assetId'] as String).trim();
          final quantity = (data['quantity'] as num?)?.toInt() ?? 1;
          final condition = conditionByBorrowing[borrowingSnapshot.id]!;

          switch (condition) {
            case ReturnCondition.good:
              goodQuantityByAsset.update(
                assetId,
                (current) => current + quantity,
                ifAbsent: () => quantity,
              );
              break;
            case ReturnCondition.minorDamage:
              hasMinorDamageByAsset[assetId] = true;
              break;
            case ReturnCondition.damaged:
              hasDamageByAsset[assetId] = true;
              break;
            case ReturnCondition.lost:
              hasLostByAsset[assetId] = true;
              break;
          }
        }

        // =============================================================
        // WRITE PHASE
        // =============================================================

        for (final entry in assetSnapshots.entries) {
          final assetId = entry.key;
          final snapshot = entry.value;
          final data = snapshot.data()!;
          final currentStock = (data['stock'] as num?)?.toInt() ?? 0;
          final returnedGood = goodQuantityByAsset[assetId] ?? 0;
          final nextStock = currentStock + returnedGood;

          String nextStatus;
          String nextCondition;

          if (nextStock > 0) {
            // Masih ada unit yang sehat dan dapat dipinjam. Kondisi kerusakan
            // per unit tetap tersimpan pada borrowing, bukan dipaksakan ke
            // seluruh stok agregat.
            nextStatus = 'available';
            nextCondition = (data['condition'] as String? ?? 'good').trim();

            if (returnedGood > 0 && currentStock == 0) {
              nextCondition = 'good';
            }
          } else if (hasLostByAsset[assetId] == true) {
            nextStatus = 'inactive';
            nextCondition = 'damaged';
          } else if (hasDamageByAsset[assetId] == true) {
            nextStatus = 'maintenance';
            nextCondition = 'damaged';
          } else if (hasMinorDamageByAsset[assetId] == true) {
            nextStatus = 'maintenance';
            nextCondition = 'minor_damage';
          } else {
            // Kondisi defensif. Secara normal branch ini tidak tercapai karena
            // aset aktif minimal memiliki hasil pemeriksaan.
            nextStatus = 'inactive';
            nextCondition = (data['condition'] as String? ?? 'good').trim();
          }

          transaction.update(snapshot.reference, {
            'stock': nextStock,
            'status': nextStatus,
            'condition': nextCondition,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        for (final borrowingSnapshot in borrowingSnapshots) {
          final borrowingData = borrowingSnapshot.data()!;
          final condition = conditionByBorrowing[borrowingSnapshot.id]!;
          final note = (noteByBorrowing[borrowingSnapshot.id] ?? '').trim();

          transaction.update(borrowingSnapshot.reference, {
            'status': 'returned',
            'returnedAt': FieldValue.serverTimestamp(),
            'returnCondition': condition.firestoreValue,
            'returnNote': note.isEmpty ? null : note,
            'returnVerifiedBy': user.uid,
            'returnVerifiedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Kerusakan yang ditemukan saat pengembalian otomatis masuk ke
          // antrean Maintenance. ID dibuat deterministik agar satu borrowing
          // tidak menghasilkan record maintenance ganda.
          if (condition == ReturnCondition.minorDamage ||
              condition == ReturnCondition.damaged) {
            final maintenanceReference = _firestore
                .collection('maintenance_records')
                .doc('return__${borrowingSnapshot.id}');

            transaction.set(maintenanceReference, {
              'labId': cleanLabId,
              'assetId': (borrowingData['assetId'] as String? ?? '').trim(),
              'assetCode': (borrowingData['assetCode'] as String? ?? '').trim(),
              'assetName': (borrowingData['assetName'] as String? ?? '').trim(),
              'quantity': (borrowingData['quantity'] as num?)?.toInt() ?? 1,
              'condition': condition.firestoreValue,
              'description': note.isEmpty
                  ? 'Kerusakan ditemukan saat proses pengembalian.'
                  : note,
              'status': 'pending',
              'sourceType': 'return',
              'sourceId': borrowingSnapshot.id,
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
          }
        }

        transaction.update(requestReference, {
          'status': 'returned',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const ReturnVerificationException(
          'Firestore menolak penyelesaian pengembalian. '
          'Periksa rules dan relasi data peminjaman.',
        );
      }

      if (error.code == 'aborted') {
        throw const ReturnVerificationException(
          'Data berubah saat pengembalian diproses. Muat ulang lalu coba lagi.',
        );
      }

      throw ReturnVerificationException(
        'Pengembalian gagal diproses (${error.code}).',
      );
    }
  }
}

class ReturnVerificationException implements Exception {
  const ReturnVerificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
