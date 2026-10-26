import 'package:cloud_firestore/cloud_firestore.dart';

class StudentProfile {
  const StudentProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.status,
  });

  final String uid;
  final String fullName;
  final String email;
  final String status;

  String get displayName =>
      fullName.trim().isEmpty ? 'Mahasiswa' : fullName.trim();

  String get firstName {
    final parts = displayName.split(RegExp(r'\s+'));
    return parts.isEmpty ? displayName : parts.first;
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);

    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class StudentLaboratory {
  const StudentLaboratory({
    required this.id,
    required this.code,
    required this.name,
    required this.location,
  });

  final String id;
  final String code;
  final String name;
  final String location;

  factory StudentLaboratory.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return StudentLaboratory(
      id: document.id,
      code: (data['code'] as String? ?? '-').trim(),
      name: (data['name'] as String? ?? 'Laboratorium').trim(),
      location: (data['location'] as String? ?? '-').trim(),
    );
  }
}

class StudentAsset {
  const StudentAsset({
    required this.id,
    required this.labId,
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.stock,
    required this.status,
    required this.condition,
    required this.qrValue,
    this.imageUrl,
  });

  final String id;
  final String labId;
  final String code;
  final String name;
  final String category;
  final String description;
  final String location;
  final int stock;
  final String status;
  final String condition;
  final String qrValue;
  final String? imageUrl;

  bool get isAvailable => status == 'available' && stock > 0;

  factory StudentAsset.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return StudentAsset(
      id: document.id,
      labId: (data['labId'] as String? ?? '').trim(),
      code: (data['code'] as String? ?? '-').trim(),
      name: (data['name'] as String? ?? 'Aset').trim(),
      category: (data['category'] as String? ?? 'Other').trim(),
      description: (data['description'] as String? ?? '').trim(),
      location: (data['location'] as String? ?? '-').trim(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String? ?? 'inactive').trim(),
      condition: (data['condition'] as String? ?? 'good').trim(),
      qrValue: (data['qrValue'] as String? ?? '').trim(),
      imageUrl: (data['imageUrl'] as String?)?.trim(),
    );
  }
}

class StudentBorrowRequest {
  const StudentBorrowRequest({
    required this.id,
    required this.requestNumber,
    required this.labId,
    required this.purpose,
    required this.status,
    required this.borrowDate,
    required this.expectedReturnDate,
    required this.createdAt,
    this.rejectionReason,
  });

  final String id;
  final String requestNumber;
  final String labId;
  final String purpose;
  final String status;
  final DateTime borrowDate;
  final DateTime expectedReturnDate;
  final DateTime createdAt;
  final String? rejectionReason;

  factory StudentBorrowRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return StudentBorrowRequest(
      id: document.id,
      requestNumber: (data['requestNumber'] as String? ?? '-').trim(),
      labId: (data['labId'] as String? ?? '').trim(),
      purpose: (data['purpose'] as String? ?? '-').trim(),
      status: (data['status'] as String? ?? 'pending').trim(),
      borrowDate: _date(data['borrowDate']),
      expectedReturnDate: _date(data['expectedReturnDate']),
      createdAt: _date(data['createdAt']),
      rejectionReason: (data['rejectionReason'] as String?)?.trim(),
    );
  }
}

class StudentBorrowSubmissionResult {
  const StudentBorrowSubmissionResult({
    required this.requestId,
    required this.requestNumber,
  });

  final String requestId;
  final String requestNumber;
}

class StudentReport {
  const StudentReport({
    required this.id,
    required this.reportNumber,
    required this.labId,
    required this.category,
    required this.title,
    required this.location,
    required this.severity,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.assetId,
    this.adminResponse,
  });

  final String id;
  final String reportNumber;
  final String labId;
  final String category;
  final String title;
  final String location;
  final String severity;
  final String priority;
  final String status;
  final DateTime createdAt;
  final String? assetId;
  final String? adminResponse;

  factory StudentReport.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return StudentReport(
      id: document.id,
      reportNumber: (data['reportNumber'] as String? ?? '-').trim(),
      labId: (data['labId'] as String? ?? '').trim(),
      category: (data['category'] as String? ?? 'other').trim(),
      title: (data['title'] as String? ?? 'Laporan').trim(),
      location: (data['location'] as String? ?? '-').trim(),
      severity: (data['severity'] as String? ?? 'normal').trim(),
      priority: (data['priority'] as String? ?? 'medium').trim(),
      status: (data['status'] as String? ?? 'open').trim(),
      createdAt: _date(data['createdAt']),
      assetId: (data['assetId'] as String?)?.trim(),
      adminResponse: (data['adminResponse'] as String?)?.trim(),
    );
  }
}

class StudentHomeData {
  const StudentHomeData({
    required this.profile,
    required this.laboratories,
    required this.assets,
    required this.borrowRequests,
    required this.reports,
  });

  final StudentProfile profile;
  final List<StudentLaboratory> laboratories;
  final List<StudentAsset> assets;
  final List<StudentBorrowRequest> borrowRequests;
  final List<StudentReport> reports;
}

DateTime _date(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.fromMillisecondsSinceEpoch(0);
}
