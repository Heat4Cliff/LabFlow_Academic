import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:labflow/core/connectivity/connectivity_service.dart';
import 'package:labflow/features/asset/data/asset_image_service.dart';
import 'package:labflow/features/reporting/data/report_conversation_service.dart';
import 'package:labflow/features/reporting/data/report_service.dart';
import 'package:labflow/features/reporting/domain/lab_report.dart';
import 'package:labflow/features/reporting/domain/report_message.dart';
import 'package:labflow/features/reporting/presentation/cubit/report_conversation_cubit.dart';
import 'package:labflow/features/reporting/presentation/cubit/report_detail_cubit.dart';
import 'package:labflow/features/reporting/presentation/pages/admin_report_detail_page.dart';
import 'package:labflow/features/student/data/student_report_service.dart';
import 'package:labflow/features/student/presentation/cubit/student_report_detail_cubit.dart';
import 'package:labflow/features/student/presentation/pages/student_report_detail_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_firestore.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

class _MockAssetImageService extends Mock implements AssetImageService {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

LabReport _sampleReport() => LabReport(
  id: 'rep-1',
  reportNumber: 'RPT-2026-001',
  reporterId: 'student-1',
  reporterName: 'Budi Santoso',
  labId: 'lab-1',
  assetId: 'asset-1',
  assetName: 'Oscilloscope Rigol DS1054Z',
  assetCode: 'OSC-001',
  category: 'damage',
  title: 'Layar Oscilloscope Berkedip Saat Pengukuran Tegangan Tinggi',
  description:
      'Ketika digunakan untuk praktikum elektronika daya, layar terkadang berkedip dan menampilkan noise pada kanal 2. Sudah dicoba menggunakan probe cadangan namun hasilnya tetap sama.',
  location: 'Lab Elektronika Gedung C Lantai 2',
  severity: 'normal',
  priority: 'medium',
  status: 'in_progress',
  assignedTo: 'admin-1',
  adminResponse: 'Sedang dilakukan pengecekan modul power supply.',
  createdAt: DateTime(2026, 11, 10, 9, 0),
  acknowledgedAt: DateTime(2026, 11, 10, 10, 0),
  resolvedAt: null,
  closedAt: null,
  updatedAt: DateTime(2026, 11, 10, 10, 30),
);

class _FakeStudentReportService extends StudentReportService {
  _FakeStudentReportService(this._report)
    : super(firestore: FakeMemoryFirestore(), auth: _MockFirebaseAuth());

  final LabReport _report;

  @override
  Stream<LabReport> watchOwnReport(String reportId) => Stream.value(_report);

  @override
  Future<String> loadLaboratoryName(String labId) async =>
      'Laboratorium Elektronika & Instrumentasi';
}

class _FakeReportService extends ReportService {
  _FakeReportService(this._report)
    : super(
        firestore: FakeMemoryFirestore(),
        firebaseAuth: _MockFirebaseAuth(),
      );

  final LabReport _report;

  @override
  Future<LabReport> getReport(String reportId) async => _report;
}

class _FakeConversationService extends ReportConversationService {
  _FakeConversationService({
    required this.fakeFirestore,
    required FirebaseAuth auth,
    required AssetImageService images,
    required ConnectivityService connectivity,
    List<ReportMessage> initialMessages = const <ReportMessage>[],
  }) : _messages = List<ReportMessage>.from(initialMessages),
       super(
         firestore: fakeFirestore,
         auth: auth,
         images: images,
         connectivity: connectivity,
       );

  final FakeMemoryFirestore fakeFirestore;
  final List<ReportMessage> _messages;
  final StreamController<List<ReportMessage>> _controller =
      StreamController<List<ReportMessage>>.broadcast();

  @override
  Stream<List<ReportMessage>> watchMessages(String reportId) =>
      Stream.multi((sink) {
        sink.add(List<ReportMessage>.unmodifiable(_messages));
        final sub = _controller.stream.listen(
          sink.add,
          onError: sink.addError,
          onDone: sink.close,
        );
        sink.onCancel = sub.cancel;
      });

