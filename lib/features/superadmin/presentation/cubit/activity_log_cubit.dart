import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/activity_log_service.dart';
import '../../domain/activity_log.dart';

sealed class ActivityLogState {
  const ActivityLogState();
}

final class ActivityLogLoading extends ActivityLogState {
  const ActivityLogLoading();
}

final class ActivityLogFailure extends ActivityLogState {
  const ActivityLogFailure();
}

final class ActivityLogLoaded extends ActivityLogState {
  const ActivityLogLoaded({required this.activities, required this.filter});

  final List<ActivityLog> activities;
  final String filter;

  List<ActivityLog> get visibleActivities => filter == 'all'
      ? activities
      : activities.where((activity) => activity.type == filter).toList();
}

/// Memiliki tepat satu stream Activity Log dan menutupnya bersama lifecycle.
class ActivityLogCubit extends Cubit<ActivityLogState> {
  ActivityLogCubit(this._service) : super(const ActivityLogLoading());

  final ActivityLogService _service;
  StreamSubscription<List<ActivityLog>>? _subscription;
  List<ActivityLog> _activities = const [];
  String _filter = 'all';

  void start() {
    if (_subscription != null) return;
    _subscription = _service.watchActivities().listen((activities) {
      _activities = List.unmodifiable(activities);
      _emitLoaded();
    }, onError: (Object _) => emit(const ActivityLogFailure()));
  }

  void setFilter(String value) {
    _filter = value;
    _emitLoaded();
  }

  void _emitLoaded() =>
      emit(ActivityLogLoaded(activities: _activities, filter: _filter));

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
