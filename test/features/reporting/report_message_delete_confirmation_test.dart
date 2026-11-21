import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
  assetName: 'Oscilloscope',
  assetCode: 'OSC-01',
  category: 'damage',
  title: 'Kabel Power Longgar',
  description: 'Kabel daya sering terlepas saat praktikum.',
  location: 'Lab Elektronika',
  severity: 'normal',
  priority: 'medium',
  status: 'in_progress',
  assignedTo: 'admin-1',
  adminResponse: null,
  createdAt: DateTime(2026, 11, 20, 9, 0),
  acknowledgedAt: DateTime(2026, 11, 20, 10, 0),
  resolvedAt: null,
  closedAt: null,
  updatedAt: DateTime(2026, 11, 20, 10, 0),
);

class _FakeStudentReportService extends StudentReportService {
  _FakeStudentReportService(this._report)
    : super(firestore: FakeMemoryFirestore(), auth: _MockFirebaseAuth());

  final LabReport _report;

  @override
  Stream<LabReport> watchOwnReport(String reportId) => Stream.value(_report);

  @override
  Future<String> loadLaboratoryName(String labId) async => 'Lab Elektronika';
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

  int softDeleteCallCount = 0;
  bool shouldFailDelete = false;
  Completer<void>? deleteCompleter;

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
  Future<void> softDelete(String reportId, String messageId) async {
    softDeleteCallCount++;
    if (deleteCompleter != null) {
      await deleteCompleter!.future;
    }
    if (shouldFailDelete) {
      throw Exception('Firestore permission denied or network error');
    }
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final old = _messages[index];
      _messages[index] = ReportMessage(
        id: old.id,
        senderId: old.senderId,
        senderRole: old.senderRole,
        senderName: old.senderName,
        text: old.text,
        type: old.type,
        imageUrl: old.imageUrl,
        imagePublicId: old.imagePublicId,
        createdAt: old.createdAt,
        deletedAt: DateTime(2026, 11, 21, 10, 40),
      );
      _controller.add(List<ReportMessage>.unmodifiable(_messages));
    }
  }

  Future<void> dispose() => _controller.close();
}

