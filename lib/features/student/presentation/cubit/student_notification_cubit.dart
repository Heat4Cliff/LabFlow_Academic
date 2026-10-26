import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/student_notification_service.dart';
import '../../domain/student_notification.dart';
import 'student_notification_state.dart';

class StudentNotificationCubit extends Cubit<StudentNotificationState> {
  StudentNotificationCubit(this._service)
    : super(const StudentNotificationState());
  final StudentNotificationService _service;
  StreamSubscription<List<StudentNotification>>? _subscription;

  void start() {
    if (_subscription != null) return;
    emit(state.copyWith(status: StudentNotificationStatus.loading));
    _subscription = _service.watchMine().listen(
      (items) => emit(
        state.copyWith(
          status: StudentNotificationStatus.loaded,
          notifications: items,
          errorMessage: '',
        ),
      ),
      onError: (_) => emit(
        state.copyWith(
          status: StudentNotificationStatus.failure,
          errorMessage: 'Notifikasi tidak dapat dimuat.',
        ),
      ),
    );
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _subscription = null;
    start();
  }

  Future<void> markRead(String id) async {
    if (state.readingIds.contains(id)) return;
    emit(
      state.copyWith(readingIds: {...state.readingIds, id}, errorMessage: ''),
    );
    try {
      await _service.markRead(id);
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Status notifikasi gagal diperbarui.'));
    } finally {
      emit(state.copyWith(readingIds: {...state.readingIds}..remove(id)));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
