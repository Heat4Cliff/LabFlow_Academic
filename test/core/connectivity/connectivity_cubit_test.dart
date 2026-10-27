import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/core/connectivity/connectivity_cubit.dart';
import 'package:labflow/core/connectivity/connectivity_service.dart';
import 'package:labflow/core/connectivity/connectivity_state.dart';

class _FakeConnectivityService implements ConnectivityService {
  final controller = StreamController<bool>.broadcast();
  bool available = true;

  @override
  Future<bool> hasNetworkInterface() async => available;

  @override
  Stream<bool> get networkInterfaceChanges => controller.stream;
}

void main() {
  test(
    'emits initial network availability, offline, and reconnect states',
    () async {
      final service = _FakeConnectivityService();
      final cubit = ConnectivityCubit(service);
      final states = <ConnectivityStatus>[];
      final subscription = cubit.stream.listen(
        (state) => states.add(state.status),
      );

      await cubit.start();
      service.controller.add(false);
      await Future<void>.delayed(Duration.zero);
      service.controller.add(true);
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        ConnectivityStatus.networkAvailable,
        ConnectivityStatus.offline,
        ConnectivityStatus.networkAvailable,
      ]);
      await subscription.cancel();
      await cubit.close();
      await service.controller.close();
    },
  );
}
