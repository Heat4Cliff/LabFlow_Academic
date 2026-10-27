import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_service.dart';
import 'connectivity_state.dart';

class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(
    this._service, {
    ConnectivityStatus initialStatus = ConnectivityStatus.unknown,
  }) : super(ConnectivityState(initialStatus));

  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _service.networkInterfaceChanges.listen(
      _emitStatus,
      onError: (_) => emit(const ConnectivityState.unknown()),
    );
    try {
      _emitStatus(await _service.hasNetworkInterface());
    } catch (_) {
      emit(const ConnectivityState.unknown());
    }
  }

  void _emitStatus(bool available) {
    emit(
      ConnectivityState(
        available
            ? ConnectivityStatus.networkAvailable
            : ConnectivityStatus.offline,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
