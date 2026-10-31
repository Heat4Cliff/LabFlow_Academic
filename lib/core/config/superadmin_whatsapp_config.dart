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
  SuperadminWhatsAppConfig({RemoteConfigReader? reader})
    : _reader = reader ?? FirebaseRemoteConfigReader();

  final RemoteConfigReader _reader;

  Future<String?> loadNumber() async {
    try {
      await _reader.configure();
      await _reader.fetchAndActivate();
    } catch (_) {
      // The Firebase SDK retains the last activated value in its local cache.
    }

    try {
      return normalize(_reader.getString(AppConfig.superadminWhatsAppKey));
    } catch (_) {
      return null;
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
