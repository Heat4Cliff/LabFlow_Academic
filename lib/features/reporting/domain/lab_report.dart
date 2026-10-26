import 'package:cloud_firestore/cloud_firestore.dart';

class LabReport {
  const LabReport({
    required this.id,
    required this.reportNumber,
    required this.reporterId,
    required this.labId,
    required this.assetId,
    required this.category,
    required this.title,
    required this.description,
    required this.location,
    required this.severity,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.adminResponse,
    required this.createdAt,
    required this.acknowledgedAt,
    required this.resolvedAt,
    required this.closedAt,
    required this.updatedAt,
  });

  final String id;
  final String reportNumber;
  final String reporterId;
  final String labId;
  final String? assetId;
  final String category;
  final String title;
  final String description;
  final String location;
  final String severity;
  final String priority;
  final String status;
  final String? assignedTo;
  final String? adminResponse;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime updatedAt;

  bool get isOpen => status == 'open';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isRejected => status == 'rejected';
  bool get isClosed => status == 'closed';

  bool get isAssetRelated =>
      assetId != null &&
      assetId!.isNotEmpty &&
      {'asset_damage', 'computer', 'other'}.contains(category);

  factory LabReport.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return LabReport(
      id: document.id,
      reportNumber: (data['reportNumber'] as String? ?? document.id).trim(),
      reporterId: (data['reporterId'] as String? ?? '').trim(),
      labId: (data['labId'] as String? ?? '').trim(),
      assetId: _nullableString(data['assetId']),
      category: (data['category'] as String? ?? 'other').trim(),
      title: (data['title'] as String? ?? 'Laporan laboratorium').trim(),
      description: (data['description'] as String? ?? '').trim(),
      location: (data['location'] as String? ?? '-').trim(),
      severity: (data['severity'] as String? ?? 'normal').trim(),
      priority: (data['priority'] as String? ?? 'medium').trim(),
      status: (data['status'] as String? ?? 'open').trim(),
      assignedTo: _nullableString(data['assignedTo']),
      adminResponse: _nullableString(data['adminResponse']),
      createdAt:
          _dateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      acknowledgedAt: _dateTime(data['acknowledgedAt']),
      resolvedAt: _dateTime(data['resolvedAt']),
      closedAt: _dateTime(data['closedAt']),
      updatedAt:
          _dateTime(data['updatedAt']) ??
          _dateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static DateTime? _dateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  static String? _nullableString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final clean = value.trim();
    return clean.isEmpty ? null : clean;
  }
}
