import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:labflow/features/student/data/student_service.dart';
import 'package:labflow/features/student/domain/student_models.dart';
import 'package:labflow/features/student/presentation/cubit/student_catalog_cubit.dart';
import 'package:labflow/features/student/presentation/pages/student_equipment_page.dart';

class _FakeStudentService implements StudentService {
  _FakeStudentService({
    required this.assets,
    required this.laboratories,
  });

  final List<StudentAsset> assets;
  final List<StudentLaboratory> laboratories;
  int loadAssetsCalls = 0;

  @override
  Future<List<StudentAsset>> loadAssets() async {
    loadAssetsCalls += 1;
    return assets;
  }

  @override
  Future<List<StudentLaboratory>> loadActiveLaboratories() async {
    return laboratories;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _testLabs = [
  StudentLaboratory(
    id: 'lab-1',
    code: 'BIO-01',
    name: 'Lab Biologi',
    location: 'Gedung A',
  ),
  StudentLaboratory(
    id: 'lab-2',
    code: 'FIS-02',
    name: 'Lab Fisika',
    location: 'Gedung B',
  ),
];

const _testAssets = [
  StudentAsset(
    id: 'asset-1',
    labId: 'lab-1',
    code: 'MKT-R01',
    name: 'Mikroskop Trinokuler Digital',
    category: 'Optik',
    description: 'Mikroskop laboratorium untuk praktikum.',
    location: 'Rak A1',
    stock: 2,
    status: 'available',
    condition: 'good',
    qrValue: 'MKT-R01',
  ),
  StudentAsset(
    id: 'asset-2',
    labId: 'lab-2',
    code: 'OSC-02',
    name: 'Osiloskop Digital 100MHz',
    category: 'Elektronik',
    description: 'Osiloskop dual channel.',
    location: 'Meja B3',
    stock: 1,
    status: 'borrowed',
    condition: 'good',
    qrValue: 'OSC-02',
  ),
  StudentAsset(
    id: 'asset-3',
    labId: 'lab-1',
    code: 'CTR-03',
    name: 'Centrifuge Mini',
    category: 'Kimia',
    description: 'Centrifuge meja lab.',
    location: 'Rak C2',
    stock: 1,
    status: 'maintenance',
    condition: 'fair',
    qrValue: 'CTR-03',
  ),
];

Widget _buildRouterApp({
  required _FakeStudentService service,
  StudentCatalogCubit? cubit,
  required List<String> visitedRoutes,
  double textScale = 1.0,
}) {
  final router = GoRouter(
    initialLocation: '/student/assets',
    routes: [
      GoRoute(
        path: '/student',
        builder: (context, state) => const Scaffold(body: Text('Beranda')),
      ),
      GoRoute(
        path: '/student/assets',
        builder: (context, state) => StudentEquipmentPage(
          service: service,
          cubit: cubit,
        ),
      ),
      GoRoute(
        path: '/student/assets/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          visitedRoutes.add('/student/assets/$id');
          return Scaffold(
            appBar: AppBar(title: Text('Detail $id')),
            body: Text('Asset Detail: $id'),
          );
        },
      ),
      GoRoute(
        path: '/student/scanner',
        builder: (context, state) {
          visitedRoutes.add('/student/scanner');
          return Scaffold(
            appBar: AppBar(title: const Text('Scanner')),
            body: const Text('QR Scanner Screen'),
          );
        },
      ),
      GoRoute(
        path: '/student/borrowing',
        builder: (context, state) => const Scaffold(body: Text('Pinjam')),
      ),
      GoRoute(
        path: '/student/reports',
        builder: (context, state) => const Scaffold(body: Text('Laporan')),
      ),
      GoRoute(
        path: '/student/profile',
        builder: (context, state) => const Scaffold(body: Text('Profil')),
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
  testWidgets('Test 1 & 2: Input kode and Scan QR appear in both Grid and List views', (
    tester,
  ) async {
    final service = _FakeStudentService(
      assets: _testAssets,
      laboratories: _testLabs,
    );
    final visited = <String>[];

    await tester.pumpWidget(
      _buildRouterApp(service: service, visitedRoutes: visited),
    );
    await tester.pumpAndSettle();

    // Default mode is Grid view.
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

    // Switch to List view.
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsNothing);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
    expect(find.text('Mikroskop Trinokuler Digital'), findsOneWidget);
  });

  testWidgets('Test 3: Grid -> List -> Grid switching preserves both action buttons without duplication', (
    tester,
  ) async {
    final service = _FakeStudentService(
      assets: _testAssets,
      laboratories: _testLabs,
    );
    final visited = <String>[];

    await tester.pumpWidget(
      _buildRouterApp(service: service, visitedRoutes: visited),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

    // Grid -> List
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsNothing);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

    // List -> Grid
    await tester.tap(find.byTooltip('Tampilan grid'));
    await tester.pumpAndSettle();
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);
  });

  testWidgets('Test 4: Input kode opens sheet and handles valid & invalid codes in Grid and List', (
    tester,
  ) async {
    final service = _FakeStudentService(
      assets: _testAssets,
      laboratories: _testLabs,
    );
    final visited = <String>[];

    await tester.pumpWidget(
      _buildRouterApp(service: service, visitedRoutes: visited),
    );
    await tester.pumpAndSettle();

    // Grid mode: valid code (case-insensitive) navigates to asset detail.
    await tester.tap(find.text('Input kode'));
    await tester.pumpAndSettle();
    expect(find.text('Masukkan Kode Aset'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Kode Aset'),
      'mkt-r01',
    );
    await tester.tap(find.text('Cari Aset'));
    await tester.pumpAndSettle();

    expect(visited, ['/student/assets/asset-1']);
    expect(find.text('Asset Detail: asset-1'), findsOneWidget);

    // Pop back to catalog and switch to List mode.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();

    // List mode: invalid code shows notification and does not navigate.
    await tester.tap(find.text('Input kode'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Kode Aset'),
      'TIDAK-ADA-99',
    );
    await tester.tap(find.text('Cari Aset'));
    await tester.pumpAndSettle();

    expect(visited, ['/student/assets/asset-1']);
    expect(find.text('Kode aset tidak ditemukan.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('Test 5: Scan QR navigates cleanly to /student/scanner from both Grid and List views', (
    tester,
  ) async {
    final service = _FakeStudentService(
      assets: _testAssets,
      laboratories: _testLabs,
    );
    final visited = <String>[];

    await tester.pumpWidget(
      _buildRouterApp(service: service, visitedRoutes: visited),
    );
    await tester.pumpAndSettle();

    // Grid mode -> Scan QR
    await tester.tap(find.text('Scan QR'));
    await tester.pumpAndSettle();
    expect(visited, ['/student/scanner']);
    expect(find.text('QR Scanner Screen'), findsOneWidget);

    // Back -> switch to List mode -> Scan QR
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Scan QR'));
    await tester.pumpAndSettle();
    expect(visited, ['/student/scanner', '/student/scanner']);
  });

  testWidgets('Test 6: Search and filter state persist across Grid <-> List switches without reload', (
    tester,
  ) async {
    final service = _FakeStudentService(
      assets: _testAssets,
      laboratories: _testLabs,
    );
    final cubit = StudentCatalogCubit(service);
    await cubit.load();
    addTearDown(cubit.close);

    final visited = <String>[];
    await tester.pumpWidget(
      _buildRouterApp(service: service, cubit: cubit, visitedRoutes: visited),
    );
    await tester.pumpAndSettle();
    expect(service.loadAssetsCalls, 1);

    // Enter query + availability + lab filter.
    await tester.enterText(
      find.widgetWithText(TextField, 'Cari peralatan...'),
      'Mikroskop',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tersedia').first);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Laboratorium'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lab Biologi').last);
    await tester.pumpAndSettle();

    expect(cubit.state.query, 'Mikroskop');
    expect(cubit.state.labId, 'lab-1');
    expect(find.text('1 peralatan · Lab Biologi'), findsOneWidget);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

    // Toggle Grid -> List -> Grid and verify state preserved without reload.
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();
    expect(cubit.state.query, 'Mikroskop');
    expect(cubit.state.labId, 'lab-1');
    expect(find.text('1 peralatan · Lab Biologi'), findsOneWidget);
    expect(find.text('Mikroskop Trinokuler Digital'), findsOneWidget);
    expect(find.text('Input kode'), findsOneWidget);
    expect(find.text('Scan QR'), findsOneWidget);

    await tester.tap(find.byTooltip('Tampilan grid'));
    await tester.pumpAndSettle();
    expect(cubit.state.query, 'Mikroskop');
    expect(cubit.state.labId, 'lab-1');
    expect(find.text('1 peralatan · Lab Biologi'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(service.loadAssetsCalls, 1);
  });

  testWidgets('Test 7: Responsive layout across small/medium/large viewports and text scaling', (
    tester,
  ) async {
    final viewports = [
      const Size(360, 640),
      const Size(360, 800),
      const Size(393, 873),
      const Size(412, 915),
    ];

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    for (final size in viewports) {
      for (final scale in [1.0, 1.3]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        final service = _FakeStudentService(
          assets: _testAssets,
          laboratories: _testLabs,
        );
        final visited = <String>[];

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          _buildRouterApp(
            service: service,
            visitedRoutes: visited,
            textScale: scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Grid overflow at $size scale $scale',
        );
        expect(find.text('Input kode'), findsOneWidget);
        expect(find.text('Scan QR'), findsOneWidget);

        await tester.tap(find.byTooltip('Tampilan daftar'));
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'List overflow at $size scale $scale',
        );
        expect(find.text('Input kode'), findsOneWidget);
        expect(find.text('Scan QR'), findsOneWidget);
      }
    }
  });

  testWidgets('Test 8: Existing card tap navigation works in both Grid and List views', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final service = _FakeStudentService(
      assets: _testAssets,
      laboratories: _testLabs,
    );
    final visited = <String>[];

    await tester.pumpWidget(
      _buildRouterApp(service: service, visitedRoutes: visited),
    );
    await tester.pumpAndSettle();

    // Grid card tap
    await tester.tap(find.text('Mikroskop Trinokuler Digital'));
    await tester.pumpAndSettle();
    expect(visited, ['/student/assets/asset-1']);

    // Back -> List card tap
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Tampilan daftar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Osiloskop Digital 100MHz'));
    await tester.pumpAndSettle();
    expect(visited, ['/student/assets/asset-1', '/student/assets/asset-2']);
  });
}
