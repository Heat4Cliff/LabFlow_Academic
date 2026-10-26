import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.labId,
    required this.assetId,
    required this.assetCode,
    required this.assetName,
    required this.quantity,
    required this.condition,
    required this.description,
    required this.status,
    required this.sourceType,
    required this.sourceId,
    required this.createdBy,
    required this.startedBy,
    required this.startedAt,
    required this.resolution,
    required this.resolutionNote,
    required this.completedBy,
    required this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String labId;
  final String assetId;
  final String assetCode;
  final String assetName;
  final int quantity;
  final String condition;
  final String description;
  final String status;
  final String sourceType;
  final String? sourceId;
  final String createdBy;
  final String? startedBy;
  final DateTime? startedAt;
  final String? resolution;
  final String? resolutionNote;
  final String? completedBy;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPending => status == 'pending';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  factory MaintenanceRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return MaintenanceRecord(
      id: document.id,
      labId: (data['labId'] as String? ?? '').trim(),
      assetId: (data['assetId'] as String? ?? '').trim(),
      assetCode: (data['assetCode'] as String? ?? '').trim(),
      assetName: (data['assetName'] as String? ?? 'Aset laboratorium').trim(),
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      condition: (data['condition'] as String? ?? 'damaged').trim(),
      description: (data['description'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'pending').trim(),
      sourceType: (data['sourceType'] as String? ?? 'manual').trim(),
      sourceId: (data['sourceId'] as String?)?.trim(),
      createdBy: (data['createdBy'] as String? ?? '').trim(),
      startedBy: (data['startedBy'] as String?)?.trim(),
      startedAt: _dateTime(data['startedAt']),
      resolution: (data['resolution'] as String?)?.trim(),
      resolutionNote: (data['resolutionNote'] as String?)?.trim(),
      completedBy: (data['completedBy'] as String?)?.trim(),
      completedAt: _dateTime(data['completedAt']),
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

    return null;
  }
}

class MaintenanceAssetOption {
  const MaintenanceAssetOption({
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

  bool get canCreateMaintenance => status == 'available' && stock > 0;

  factory MaintenanceAssetOption.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return MaintenanceAssetOption(
      id: document.id,
      labId: (data['labId'] as String? ?? '').trim(),
      code: (data['code'] as String? ?? '').trim(),
      name: (data['name'] as String? ?? 'Aset laboratorium').trim(),
      location: (data['location'] as String? ?? '-').trim(),
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      status: (data['status'] as String? ?? '').trim(),
      condition: (data['condition'] as String? ?? 'good').trim(),
    );
  }
}

enum MaintenanceIssueCondition { minorDamage, damaged }

extension MaintenanceIssueConditionX on MaintenanceIssueCondition {
  String get firestoreValue {
    switch (this) {
      case MaintenanceIssueCondition.minorDamage:
        return 'minor_damage';
      case MaintenanceIssueCondition.damaged:
        return 'damaged';
    }
  }

  String get label {
    switch (this) {
      case MaintenanceIssueCondition.minorDamage:
        return 'Rusak Ringan';
      case MaintenanceIssueCondition.damaged:
        return 'Rusak';
    }
  }
}

enum MaintenanceResolution { repaired, unrepairable }

extension MaintenanceResolutionX on MaintenanceResolution {
  String get firestoreValue {
    switch (this) {
      case MaintenanceResolution.repaired:
        return 'repaired';
      case MaintenanceResolution.unrepairable:
        return 'unrepairable';
    }
  }

  String get label {
    switch (this) {
      case MaintenanceResolution.repaired:
        return 'Berhasil Diperbaiki';
      case MaintenanceResolution.unrepairable:
        return 'Tidak Dapat Diperbaiki';
    }
  }
}
