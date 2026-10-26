import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/borrow_assignment.dart';

class BorrowingAssignmentService {
  BorrowingAssignmentService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  /// Memantau item pada satu permintaan peminjaman.
  Stream<List<AssignmentRequestItem>> watchRequestItems(String requestId) {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      return Stream.value(const <AssignmentRequestItem>[]);
    }

    return _firestore
        .collection('borrow_requests')
        .doc(cleanId)
        .collection('items')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs
              .map(AssignmentRequestItem.fromDocument)
              .toList(growable: false);

          items.sort(
            (a, b) =>
                a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase()),
          );

          return items;
        });
  }

  /// Memantau aset yang masih dapat dialokasikan pada laboratorium request.
  ///
  /// Filter status/kondisi/stok dilakukan di client supaya query tetap
  /// sederhana dan tidak membutuhkan composite index baru.
  Stream<List<AssignableAsset>> watchAssignableAssets(String laboratoryId) {
    final cleanLabId = laboratoryId.trim();

    if (cleanLabId.isEmpty) {
      return Stream.value(const <AssignableAsset>[]);
    }

    return _firestore
        .collection('assets')
        .where('labId', isEqualTo: cleanLabId)
        .snapshots()
        .map((snapshot) {
          final assets = snapshot.docs
              .map(AssignableAsset.fromDocument)
              .where((asset) => asset.isAssignable)
              .toList(growable: false);

          assets.sort((a, b) {
            final nameCompare = a.name.toLowerCase().compareTo(
              b.name.toLowerCase(),
            );

            if (nameCompare != 0) {
              return nameCompare;
            }

            return a.code.toLowerCase().compareTo(b.code.toLowerCase());
          });

          return assets;
        });
  }

  /// Menugaskan aset untuk seluruh item pada request yang sudah disetujui.
  ///
  /// Satu dokumen `borrowings` dibuat untuk setiap item request agar:
  /// - riwayat aset dapat ditelusuri melalui `assetId`;
  /// - pengecekan hard-delete AssetService tetap kompatibel;
  /// - pickup/return berikutnya dapat diproses per assignment.
  ///
  /// Seluruh perubahan stok, pembuatan borrowing, dan perubahan status request
  /// dilakukan secara atomik melalui Firestore Transaction.
  Future<void> assignApprovedRequest({
    required String requestId,
    required Map<String, String> assetByRequestItem,
  }) async {
    final cleanRequestId = requestId.trim();
    final user = _firebaseAuth.currentUser;

    if (cleanRequestId.isEmpty) {
      throw const BorrowingAssignmentException(
        'ID permintaan peminjaman tidak valid.',
      );
    }

    if (user == null) {
      throw const BorrowingAssignmentException(
        'Sesi Lab Admin tidak ditemukan.',
      );
    }

    final requestReference = _firestore
        .collection('borrow_requests')
        .doc(cleanRequestId);

    // Item tidak dapat diubah setelah request keluar dari status pending,
    // sehingga pembacaan daftar item sebelum transaction aman digunakan untuk
    // memastikan seluruh item telah mendapatkan pilihan aset.
    final itemQuery = await requestReference.collection('items').get();

    if (itemQuery.docs.isEmpty) {
      throw const BorrowingAssignmentException(
        'Permintaan tidak memiliki item yang dapat ditugaskan.',
      );
    }

    final itemIds = itemQuery.docs.map((document) => document.id).toSet();
    final selectedItemIds = assetByRequestItem.keys.toSet();

    if (itemIds.length != selectedItemIds.length ||
        !itemIds.containsAll(selectedItemIds)) {
      throw const BorrowingAssignmentException(
        'Semua item wajib memiliki aset sebelum penugasan dikonfirmasi.',
      );
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final requestSnapshot = await transaction.get(requestReference);

        if (!requestSnapshot.exists) {
          throw const BorrowingAssignmentException(
            'Permintaan peminjaman tidak ditemukan.',
          );
        }

        final requestData = requestSnapshot.data();

        if (requestData == null) {
          throw const BorrowingAssignmentException(
            'Data permintaan peminjaman tidak valid.',
          );
        }

        if (requestData['status'] != 'approved') {
          throw const BorrowingAssignmentException(
            'Permintaan sudah tidak berada pada tahap penugasan aset.',
          );
        }

        final requestLabId = (requestData['labId'] as String? ?? '').trim();

        if (requestLabId.isEmpty) {
          throw const BorrowingAssignmentException(
            'Laboratorium permintaan tidak valid.',
          );
        }

        // ---------------------------------------------------------------
        // READ PHASE
        // Semua pembacaan dilakukan sebelum write agar transaction Firestore
        // tetap valid.
        // ---------------------------------------------------------------

        final resolvedItems = <AssignmentRequestItem>[];

        for (final itemDocument in itemQuery.docs) {
          final itemReference = requestReference
              .collection('items')
              .doc(itemDocument.id);
          final itemSnapshot = await transaction.get(itemReference);

          if (!itemSnapshot.exists) {
            throw const BorrowingAssignmentException(
              'Salah satu item permintaan sudah tidak tersedia.',
            );
          }

          final item = AssignmentRequestItem.fromDocument(itemSnapshot);

          if (item.quantity < 1) {
            throw const BorrowingAssignmentException(
              'Jumlah item permintaan tidak valid.',
            );
          }

          resolvedItems.add(item);
        }

        final requiredQuantityByAsset = <String, int>{};

        for (final item in resolvedItems) {
          final assetId = assetByRequestItem[item.documentId]?.trim() ?? '';

          if (assetId.isEmpty) {
            throw BorrowingAssignmentException(
              'Aset untuk ${item.itemName} belum dipilih.',
            );
          }

          requiredQuantityByAsset.update(
            assetId,
            (current) => current + item.quantity,
            ifAbsent: () => item.quantity,
          );
        }

        final assetSnapshots =
            <String, DocumentSnapshot<Map<String, dynamic>>>{};

        for (final entry in requiredQuantityByAsset.entries) {
          final assetReference = _firestore.collection('assets').doc(entry.key);
          final assetSnapshot = await transaction.get(assetReference);

          if (!assetSnapshot.exists) {
            throw const BorrowingAssignmentException(
              'Aset yang dipilih tidak ditemukan.',
            );
          }

          final assetData = assetSnapshot.data();

          if (assetData == null) {
            throw const BorrowingAssignmentException(
              'Data aset yang dipilih tidak valid.',
            );
          }

          final labId = (assetData['labId'] as String? ?? '').trim();
          final status = (assetData['status'] as String? ?? '').trim();
          final condition = (assetData['condition'] as String? ?? '').trim();
          final stock = (assetData['stock'] as num?)?.toInt() ?? 0;

          if (labId != requestLabId) {
            throw const BorrowingAssignmentException(
              'Aset tidak berasal dari laboratorium permintaan.',
            );
          }

          if (status != 'available' || condition == 'damaged') {
            throw const BorrowingAssignmentException(
              'Salah satu aset sudah tidak tersedia untuk dipinjam.',
            );
          }

          if (stock < entry.value) {
            final assetName =
                (assetData['name'] as String? ?? 'Aset laboratorium').trim();

            throw BorrowingAssignmentException(
              'Stok $assetName tidak mencukupi untuk jumlah yang diminta.',
            );
          }

          assetSnapshots[entry.key] = assetSnapshot;
        }

        // Jangan melakukan transaction.get() ke dokumen `borrowings` yang
        // belum ada. Rule read untuk `borrowings` menggunakan `resource.data`
        // sehingga read terhadap dokumen non-existent tidak dapat dievaluasi
        // untuk Lab Admin dan dapat menghasilkan PERMISSION_DENIED.
        //
        // Duplikasi tetap aman: jika document ID borrowing sudah ada,
        // transaction.set() di bawah akan dievaluasi sebagai UPDATE. Rules
        // Borrowing Phase 3 menutup update, sehingga overwrite akan ditolak.

        // ---------------------------------------------------------------
        // WRITE PHASE
        // ---------------------------------------------------------------

        for (final entry in requiredQuantityByAsset.entries) {
          final assetSnapshot = assetSnapshots[entry.key]!;
          final assetData = assetSnapshot.data()!;
          final currentStock = (assetData['stock'] as num?)?.toInt() ?? 0;
          final remainingStock = currentStock - entry.value;

          transaction.update(assetSnapshot.reference, {
            'stock': remainingStock,
            'status': remainingStock == 0 ? 'borrowed' : 'available',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        for (final item in resolvedItems) {
          final assetId = assetByRequestItem[item.documentId]!.trim();
          final assetSnapshot = assetSnapshots[assetId]!;
          final assetData = assetSnapshot.data()!;
          final borrowingId = '${cleanRequestId}__${item.documentId}';
          final borrowingReference = _firestore
              .collection('borrowings')
              .doc(borrowingId);

          transaction.set(borrowingReference, {
            'requestId': cleanRequestId,
            'requestNumber': (requestData['requestNumber'] as String? ?? '')
                .trim(),
            'requestItemId': item.documentId,
            'itemId': item.itemId,
            'itemName': item.itemName,
            'studentId': (requestData['studentId'] as String? ?? '').trim(),
            'labId': requestLabId,
            'assetId': assetId,
            'assetCode': (assetData['code'] as String? ?? '').trim(),
            'assetName': (assetData['name'] as String? ?? '').trim(),
            'quantity': item.quantity,
            'borrowDate': requestData['borrowDate'],
            'expectedReturnDate': requestData['expectedReturnDate'],
            'status': 'waiting_pickup',
            'assignedBy': user.uid,
            'assignedAt': FieldValue.serverTimestamp(),
            'pickupVerifiedBy': null,
            'pickupVerifiedAt': null,
            'returnedAt': null,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(requestReference, {
          'status': 'waiting_pickup',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw const BorrowingAssignmentException(
          'Firestore menolak proses penugasan aset. '
          'Periksa rules atau data relasi request, aset, dan laboratorium.',
        );
      }

      if (error.code == 'aborted') {
        throw const BorrowingAssignmentException(
          'Data berubah saat penugasan diproses. Muat ulang lalu coba lagi.',
        );
      }

      throw BorrowingAssignmentException(
        'Penugasan aset gagal diproses (${error.code}).',
      );
    }
  }
}

class BorrowingAssignmentException implements Exception {
  const BorrowingAssignmentException(this.message);

  final String message;

  @override
  String toString() => message;
}
