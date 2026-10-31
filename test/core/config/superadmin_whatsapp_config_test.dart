import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/core/config/app_config.dart';
import 'package:labflow/core/config/superadmin_whatsapp_config.dart';

class _FakeRemoteConfigReader implements RemoteConfigReader {
  _FakeRemoteConfigReader({this.value = '', this.fetchError});

  String value;
  Object? fetchError;
  int configureCalls = 0;
  int fetchCalls = 0;

  @override
  Future<void> configure() async => configureCalls++;

  @override
  Future<bool> fetchAndActivate() async {
    fetchCalls++;
    if (fetchError != null) throw fetchError!;
    return true;
  }

  @override
  String getString(String key) {
    expect(key, AppConfig.superadminWhatsAppKey);
    return value;
  }
}

void main() {
  test('normalizes a valid international number to digits only', () {
    expect(
      SuperadminWhatsAppConfig.normalize('+62 812-3456-7890'),
      '6281234567890',
    );
  });

  test('rejects empty and local format numbers', () {
    expect(SuperadminWhatsAppConfig.normalize(''), isNull);
    expect(SuperadminWhatsAppConfig.normalize('081234567890'), isNull);
  });

  test('rejects malformed numbers', () {
    expect(SuperadminWhatsAppConfig.normalize('62ABC123456'), isNull);
    expect(SuperadminWhatsAppConfig.normalize('123'), isNull);
    expect(SuperadminWhatsAppConfig.normalize('+62 0000'), isNull);
  });

  test('uses cached value when Remote Config fetch fails', () async {
    final reader = _FakeRemoteConfigReader(
      value: '+62 812 3456 7890',
      fetchError: StateError('offline'),
    );

    final number = await SuperadminWhatsAppConfig(reader: reader).loadNumber();

    expect(number, '6281234567890');
    expect(reader.configureCalls, 1);
    expect(reader.fetchCalls, 1);
  });

  test('returns null when Remote Config contains no valid contact', () async {
    final reader = _FakeRemoteConfigReader(value: 'not-a-number');

    expect(await SuperadminWhatsAppConfig(reader: reader).loadNumber(), isNull);
  });
}
