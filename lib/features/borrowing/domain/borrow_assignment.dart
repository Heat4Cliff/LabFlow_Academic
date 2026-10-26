import 'package:cloud_firestore/cloud_firestore.dart';

/// Item permintaan yang akan dipasangkan dengan aset inventaris.
///
/// Model ini sengaja dipisahkan dari [BorrowRequestItem] karena kebutuhan
/// assignment memerlukan document ID Firestore sebagai identitas transaksi.
class AssignmentRequestItem {
  const AssignmentRequestItem({
    required this.documentId,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.requestedAssetId,
  });

  final String documentId;
  final String itemId;
  final String itemName;
  final int quantity;
  final String? requestedAssetId;

  factory AssignmentRequestItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return AssignmentRequestItem(
      documentId: document.id,
      itemId: (data['itemId'] as String? ?? '').trim(),
      itemName: (data['itemName'] as String? ?? 'Aset laboratorium').trim(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      requestedAssetId: (data['requestedAssetId'] as String?)?.trim(),
    );
  }
}

/// Ringkasan aset yang dapat dipilih pada proses penugasan.
class AssignableAsset {
  const AssignableAsset({
    required this.id,
    required this.labId,
    required this.code,
    required this.name,
    required this.location,
    required this.stock,
    required this.status,
    required this.condition,
  });

  final String id;
  final String labId;
  final String code;
  final String name;
  final String location;
  final int stock;
  final String status;
  final String condition;

  bool get isAssignable =>
      status == 'available' && condition != 'damaged' && stock > 0;

  factory AssignableAsset.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return AssignableAsset(
      id: document.id,
      labId: (data['labId'] as String? ?? '').trim(),
      code: (data['code'] as String? ?? '').trim(),
      name: (data['name'] as String? ?? 'Aset laboratorium').trim(),
      location: (data['location'] as String? ?? '-').trim(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String? ?? '').trim(),
      condition: (data['condition'] as String? ?? '').trim(),
    );
  }
}
