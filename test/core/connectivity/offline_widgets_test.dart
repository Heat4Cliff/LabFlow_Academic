import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/core/connectivity/connectivity_cubit.dart';
import 'package:labflow/core/connectivity/connectivity_service.dart';
import 'package:labflow/core/connectivity/connectivity_state.dart';
import 'package:labflow/core/connectivity/offline_banner.dart';
import 'package:labflow/shared/presentation/states/labflow_offline_empty_state.dart';

class _FakeConnectivityService implements ConnectivityService {
  @override
  Future<bool> hasNetworkInterface() async => false;

  @override
  Stream<bool> get networkInterfaceChanges => const Stream<bool>.empty();
}

void main() {
  testWidgets('offline banner appears while cached content remains visible', (
    tester,
  ) async {
    final service = _FakeConnectivityService();
    final cubit = ConnectivityCubit(
      service,
      initialStatus: ConnectivityStatus.offline,
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(
          home: OfflineBanner(child: Text('Home content')),
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Offline mode'), findsOneWidget);
    expect(find.text('Home content'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('offline cache miss has a dedicated retry state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: LabFlowOfflineEmptyState(onRetry: () {})),
      ),
    );

    expect(find.text('Belum ada data offline'), findsOneWidget);
    expect(find.text('Coba Lagi'), findsOneWidget);
  });
}
