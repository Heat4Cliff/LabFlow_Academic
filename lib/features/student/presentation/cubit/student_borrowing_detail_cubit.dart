import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_borrowing_detail_service.dart';
import 'student_borrowing_detail_state.dart';

class StudentBorrowingDetailCubit extends Cubit<StudentBorrowingDetailState> {
  StudentBorrowingDetailCubit(this._service)
    : super(const StudentBorrowingDetailState());

  final StudentBorrowingDetailService _service;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  int _readySources = 0;
  String? _requestId;

  void watch(String requestId) {
    final id = requestId.trim();
    if (id.isEmpty) {
      emit(
        state.copyWith(
          status: StudentBorrowingDetailStatus.failure,
          errorMessage: 'ID pengajuan tidak valid.',
        ),
      );
      return;
    }
    _requestId = id;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    emit(
      state.copyWith(
        status: StudentBorrowingDetailStatus.loading,
        errorMessage: '',
      ),
    );
    _readySources = 0;
    _subscriptions.add(
      _service.watchRequest(id).listen((request) async {
        emit(state.copyWith(request: request));
        try {
          final name = await _service.loadLaboratoryName(request.labId);
          emit(state.copyWith(laboratoryName: name));
        } catch (_) {
          emit(state.copyWith(laboratoryName: 'Laboratorium'));
        }
        _markReady();
      }, onError: _fail),
    );
    _subscriptions.add(
      _service.watchItems(id).listen((items) {
        emit(state.copyWith(items: items));
        _markReady();
      }, onError: _fail),
    );
    _subscriptions.add(
      _service.watchAssignments(id).listen((items) {
        emit(state.copyWith(assignments: items));
        _markReady();
      }, onError: _fail),
    );
  }

  Future<void> retry() async {
    final id = _requestId;
    if (id == null) return;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    watch(id);
  }

  void _markReady() {
    _readySources++;
    if (_readySources >= 3) {
      emit(state.copyWith(status: StudentBorrowingDetailStatus.loaded));
    }
  }

  void _fail(Object error) {
    emit(
      state.copyWith(
        status: StudentBorrowingDetailStatus.failure,
        errorMessage: error is StudentBorrowingDetailException
            ? error.message
            : 'Detail peminjaman tidak dapat dimuat.',
      ),
    );
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