Widget _buildRouterApp(
  Widget page, {
  void Function(GoRouter)? onCreated,
}) {
  final router = GoRouter(
    initialLocation: '/detail',
    routes: [
      GoRoute(path: '/detail', builder: (_, _) => page),
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
  return MaterialApp.router(routerConfig: router);
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
  });

  group('Bug #4 Delete Message Confirmation Dialog', () {
    testWidgets(
      'Test 1 & Test 2 — Long press menampilkan dialog konfirmasi dan Batal membatalkan penghapusan',
      (tester) async {
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-1',
              senderId: 'student-1',
              senderRole: 'student',
              text: 'Pesan penting saya.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
          ],
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

        // Scroll agar bubble pesan tampil jelas
        await tester.scrollUntilVisible(
          find.text('Pesan penting saya.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Test 1: Long press pesan
        await tester.longPress(find.text('Pesan penting saya.'));
        await tester.pumpAndSettle();

        // Pastikan dialog konfirmasi tampil dan pesan belum terhapus
        expect(find.text('Hapus pesan?'), findsOneWidget);
        expect(
          find.text(
            'Apakah Anda yakin ingin menghapus pesan ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          findsOneWidget,
        );
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Hapus'), findsOneWidget);
        expect(convService.softDeleteCallCount, 0);
        expect(find.text('Pesan penting saya.'), findsOneWidget);

        // Test 2: Pilih Batal
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Hapus pesan?'), findsNothing);
        expect(find.text('Pesan penting saya.'), findsOneWidget);
        expect(convService.softDeleteCallCount, 0);
      },
    );

    testWidgets(
      'Test 3 — Confirm Delete: menekan Hapus menjalankan softDelete tepat satu kali dan memperbarui UI',
      (tester) async {
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-1',
              senderId: 'student-1',
              senderRole: 'student',
              text: 'Pesan yang akan dihapus.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
          ],
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

        await tester.scrollUntilVisible(
          find.text('Pesan yang akan dihapus.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Pesan yang akan dihapus.'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        expect(convService.softDeleteCallCount, 1);
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(find.text('Pesan yang akan dihapus.'), findsNothing);
        expect(find.text('Pesan telah dihapus'), findsOneWidget);
        expect(find.text('Pesan berhasil dihapus.'), findsOneWidget);

        // Pastikan overlay notification bersih sebelum teardown
        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'Test 4 — Android Back & Outside Tap: menutup dialog tanpa menghapus pesan',
      (tester) async {
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-1',
              senderId: 'student-1',
              senderRole: 'student',
              text: 'Pesan tetap aman.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
          ],
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

        await tester.scrollUntilVisible(
          find.text('Pesan tetap aman.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Bagian 1: Tutup dengan Android Back
        await tester.longPress(find.text('Pesan tetap aman.'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(convService.softDeleteCallCount, 0);
        expect(find.text('Pesan tetap aman.'), findsOneWidget);

        // Bagian 2: Tutup dengan mengetuk area luar dialog (barrier)
        await tester.longPress(find.text('Pesan tetap aman.'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsOneWidget);

        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(convService.softDeleteCallCount, 0);
        expect(find.text('Pesan tetap aman.'), findsOneWidget);
      },
    );

    testWidgets(
      'Test 5 — Delete Failure: gagal hapus tidak menghilangkan pesan dan menampilkan error informatif',
      (tester) async {
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-1',
              senderId: 'student-1',
              senderRole: 'student',
              text: 'Pesan gagal hapus.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
          ],
        )..shouldFailDelete = true;

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

        await tester.scrollUntilVisible(
          find.text('Pesan gagal hapus.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Pesan gagal hapus.'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        // Pesan tetap tampil di UI dan error notification ditampilkan
        expect(convService.softDeleteCallCount, 1);
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(find.text('Pesan gagal hapus.'), findsOneWidget);
        expect(find.text('Pesan telah dihapus'), findsNothing);
        expect(find.text('Pesan tidak dapat dihapus.'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'Test 6 — Double Tap Protection: tap berkali-kali saat loading hanya memanggil delete satu kali',
      (tester) async {
        final completer = Completer<void>();
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-1',
              senderId: 'student-1',
              senderRole: 'student',
              text: 'Pesan uji double tap.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
          ],
        )..deleteCompleter = completer;

        final detailCubit = StudentReportDetailCubit(
          _FakeStudentReportService(_sampleReport()),
        )..watch('rep-1');
        final convCubit = ReportConversationCubit(convService, auth: mockAuth)
          ..watch('rep-1');
        GoRouter? router;
        addTearDown(() async {
          if (!completer.isCompleted) completer.complete();
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

        await tester.scrollUntilVisible(
          find.text('Pesan uji double tap.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Pesan uji double tap.'));
        await tester.pumpAndSettle();

        final deleteBtn = find.widgetWithText(FilledButton, 'Hapus');
        expect(deleteBtn, findsOneWidget);

        // Tap Hapus pertama kali
        await tester.tap(deleteBtn);
        await tester.pump();

        // Dialog masih terbuka dalam state loading; tombol kini disabled dan menampilkan spinner
        expect(find.text('Hapus pesan?'), findsOneWidget);
        final filledWidget = tester.widget<FilledButton>(
          find.byType(FilledButton).last,
        );
        expect(filledWidget.onPressed, isNull);

        // Tap berulang saat loading berlangsung
        await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
        await tester.tap(find.byType(FilledButton).last, warnIfMissed: false);
        await tester.pump();

        // Uji juga pemanggilan paralel di level Cubit
        unawaited(convCubit.delete('msg-1'));
        expect(convService.softDeleteCallCount, 1);

        // Selesaikan proses delete
        completer.complete();
        await tester.pumpAndSettle();

        expect(convService.softDeleteCallCount, 1);
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(find.text('Pesan telah dihapus'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'Test 7 — Authorization Regression: pesan milik orang lain dan pesan terhapus tidak memicu dialog hapus',
      (tester) async {
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-other',
              senderId: 'admin-1',
              senderRole: 'lab_admin',
              text: 'Pesan dari Lab Admin.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
            ReportMessage(
              id: 'msg-deleted',
              senderId: 'student-1',
              senderRole: 'student',
              text: 'Sudah terhapus.',
              createdAt: DateTime(2026, 11, 21, 10, 5),
              deletedAt: DateTime(2026, 11, 21, 10, 6),
            ),
          ],
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

        await tester.scrollUntilVisible(
          find.text('Pesan telah dihapus'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        // Long press pesan milik Lab Admin saat login sebagai Student
        await tester.longPress(find.text('Pesan dari Lab Admin.'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(convService.softDeleteCallCount, 0);

        // Long press pesan yang sudah berstatus terhapus
        await tester.longPress(find.text('Pesan telah dihapus'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsNothing);
        expect(convService.softDeleteCallCount, 0);
      },
    );

    testWidgets(
      'Test 8 — Conversation & Bug #3 Regression pada AdminReportDetailPage: konfirmasi hapus, keyboard, dan composer pinned bekerja harmonis',
      (tester) async {
        const size = Size(393, 873);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        when(() => mockUser.uid).thenReturn('admin-1');
        final convService = _FakeConversationService(
          fakeFirestore: fakeFirestore,
          auth: mockAuth,
          images: mockImages,
          connectivity: mockConnectivity,
          initialMessages: [
            ReportMessage(
              id: 'msg-admin',
              senderId: 'admin-1',
              senderRole: 'lab_admin',
              text: 'Kami cek dulu unit cadangan.',
              createdAt: DateTime(2026, 11, 21, 10, 0),
            ),
          ],
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

        // Composer Bug #3 langsung terlihat di bawah
        final inputFinder = find.widgetWithText(TextField, 'Tulis pesan...');
        expect(inputFinder, findsOneWidget);
        expect(tester.getRect(inputFinder).bottom, lessThanOrEqualTo(873));

        // Keyboard Bug #3 bekerja
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.getRect(inputFinder).bottom, lessThanOrEqualTo(573));
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();

        // Long press pesan admin untuk konfirmasi hapus
        await tester.scrollUntilVisible(
          find.text('Kami cek dulu unit cadangan.'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        await tester.longPress(find.text('Kami cek dulu unit cadangan.'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus pesan?'), findsOneWidget);

        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();
        expect(convService.softDeleteCallCount, 1);
        expect(find.text('Pesan telah dihapus'), findsOneWidget);

        await tester.pump(const Duration(seconds: 4));
      },
    );
  });
}
