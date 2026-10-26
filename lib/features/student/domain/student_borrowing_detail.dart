import 'package:cloud_firestore/cloud_firestore.dart';

import '../../borrowing/domain/borrow_request.dart';

class StudentAssignedBorrowing {
  const StudentAssignedBorrowing({
    required this.id,
    required this.assetName,
    required this.assetCode,
    required this.quantity,
    required this.status,
    this.pickupAt,
    this.returnedAt,
    this.returnCondition,
    this.returnNote,
  });

  final String id;
  final String assetName;
  final String assetCode;
  final int quantity;
  final String status;
  final DateTime? pickupAt;
  final DateTime? returnedAt;
  final String? returnCondition;
  final String? returnNote;

  factory StudentAssignedBorrowing.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return StudentAssignedBorrowing(
      id: document.id,
      assetName: (data['assetName'] as String? ?? 'Aset laboratorium').trim(),
      assetCode: (data['assetCode'] as String? ?? '').trim(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      status: (data['status'] as String? ?? '').trim(),
      pickupAt: _date(data['pickupVerifiedAt']),
      returnedAt: _date(data['returnedAt']),
      returnCondition: (data['returnCondition'] as String?)?.trim(),
      returnNote: (data['returnNote'] as String?)?.trim(),
    );
  }
}

DateTime? _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

class StudentBorrowingDetail {
  const StudentBorrowingDetail({
    required this.request,
    required this.items,
    required this.assignments,
    required this.laboratoryName,
  });

  final BorrowRequest request;
  final List<BorrowRequestItem> items;
  final List<StudentAssignedBorrowing> assignments;
  final String laboratoryName;
}
