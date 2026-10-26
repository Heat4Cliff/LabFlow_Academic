import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';

sealed class LaboratoryDirectoryState {
  const LaboratoryDirectoryState();
}

final class LaboratoryDirectoryLoading extends LaboratoryDirectoryState {
  const LaboratoryDirectoryLoading();
}

final class LaboratoryDirectoryFailure extends LaboratoryDirectoryState {
  const LaboratoryDirectoryFailure();
}

final class LaboratoryDirectoryLoaded extends LaboratoryDirectoryState {
  const LaboratoryDirectoryLoaded({
    required this.laboratories,
    required this.query,
    required this.status,
  });

  final List<Laboratory> laboratories;
  final String query;
  final String status;

  List<Laboratory> get visibleLaboratories => laboratories
      .where((laboratory) {
        final normalizedQuery = query.trim().toLowerCase();
        final matchesQuery =
            normalizedQuery.isEmpty ||
            laboratory.name.toLowerCase().contains(normalizedQuery) ||
            laboratory.code.toLowerCase().contains(normalizedQuery) ||
            laboratory.location.toLowerCase().contains(normalizedQuery);
        final matchesStatus = status == 'all' || laboratory.status == status;
        return matchesQuery && matchesStatus;
      })
      .toList(growable: false);
}

/// Mengelola stream laboratorium serta filter halaman Superadmin.
class LaboratoryDirectoryCubit extends Cubit<LaboratoryDirectoryState> {
  LaboratoryDirectoryCubit(this._service)
    : super(const LaboratoryDirectoryLoading());

  final LaboratoryService _service;
  StreamSubscription<List<Laboratory>>? _subscription;
  List<Laboratory> _laboratories = const [];
  String _query = '';
  String _status = 'all';

  void start() {
    if (_subscription != null) return;
    _subscription = _service.watchLaboratories().listen((laboratories) {
      _laboratories = List.unmodifiable(laboratories);
      _emitLoaded();
    }, onError: (Object _) => emit(const LaboratoryDirectoryFailure()));
  }

  void setQuery(String value) {
    _query = value;
    _emitLoaded();
  }

  void setStatus(String value) {
    _status = value;
    _emitLoaded();
  }

  void _emitLoaded() => emit(
    LaboratoryDirectoryLoaded(
      laboratories: _laboratories,
      query: _query,
      status: _status,
    ),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
