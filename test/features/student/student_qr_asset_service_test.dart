import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/student/data/student_qr_asset_service.dart';

class _Lookup implements StudentAssetLookup {
  final Map<String, String> qr = {};
  final Map<String, String> code = {};
  final Set<String> ids = {};
  final List<String> calls = [];

  @override
  Future<String?> findByQrValue(String value) async {
    calls.add('qr:$value');
    return qr[value];
  }

  @override
  Future<bool> existsById(String documentId) async {
    calls.add('id:$documentId');
    return ids.contains(documentId);
  }

  @override
  Future<String?> findByCode(String value) async {
    calls.add('code:$value');
    return code[value];
  }
}

void main() {
  test('exact qrValue resolves to authoritative document ID', () async {
    final lookup = _Lookup()..qr['asset:legacy'] = 'actual-doc';
    final result = await StudentQrAssetResolver(lookup)
        .resolve(' asset:legacy ');
    expect(result.status, StudentQrResolutionStatus.found);
    expect(result.assetId, 'actual-doc');
    expect(lookup.calls, ['qr:asset:legacy']);
  });

  test('asset:<id> falls back to existing document only', () async {
    final lookup = _Lookup()..ids.add('asset-doc-1');
    final resolver = StudentQrAssetResolver(lookup);
    final found = await resolver.resolve('asset:asset-doc-1');
    final missing = await resolver.resolve('asset:missing');
    expect(found.assetId, 'asset-doc-1');
    expect(missing.status, StudentQrResolutionStatus.notFound);
  });

  test('manual code fallback normalizes code and resolves document', () async {
    final lookup = _Lookup()..code['IOT-ESP-001'] = 'esp-doc';
    final result = await StudentQrAssetResolver(lookup)
        .resolve('iot-esp-001', manual: true);
    expect(result.assetId, 'esp-doc');
    expect(lookup.calls.last, 'code:IOT-ESP-001');
  });

  test('invalid and empty payloads never supply navigation paths', () async {
    final lookup = _Lookup();
    final resolver = StudentQrAssetResolver(lookup);
    expect(
      (await resolver.resolve('')).status,
      StudentQrResolutionStatus.invalid,
    );
    expect(lookup.calls, isEmpty);
    expect(
      (await resolver.resolve('https://example.invalid/admin')).status,
      StudentQrResolutionStatus.invalid,
    );
    expect(
      StudentQrAssetResolver.documentIdFromCanonicalQr('asset:../admin'),
      isNull,
    );
  });
}
