import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class ConnectivityService {
  Future<bool> hasNetworkInterface();
  Stream<bool> get networkInterfaceChanges;
}

class PluginConnectivityService implements ConnectivityService {
  PluginConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  bool _containsNetwork(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> hasNetworkInterface() async =>
      _containsNetwork(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get networkInterfaceChanges =>
      _connectivity.onConnectivityChanged.map(_containsNetwork).distinct();
}
