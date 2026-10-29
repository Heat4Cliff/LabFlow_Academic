import 'package:cloud_firestore/cloud_firestore.dart';

class BorrowRequest {
  const BorrowRequest({
    required this.id,
    required this.requestNumber,
    required this.studentId,
    this.studentName,
    required this.labId,
    required this.purpose,
    required this.borrowDate,
    required this.expectedReturnDate,
    required this.status,
    required this.studentNote,
    required this.approvedBy,
    required this.approvedAt,
    required this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requestNumber;
  final String studentId;
  final String? studentName;
  String get studentNameLabel => studentName?.trim().isNotEmpty == true
      ? studentName!.trim()
      : 'Nama peminjam belum tersedia';
  final String labId;
  final String purpose;
  final DateTime borrowDate;
  final DateTime expectedReturnDate;
  final String status;
  final String? studentNote;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  factory BorrowRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw const FormatException(
        'Data permintaan peminjaman tidak ditemukan.',
      );
    }

    return BorrowRequest(
      id: document.id,
      requestNumber: data['requestNumber'] as String? ?? document.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String?,
      labId: data['labId'] as String? ?? '',
      purpose: data['purpose'] as String? ?? '',
      borrowDate:
          _dateTime(data['borrowDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expectedReturnDate:
          _dateTime(data['expectedReturnDate']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: data['status'] as String? ?? '',
      studentNote: data['studentNote'] as String?,
      approvedBy: data['approvedBy'] as String?,
      approvedAt: _dateTime(data['approvedAt']),
      rejectionReason: data['rejectionReason'] as String?,
      createdAt:
          _dateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          _dateTime(data['updatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

class BorrowRequestItem {
  const BorrowRequestItem({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.requestedAssetId,
    this.requestedAssetCode,
  });

  final String id;
  final String itemId;
  final String itemName;
  final int quantity;
  final String? requestedAssetId;
  final String? requestedAssetCode;
  String get subtitle =>
      'Jumlah $quantity${requestedAssetCode?.trim().isNotEmpty == true ? ' · Kode: ${requestedAssetCode!.trim()}' : ''}';

  factory BorrowRequestItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw const FormatException(
        'Item permintaan peminjaman tidak ditemukan.',
      );
    }

    return BorrowRequestItem(
      id: document.id,
      itemId: data['itemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? 'Aset laboratorium',
      quantity: data['quantity'] as int? ?? 1,
      requestedAssetId: data['requestedAssetId'] as String?,
      requestedAssetCode: data['requestedAssetCode'] as String?,
    );
  }
}
