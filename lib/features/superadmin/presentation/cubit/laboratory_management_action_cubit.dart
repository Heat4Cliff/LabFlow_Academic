import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/activity_log_service.dart';

/// Mengelola status operasi dan audit untuk perubahan laboratorium.
class LaboratoryManagementActionCubit extends Cubit<bool> {
  LaboratoryManagementActionCubit(this._laboratories, this._activityLog)
    : super(false);

  final LaboratoryService _laboratories;
  final ActivityLogService _activityLog;

  Future<Laboratory> getLaboratory(String id) =>
      _laboratories.getLaboratory(id);

  Future<void> createLaboratory({
    required String name,
    required String code,
    required String description,
    required String location,
    required String status,
  }) => _run(() async {
    await _laboratories.createLaboratory(
      name: name,
      code: code,
      description: description,
      location: location,
      status: status,
    );
    await _activityLog.createActivity(
      type: 'laboratory',
      title: 'Laboratorium dibuat',
      description:
          '$code — $name berhasil dibuat dengan status ${_statusLabel(status)}.',
      reference: code,
    );
  });

  Future<void> updateLaboratory({
    required String laboratoryId,
    required String name,
    required String code,
    required String description,
    required String location,
    required String status,
    required Laboratory original,
  }) => _run(() async {
    await _laboratories.updateLaboratory(
      laboratoryId: laboratoryId,
      name: name,
      code: code,
      description: description,
      location: location,
      status: status,
    );

    final generalDataChanged =
        original.name.trim() != name.trim() ||
        original.code.trim().toUpperCase() != code.trim().toUpperCase() ||
        original.location.trim() != location.trim() ||
        original.description.trim() != description.trim();
    if (generalDataChanged) {
      await _activityLog.createActivity(
        type: 'laboratory',
        title: 'Laboratorium diperbarui',
        description:
            '${code.trim().toUpperCase()} — ${name.trim()} berhasil diperbarui.',
        reference: code.trim().toUpperCase(),
      );
    }

    if (original.status != status) {
      final title = switch ((original.status, status)) {
        ('active', 'inactive') => 'Laboratorium dinonaktifkan',
        ('inactive', 'active') => 'Laboratorium diaktifkan kembali',
        _ => 'Status laboratorium diubah',
      };
      final description = switch ((original.status, status)) {
        ('active', 'inactive') =>
          '${code.trim().toUpperCase()} — ${name.trim()} dinonaktifkan.',
        ('inactive', 'active') =>
          '${code.trim().toUpperCase()} — ${name.trim()} diaktifkan kembali.',
        _ =>
          'Status ${code.trim().toUpperCase()} — ${name.trim()} diubah dari ${_statusLabel(original.status)} menjadi ${_statusLabel(status)}.',
      };
      await _activityLog.createActivity(
        type: 'laboratory',
        title: title,
        description: description,
        reference: code.trim().toUpperCase(),
      );
    }
  });

  Future<void> deleteLaboratory({
    required String laboratoryId,
    required String name,
    required String code,
  }) => _run(() async {
    await _laboratories.deleteLaboratory(laboratoryId);
    await _activityLog.createActivity(
      type: 'laboratory',
      title: 'Laboratorium dihapus',
      description: '$code — $name dihapus dari sistem.',
      reference: code,
    );
  });

  Future<void> _run(Future<void> Function() operation) async {
    if (state) return;
    emit(true);
    try {
      await operation();
    } finally {
      emit(false);
    }
  }

  String _statusLabel(String status) => switch (status) {
    'active' => 'Aktif',
    'inactive' => 'Tidak Aktif',
    _ => status,
  };
}
