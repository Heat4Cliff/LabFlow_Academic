import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/notification_center_service.dart';
import '../../domain/app_notification.dart';

enum NotificationCenterStatus { initial, loading, loaded, failure }

class NotificationCenterState {
  const NotificationCenterState({
    this.status = NotificationCenterStatus.initial,
    this.notifications = const [],
    this.readingIds = const {},
    this.errorMessage = '',
  });

  final NotificationCenterStatus status;
  final List<AppNotification> notifications;
  final Set<String> readingIds;
  final String errorMessage;

  int get unreadCount => notifications.where((item) => !item.isRead).length;

  NotificationCenterState copyWith({
    NotificationCenterStatus? status,
    List<AppNotification>? notifications,
    Set<String>? readingIds,
    String? errorMessage,
  }) => NotificationCenterState(
    status: status ?? this.status,
    notifications: notifications ?? this.notifications,
    readingIds: readingIds ?? this.readingIds,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

class NotificationCenterCubit extends Cubit<NotificationCenterState> {
  NotificationCenterCubit(this._service)
    : super(const NotificationCenterState());

  final NotificationCenterService _service;
  StreamSubscription<List<AppNotification>>? _subscription;

  void start() {
    if (_subscription != null) return;
    emit(state.copyWith(status: NotificationCenterStatus.loading));
    _subscription = _service.watchMine().listen(
      (items) => emit(
        state.copyWith(
          status: NotificationCenterStatus.loaded,
          notifications: items,
          errorMessage: '',
        ),
      ),
      onError: (_) => emit(
        state.copyWith(
          status: NotificationCenterStatus.failure,
          errorMessage: 'Notifikasi tidak dapat dimuat. Periksa koneksi Anda.',
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

  Future<void> markAllRead() async {
    try {
      await _service.markAllRead(state.notifications);
    } catch (_) {
      emit(state.copyWith(errorMessage: 'Notifikasi gagal ditandai dibaca.'));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