  @override
  Future<void> send(String reportId, String text, {XFile? image}) async {
    await super.send(reportId, text, image: image);
    _messages.add(
      ReportMessage(
        id: 'msg-${_messages.length + 1}',
        senderId: 'student-1',
        senderRole: 'student',
        senderName: 'Budi Santoso',
        text: text.trim(),
        createdAt: DateTime(2026, 11, 21, 9, 45),
      ),
    );
    _controller.add(List<ReportMessage>.unmodifiable(_messages));
  }

  Future<void> dispose() => _controller.close();
}

Widget _buildRouterApp(
  Widget page, {
  double textScale = 1.0,
  void Function(GoRouter)? onCreated,
}) {
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(
        path: '/detail',
        builder: (_, _) => page,
      ),
      GoRoute(
        path: '/student/reports',
        builder: (_, _) => const Scaffold(body: Text('Reports List')),
      ),
      GoRoute(
        path: '/lab-admin/reports',
        builder: (_, _) => const Scaffold(body: Text('Admin Reports List')),
      ),
    ],
  );
  onCreated?.call(router);
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
  late FakeMemoryFirestore fakeFirestore;
  late _MockFirebaseAuth mockAuth;
  late _MockUser mockUser;
  late _MockAssetImageService mockImages;
  late _MockConnectivityService mockConnectivity;

  setUp(() {
    fakeFirestore = FakeMemoryFirestore();
    mockAuth = _MockFirebaseAuth();
    mockUser = _MockUser();
    mockImages = _MockAssetImageService();
    mockConnectivity = _MockConnectivityService();

    when(() => mockUser.uid).thenReturn('student-1');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(
      () => mockConnectivity.hasNetworkInterface(),
    ).thenAnswer((_) async => true);

    fakeFirestore.seedDoc('users', 'student-1', {
      'role': 'student',
      'status': 'active',
      'fullName': 'Budi Santoso',
    });
  });

  group('Bug #3 Report Detail Conversation Responsive Layout', () {
    for (final size in const [
      Size(360, 640),
      Size(360, 800),
      Size(393, 873),
      Size(412, 915),
    ]) {
      testWidgets(
        'Test 1 — Initial Layout ($size): composer terlihat utuh di bawah tanpa scroll manual dan aman dari system nav inset',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          // Simulasikan system navigation bar (3-button nav = 48px)
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 48);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPadding);

          final convService = _FakeConversationService(
            fakeFirestore: fakeFirestore,
            auth: mockAuth,
            images: mockImages,
            connectivity: mockConnectivity,
          );
          final detailCubit = StudentReportDetailCubit(
            _FakeStudentReportService(_sampleReport()),
          )..watch('rep-1');
          final convCubit = ReportConversationCubit(convService, auth: mockAuth)
            ..watch('rep-1');
          GoRouter? router;
          addTearDown(() async {
            router?.dispose();
            await detailCubit.close();
            await convCubit.close();
            await convService.dispose();
          });

          await tester.pumpWidget(
            _buildRouterApp(
              StudentReportDetailPage(
                reportId: 'rep-1',
                cubit: detailCubit,
                conversationCubit: convCubit,
              ),
              onCreated: (r) => router = r,
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Viewport $size');

          final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
          expect(inputFinder, findsOneWidget);

          final inputRect = tester.getRect(inputFinder);
          // Composer harus langsung terlihat di layar tanpa scroll manual
          expect(inputRect.top, greaterThan(0));
          // Tidak boleh terpotong oleh bawah layar maupun system nav bar (48px)
          expect(inputRect.bottom, lessThanOrEqualTo(size.height - 48));
        },
      );
    }

    testWidgets(
      'Test 2 — Keyboard Visibility: composer bergeser ke atas keyboard dan menerima input',
      (tester) async {
        const size = Size(393, 873);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewInsets);

        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
        );
        final detailCubit = StudentReportDetailCubit(
          _FakeStudentReportService(_sampleReport()),
        )..watch('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          router?.dispose();
          await detailCubit.close();
          await convCubit.close();
          await convService.dispose();
        });

        await tester.pumpWidget(
          _buildRouterApp(
            StudentReportDetailPage(
              reportId: 'rep-1',
              cubit: detailCubit,
              conversationCubit: convCubit,
            ),
            onCreated: (r) => router = r,
          ),
        );
        await tester.pumpAndSettle();

        // Buka keyboard Android (300px)
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        final sendFinder = find.byIcon(Icons.send_rounded);
        expect(inputFinder, findsOneWidget);
        expect(sendFinder, findsOneWidget);

        final inputRect = tester.getRect(inputFinder);
        final sendRect = tester.getRect(sendFinder);
        // Composer & tombol kirim harus tepat di atas keyboard (<= 873 - 300 = 573)
        expect(inputRect.bottom, lessThanOrEqualTo(573));
        expect(sendRect.bottom, lessThanOrEqualTo(573));

        await tester.enterText(inputFinder, 'Halo admin, mohon bantuannya.');
        await tester.pumpAndSettle();
        expect(find.text('Halo admin, mohon bantuannya.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 3 — Long Conversation: riwayat banyak pesan dapat di-scroll dan composer tetap tersemat di bawah',
      (tester) async {
        const size = Size(360, 800);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final messages = List<ReportMessage>.generate(
          25,
          (i) => ReportMessage(
            id: 'm-$i',
            senderId: i.isEven ? 'student-1' : 'admin-1',
            senderRole: i.isEven ? 'student' : 'lab_admin',
            text: 'Pesan percakapan ke-${i + 1} untuk uji scroll panjang.',
            createdAt: DateTime(2026, 11, 21, 9, i % 60),
          ),
        );

        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: messages,
        );
        final detailCubit = StudentReportDetailCubit(
          _FakeStudentReportService(_sampleReport()),
        )..watch('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          router?.dispose();
          await detailCubit.close();
          await convCubit.close();
          await convService.dispose();
        });

        await tester.pumpWidget(
          _buildRouterApp(
            StudentReportDetailPage(
              reportId: 'rep-1',
              cubit: detailCubit,
              conversationCubit: convCubit,
            ),
            onCreated: (r) => router = r,
          ),
        );
        await tester.pumpAndSettle();

        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        final beforeRect = tester.getRect(inputFinder);

        // Scroll turun jauh hingga pesan terakhir muncul
        await tester.scrollUntilVisible(
          find.text('Pesan percakapan ke-25 untuk uji scroll panjang.'),
          400,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Pesan percakapan ke-25 untuk uji scroll panjang.'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        // Posisi composer tetap stabil di area bawah
        final afterRect = tester.getRect(inputFinder);
        expect(afterRect, equals(beforeRect));
      },
    );

    testWidgets(
      'Test 4 — Long Message: teks panjang menyesuaikan tinggi tanpa overflow pada layar kecil dan font scale besar',
      (tester) async {
        const size = Size(360, 640);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: 280);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
        );
        final detailCubit = StudentReportDetailCubit(
          _FakeStudentReportService(_sampleReport()),
        )..watch('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          router?.dispose();
          await detailCubit.close();
          await convCubit.close();
          await convService.dispose();
        });

        await tester.pumpWidget(
          _buildRouterApp(
            StudentReportDetailPage(
              reportId: 'rep-1',
              cubit: detailCubit,
              conversationCubit: convCubit,
            ),
            textScale: 1.3,
            onCreated: (r) => router = r,
          ),
        );
        await tester.pumpAndSettle();

        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        final longText = List.filled(
          12,
          'Kabel daya pada osiloskop terlihat mulai panas saat uji beban tinggi.',
        ).join(' ');

        await tester.enterText(inputFinder, longText);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final sendFinder = find.byIcon(Icons.send_rounded);
        final attachFinder = find.byTooltip('Lampirkan gambar');
        expect(sendFinder, findsOneWidget);
        expect(attachFinder, findsOneWidget);

        // Tombol kirim tetap berada di atas keyboard dan di dalam lebar layar
        final sendRect = tester.getRect(sendFinder);
        expect(sendRect.bottom, lessThanOrEqualTo(640 - 280));
        expect(sendRect.right, lessThanOrEqualTo(360));
      },
    );

    testWidgets(
      'Test 5 — Keyboard Dismiss: layout kembali normal setelah keyboard ditutup',
      (tester) async {
        const size = Size(393, 873);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewInsets);

        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
        );
        final detailCubit = StudentReportDetailCubit(
          _FakeStudentReportService(_sampleReport()),
        )..watch('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          router?.dispose();
          await detailCubit.close();
          await convCubit.close();
          await convService.dispose();
        });

        await tester.pumpWidget(
          _buildRouterApp(
            StudentReportDetailPage(
              reportId: 'rep-1',
              cubit: detailCubit,
              conversationCubit: convCubit,
            ),
            onCreated: (r) => router = r,
          ),
        );
        await tester.pumpAndSettle();

        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        final initialRect = tester.getRect(inputFinder);

        // Buka keyboard
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final openRect = tester.getRect(inputFinder);
        expect(openRect.bottom, lessThan(initialRect.bottom));

        // Tutup keyboard
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        final dismissedRect = tester.getRect(inputFinder);
        expect(dismissedRect, equals(initialRect));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 6a — Regression (Student): mengirim pesan menulis ke Firestore, mengosongkan input, dan menampilkan pesan terbaru',
      (tester) async {
        const size = Size(393, 873);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
        );
        final detailCubit = StudentReportDetailCubit(
          _FakeStudentReportService(_sampleReport()),
        )..watch('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          router?.dispose();
          await detailCubit.close();
          await convCubit.close();
          await convService.dispose();
        });

        await tester.pumpWidget(
          _buildRouterApp(
            StudentReportDetailPage(
              reportId: 'rep-1',
              cubit: detailCubit,
              conversationCubit: convCubit,
            ),
            onCreated: (r) => router = r,
          ),
        );
        await tester.pumpAndSettle();

        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        await tester.enterText(inputFinder, 'Sudah kami matikan sakelar utama.');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pumpAndSettle();

        final writes = fakeFirestore.writesFor('reports/rep-1/messages');
        expect(writes, hasLength(1));
        expect(writes.first.payload['text'], 'Sudah kami matikan sakelar utama.');
        expect(writes.first.payload['senderId'], 'student-1');

        // Pesan baru tampil di percakapan dan input kosong kembali
        expect(
          find.text('Sudah kami matikan sakelar utama.'),
          findsOneWidget,
        );
        final controller = tester.widget<TextField>(inputFinder).controller!;
        expect(controller.text, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Test 6b — Regression (Lab Admin): AdminReportDetailPage menampilkan composer utuh dan responsif dengan keyboard',
      (tester) async {
        const size = Size(393, 873);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        tester.view.padding = const FakeViewPadding(top: 24, bottom: 32);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.view.resetViewInsets);

        when(() => mockUser.uid).thenReturn('admin-1');
        fakeFirestore.seedDoc('users', 'admin-1', {
          'role': 'lab_admin',
          'status': 'active',
          'fullName': 'Teknisi Lab',
        });

        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
        );
        final adminCubit = ReportDetailCubit(
          _FakeReportService(_sampleReport()),
        );
        await adminCubit.load('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          router?.dispose();
          await adminCubit.close();
          await convCubit.close();
          await convService.dispose();
        });

        await tester.pumpWidget(
          _buildRouterApp(
            AdminReportDetailPage(
              reportId: 'rep-1',
              cubit: adminCubit,
              conversationCubit: convCubit,
            ),
            onCreated: (r) => router = r,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Composer langsung terlihat di bawah tanpa perlu scroll melewati seluruh card admin
        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        expect(inputFinder, findsOneWidget);
        final initialRect = tester.getRect(inputFinder);
        expect(initialRect.bottom, lessThanOrEqualTo(size.height - 32));

        // Keyboard muncul
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();

        final keyboardRect = tester.getRect(inputFinder);
        expect(keyboardRect.bottom, lessThanOrEqualTo(size.height - 300));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
