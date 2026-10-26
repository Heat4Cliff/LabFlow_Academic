import 'package:cloud_firestore/cloud_firestore.dart';

/// Representasi satu aset yang sudah dialokasikan pada request peminjaman.
///
/// Satu document `borrowings` mewakili satu item request yang sudah dipasangkan
/// dengan aset inventaris aktual.
class PickupBorrowing {
  const PickupBorrowing({
    required this.id,
    required this.requestId,
    required this.requestNumber,
    required this.requestItemId,
    required this.itemName,
    required this.studentId,
    required this.labId,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.quantity,
    required this.status,
  });

  final String id;
  final String requestId;
  final String requestNumber;
  final String requestItemId;
  final String itemName;
  final String studentId;
  final String labId;
  final String assetId;
  final String assetCode;
  final String assetName;
  final int quantity;
  final String status;

  factory PickupBorrowing.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return PickupBorrowing(
      id: document.id,
      requestId: (data['requestId'] as String? ?? '').trim(),
      requestNumber: (data['requestNumber'] as String? ?? '').trim(),
      requestItemId: (data['requestItemId'] as String? ?? '').trim(),
      itemName: (data['itemName'] as String? ?? 'Aset laboratorium').trim(),
      studentId: (data['studentId'] as String? ?? '').trim(),
      labId: (data['labId'] as String? ?? '').trim(),
      assetId: (data['assetId'] as String? ?? '').trim(),
      assetCode: (data['assetCode'] as String? ?? '').trim(),
      assetName: (data['assetName'] as String? ?? 'Aset laboratorium').trim(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      status: (data['status'] as String? ?? '').trim(),
    );
  }
}
