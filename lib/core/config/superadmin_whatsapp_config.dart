import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'app_config.dart';

abstract interface class RemoteConfigReader {
  Future<void> configure();

  Future<bool> fetchAndActivate();

  String getString(String key);
}

class FirebaseRemoteConfigReader implements RemoteConfigReader {
  FirebaseRemoteConfigReader({FirebaseRemoteConfig? remoteConfig})
    : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> configure() async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await _remoteConfig.setDefaults(const {
      AppConfig.superadminWhatsAppKey: '',
    });
  }

  @override
  Future<bool> fetchAndActivate() => _remoteConfig.fetchAndActivate();

  @override
  String getString(String key) => _remoteConfig.getString(key);
}

class SuperadminWhatsAppConfig {
  SuperadminWhatsAppConfig._(this._reader);

  static final SuperadminWhatsAppConfig instance = SuperadminWhatsAppConfig._(
    FirebaseRemoteConfigReader(),
  );

  SuperadminWhatsAppConfig.forTesting(RemoteConfigReader reader)
    : this._(reader);

  final RemoteConfigReader _reader;
  Future<void>? _initialization;
  String? _number;

  String? get number => _number;

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _reader.configure();
      await _reader.fetchAndActivate();
    } catch (_) {
      // The Firebase SDK retains the last activated value in its local cache.
    }

    try {
      _number = normalize(_reader.getString(AppConfig.superadminWhatsAppKey));
    } catch (_) {
      _number = null;
    }
  }

  static String? normalize(String raw) {
    final value = raw.trim();
    if (value.isEmpty || !RegExp(r'^\+?[0-9][0-9\s().-]*$').hasMatch(value)) {
      return null;
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15 || digits.startsWith('0')) {
      return null;
    }
    return digits;
  }
}
