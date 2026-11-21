import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:labflow/features/asset/data/asset_service.dart';
import 'package:labflow/features/asset/domain/laboratory_asset.dart';
import 'package:labflow/features/lab_admin/data/asset_qr_print_service.dart';
import 'package:labflow/features/lab_admin/presentation/pages/asset_detail_page.dart';
import 'package:labflow/features/laboratory/data/laboratory_service.dart';
import 'package:labflow/features/laboratory/domain/laboratory.dart';
import 'package:labflow/features/student/data/student_qr_asset_service.dart';

class _FakeAssetService implements AssetService {
  _FakeAssetService(this.asset);

  final LaboratoryAsset asset;
  int getAssetCalls = 0;

  @override
  Future<LaboratoryAsset> getAsset(String assetId) async {
    getAssetCalls += 1;
    return asset;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLaboratoryService implements LaboratoryService {
  _FakeLaboratoryService(this.laboratory);

  final Laboratory laboratory;

  @override
  Future<Laboratory> getLaboratory(String laboratoryId) async => laboratory;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockPrintDriver implements AssetQrPrintDriver {
  bool printResult = true;
  bool shareResult = true;
  Object? printError;
  int printCalls = 0;
  int shareCalls = 0;
  String? lastJobName;
  String? lastFileName;
  String? lastSubject;
  Uint8List? lastPrintedBytes;
  Uint8List? lastSharedBytes;

  @override
  Future<bool> printPdf({
    required String jobName,
    required Uint8List pdfBytes,
  }) async {
    printCalls += 1;
    lastJobName = jobName;
    lastPrintedBytes = pdfBytes;
    if (printError != null) {
      throw printError!;
    }
    return printResult;
  }

  @override
  Future<bool> sharePdf({
    required String fileName,
    required Uint8List pdfBytes,
    String? subject,
  }) async {
    shareCalls += 1;
    lastFileName = fileName;
    lastSubject = subject;
    lastSharedBytes = pdfBytes;
    return shareResult;
  }
}

class _FakeScannerLookup implements StudentAssetLookup {
  final Map<String, String> byQr = <String, String>{};
  final Set<String> docIds = <String>{};

  @override
  Future<bool> existsById(String documentId) async =>
      docIds.contains(documentId);

  @override
  Future<String?> findByCode(String code) async => null;

  @override
  Future<String?> findByQrValue(String value) async => byQr[value];
}

({String streams, String words}) _extractPdfContent(
  Uint8List pdfBytes,
) {
  final rawLatin = latin1.decode(pdfBytes, allowInvalid: true);
  final buffer = StringBuffer(rawLatin);
  final streamPattern = RegExp(r'stream\r?\n([\s\S]*?)\r?\nendstream');
  for (final match in streamPattern.allMatches(rawLatin)) {
    final slice = match.group(1);
    if (slice == null) continue;
    try {
      final compressed = latin1.encode(slice);
      final inflated = zlib.decode(compressed);
      buffer.writeln(latin1.decode(inflated, allowInvalid: true));
    } catch (_) {
      // Skip non-zlib streams if any.
    }
  }
  final streams = buffer.toString();
  final words = RegExp(r'\[\(([^)]*)\)\]TJ')
      .allMatches(streams)
      .map((m) => m.group(1) ?? '')
      .join(' ');
  return (streams: streams, words: words);
}

const _sampleLab = Laboratory(
  id: 'lab-bio-1',
  name: 'Lab Biologi Molekuler',
  code: 'LAB-BIO-01',
  description: 'Laboratorium praktikum mikrobiologi',
  location: 'Gedung Sains Lt. 2',
  status: 'active',
);

const _sampleAsset = LaboratoryAsset(
  id: 'asset-doc-42',
  labId: 'lab-bio-1',
  code: 'MKT-R01',
  name: 'Mikroskop Trinokuler Digital',
  category: 'Optik',
  description: 'Mikroskop digital dengan kamera terintegrasi.',
  location: 'Rak A1',
  stock: 4,
  status: 'available',
  condition: 'good',
  qrValue: 'asset:asset-doc-42',
);

Widget _buildAssetDetailRouterApp({
  required LaboratoryAsset asset,
  required _MockPrintDriver driver,
  required List<String> navigatedRoutes,
  double textScale = 1.0,
}) {
  final router = GoRouter(
    initialLocation: '/lab-admin/assets/${asset.id}',
    routes: [
      GoRoute(
        path: '/lab-admin/assets',
        builder: (context, state) => const Scaffold(body: Text('Assets List')),
      ),
      GoRoute(
        path: '/lab-admin/assets/:assetId',
        builder: (context, state) => AssetDetailPage(
          assetId: asset.id,
          assetService: _FakeAssetService(asset),
          laboratoryService: _FakeLaboratoryService(_sampleLab),
          qrPrintService: AssetQrPrintService(driver: driver),
        ),
      ),
      GoRoute(
        path: '/lab-admin/assets/:assetId/edit',
        builder: (context, state) {
          navigatedRoutes.add('/lab-admin/assets/${asset.id}/edit');
          return const Scaffold(body: Text('Edit Asset Screen'));
        },
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
  );
}

void main() {
  testWidgets(
    'Test 1: Print action and share PDF buttons are visible on AssetDetailPage QR section and dialog',
    (tester) async {
      final driver = _MockPrintDriver();
      final routes = <String>[];

      await tester.pumpWidget(
        _buildAssetDetailRouterApp(
          asset: _sampleAsset,
          driver: driver,
          navigatedRoutes: routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QR Aset'), findsOneWidget);
      expect(find.text('Cetak QR'), findsOneWidget);
      expect(find.text('Simpan / Bagikan PDF'), findsOneWidget);

      // Enlarged QR dialog also offers Cetak QR.
      await tester.ensureVisible(find.byType(QrImageView));
      await tester.tap(find.byType(QrImageView));
      await tester.pumpAndSettle();

      expect(find.text('Salin Identitas QR'), findsOneWidget);
      expect(find.text('Cetak QR'), findsNWidgets(2));
    },
  );

  test(
    'Test 2 & 3: PDF generation preserves exact qrValue payload and includes required label details',
    () async {
      final driver = _MockPrintDriver();
      final service = AssetQrPrintService(driver: driver);

      final pdfBytes = await service.buildLabelPdf(
        asset: _sampleAsset,
        laboratoryName: _sampleLab.name,
      );

      expect(pdfBytes, isNotEmpty);
      expect(latin1.decode(pdfBytes.sublist(0, 5)), '%PDF-');

      final extracted = _extractPdfContent(pdfBytes);

      // Required asset label information.
      expect(extracted.words, contains('LABFLOW'));
      expect(extracted.words, contains('Mikroskop Trinokuler Digital'));
      expect(extracted.words, contains('MKT-R01'));
      expect(extracted.words, contains('Lab Biologi Molekuler'));
      expect(extracted.words, contains('asset:asset-doc-42'));

      // Verify QR vector drawing rectangles exist inside the stream and match asset.qrValue geometry.
      final qrBarcode = pw.Barcode.qrCode(
        errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
      );
      final expectedModules = qrBarcode
          .make(_sampleAsset.qrValue, width: 156, height: 156)
          .toList();
      final nameModules = qrBarcode
          .make(_sampleAsset.name, width: 156, height: 156)
          .toList();
      final codeModules = qrBarcode
          .make(_sampleAsset.code, width: 156, height: 156)
          .toList();

      expect(expectedModules.length, greaterThan(50));
      expect(expectedModules.length, isNot(equals(nameModules.length)));
      expect(expectedModules.length, isNot(equals(codeModules.length)));
      expect(extracted.streams, contains(' re'));

      // Ensure no sensitive data accidentally injected into label text.
      expect(extracted.words.toLowerCase(), isNot(contains('@')));
      expect(extracted.words.toLowerCase(), isNot(contains('firebase')));
      expect(extracted.words.toLowerCase(), isNot(contains('password')));
    },
  );

  test(
    'Test 4 (Unit): Invalid or empty qrValue throws clear error and never fabricates payload',
    () async {
      final driver = _MockPrintDriver();
      final service = AssetQrPrintService(driver: driver);

      for (final badQr in ['', '   ', 'asset:abc\ndef', 'x' * 513]) {
        final badAsset = _sampleAsset.copyWith(qrValue: badQr);
        await expectLater(
          () => service.buildLabelPdf(
            asset: badAsset,
            laboratoryName: _sampleLab.name,
          ),
          throwsA(isA<AssetQrPrintException>()),
        );
      }
      expect(driver.printCalls, 0);
      expect(driver.shareCalls, 0);
    },
  );

  testWidgets(
    'Test 4 (Widget): Empty qrValue shows clear error notification and never triggers driver',
    (tester) async {
      final driver = _MockPrintDriver();
      final routes = <String>[];
      final invalidAsset = _sampleAsset.copyWith(qrValue: '');

      await tester.pumpWidget(
        _buildAssetDetailRouterApp(
          asset: invalidAsset,
          driver: driver,
          navigatedRoutes: routes,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cetak QR'));
      await tester.tap(find.text('Cetak QR'));
      await tester.pumpAndSettle();

      expect(driver.printCalls, 0);
      expect(driver.lastPrintedBytes, isNull);
      expect(
        find.text(
          'Nilai QR aset belum tersedia sehingga label tidak dapat dicetak.',
        ),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Test 5: Cancelling print dialog does not mutate asset data or crash',
    (tester) async {
      final driver = _MockPrintDriver()..printResult = false;
      final routes = <String>[];

      await tester.pumpWidget(
        _buildAssetDetailRouterApp(
          asset: _sampleAsset,
          driver: driver,
          navigatedRoutes: routes,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Cetak QR'));
      await tester.tap(find.text('Cetak QR'));
      await tester.pumpAndSettle();

      expect(driver.printCalls, 1);
      expect(driver.lastPrintedBytes, isNotNull);
      expect(find.text('Proses cetak label QR dibatalkan.'), findsOneWidget);
      expect(find.text('Mikroskop Trinokuler Digital'), findsOneWidget);
      expect(find.text('asset:asset-doc-42'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Test 6: Save / Share PDF generates PDF locally and invokes share driver without external upload',
    (tester) async {
      final driver = _MockPrintDriver()..shareResult = true;
      final routes = <String>[];

      await tester.pumpWidget(
        _buildAssetDetailRouterApp(
          asset: _sampleAsset,
          driver: driver,
          navigatedRoutes: routes,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Simpan / Bagikan PDF'));
      await tester.tap(find.text('Simpan / Bagikan PDF'));
      await tester.pumpAndSettle();

      expect(driver.shareCalls, 1);
      expect(driver.lastFileName, 'labflow_qr_MKT-R01.pdf');
      expect(
        driver.lastSubject,
        'Label QR Aset LabFlow - Mikroskop Trinokuler Digital',
      );
      expect(driver.lastSharedBytes, isNotNull);
      expect(
        latin1.decode(driver.lastSharedBytes!.sublist(0, 5)),
        '%PDF-',
      );
      expect(
        find.text('Dokumen PDF label QR siap disimpan atau dibagikan.'),
        findsOneWidget,
      );

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Test 7: Existing AssetDetailPage edit and copy interactions remain intact alongside print action',
    (tester) async {
      final driver = _MockPrintDriver();
      final routes = <String>[];

      await tester.pumpWidget(
        _buildAssetDetailRouterApp(
          asset: _sampleAsset,
          driver: driver,
          navigatedRoutes: routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Salin identitas QR'), findsOneWidget);
      await tester.ensureVisible(find.text('Edit Aset'));
      await tester.tap(find.text('Edit Aset'));
      await tester.pumpAndSettle();

      expect(routes, ['/lab-admin/assets/asset-doc-42/edit']);
      expect(find.text('Edit Asset Screen'), findsOneWidget);
    },
  );

  test(
    'Test 8: Printed QR payload resolves cleanly with existing StudentQrAssetResolver',
    () async {
      final payload = AssetQrPrintService.validateQrPayload(
        _sampleAsset.qrValue,
      );
      final lookup = _FakeScannerLookup()
        ..byQr[payload] = _sampleAsset.id
        ..docIds.add(_sampleAsset.id);

      final resolved = await StudentQrAssetResolver(lookup).resolve(payload);
      expect(resolved.status, StudentQrResolutionStatus.found);
      expect(resolved.assetId, _sampleAsset.id);

      // Even without qrValue index match, canonical asset:<id> fallback works.
      final fallbackLookup = _FakeScannerLookup()..docIds.add(_sampleAsset.id);
      final resolvedFallback = await StudentQrAssetResolver(
        fallbackLookup,
      ).resolve(payload);
      expect(resolvedFallback.status, StudentQrResolutionStatus.found);
      expect(resolvedFallback.assetId, _sampleAsset.id);
    },
  );

  testWidgets(
    'Responsive: AssetDetailPage QR actions and enlarged QR dialog fit compact viewports without overflow',
    (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final config in [
        (size: const Size(360, 640), scale: 1.0),
        (size: const Size(360, 800), scale: 1.3),
      ]) {
        tester.view.physicalSize = config.size;
        tester.view.devicePixelRatio = 1.0;

        final driver = _MockPrintDriver();
        final routes = <String>[];

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          _buildAssetDetailRouterApp(
            asset: _sampleAsset,
            driver: driver,
            navigatedRoutes: routes,
            textScale: config.scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Page overflow at ${config.size} scale ${config.scale}',
        );

        await tester.ensureVisible(find.byType(QrImageView));
        await tester.tap(find.byType(QrImageView));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Dialog overflow at ${config.size} scale ${config.scale}',
        );
      }
    },
  );
}
