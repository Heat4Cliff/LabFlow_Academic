enum ConnectivityStatus { unknown, offline, networkAvailable }

class ConnectivityState {
  const ConnectivityState(this.status);

  const ConnectivityState.unknown() : status = ConnectivityStatus.unknown;

  final ConnectivityStatus status;

  bool get isOffline => status == ConnectivityStatus.offline;
  bool get hasNetwork => status == ConnectivityStatus.networkAvailable;
}
