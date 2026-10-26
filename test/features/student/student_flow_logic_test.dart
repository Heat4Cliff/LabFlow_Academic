import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/borrowing/domain/borrow_request.dart';
import 'package:labflow/features/reporting/data/report_conversation_service.dart';
import 'package:labflow/features/student/data/student_borrowing_detail_service.dart';
import 'package:labflow/features/student/data/student_notification_service.dart';
import 'package:labflow/features/student/data/student_report_service.dart';
import 'package:labflow/features/student/domain/student_borrowing_detail.dart';
import 'package:labflow/features/student/domain/student_notification.dart';
import 'package:labflow/features/student/presentation/cubit/student_borrowing_detail_cubit.dart';
import 'package:labflow/features/student/presentation/cubit/student_borrowing_detail_state.dart';
import 'package:labflow/features/student/presentation/cubit/student_notification_cubit.dart';
import 'package:labflow/features/student/presentation/cubit/student_notification_state.dart';
import 'package:labflow/features/student/presentation/student_navigation.dart';
import 'package:labflow/features/student/presentation/widgets/student_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockStudentBorrowingDetailService extends Mock
    implements StudentBorrowingDetailService {}

class MockStudentNotificationService extends Mock
    implements StudentNotificationService {}

void main() {
  group('Student status mapping', () {
    test('covers the borrowing lifecycle and terminal branches', () {
      expect(studentStatusLabel('pending'), 'Menunggu');
      expect(studentStatusLabel('approved'), 'Disetujui');
      expect(studentStatusLabel('waiting_pickup'), 'Menunggu Diambil');
      expect(studentStatusLabel('active'), 'Aktif');
      expect(studentStatusLabel('returned'), 'Dikembalikan');
      expect(studentStatusLabel('rejected'), 'Ditolak');
      expect(studentStatusLabel('cancelled'), 'Dibatalkan');
    });
  });

  group('Student navigation targets', () {
    test('request form path stays separate from document detail paths', () {
      expect(studentBorrowRequestFormPath, '/student/borrowing/request');
      expect(
        studentBorrowingDocumentPath('actual-doc-id'),
        '/student/borrowing/actual-doc-id',
      );
      expect(
        studentNotificationTargetPath(
          targetType: 'borrow_request',
          targetId: 'actual-doc-id',
        ),
        '/student/borrowing/actual-doc-id',
      );
      expect(() => studentBorrowingDocumentPath(''), throwsArgumentError);
    });

    test('notification destinations reject empty and unsupported targets', () {
      expect(
        studentNotificationTargetPath(
          targetType: 'borrow_request',
          targetId: '  ',
        ),
        isNull,
      );
      expect(
        studentNotificationTargetPath(targetType: 'other', targetId: 'id-1'),
        isNull,
      );
    });

    test('unread badge omits zero and caps counts above nine', () {
      expect(studentNotificationBadgeLabel(0), isNull);
      expect(studentNotificationBadgeLabel(-1), isNull);
      expect(studentNotificationBadgeLabel(1), '1');
      expect(studentNotificationBadgeLabel(9), '9');
      expect(studentNotificationBadgeLabel(10), '9+');
    });
  });

  group('StudentReportService validation and ownership', () {
    test('rejects missing fields and accepts valid report input', () {
      expect(
        StudentReportService.validate(
          labId: '',
          category: 'other',
          title: 'Kerusakan',
          description: 'Tidak berfungsi',
          location: 'Lab 1',
          severity: 'normal',
        ),
        'Pilih laboratorium.',
      );
      expect(
        StudentReportService.validate(
          labId: 'lab-1',
          category: 'network',
          title: 'Jaringan putus',
          description: 'Internet tidak tersambung.',
          location: 'Lab 1',
          severity: 'urgent',
        ),
        isNull,
      );
    });

    test('only the authenticated reporter is the owner', () {
      expect(
        StudentReportService.isOwner(
          authUid: 'student-1',
          reporterId: 'student-1',
        ),
        isTrue,
      );
      expect(
        StudentReportService.isOwner(
          authUid: 'student-1',
          reporterId: 'student-2',
        ),
        isFalse,
      );
      expect(
        StudentReportService.isOwner(authUid: '', reporterId: ''),
        isFalse,
      );
    });
  });

  group('Report conversation validation', () {
    test('trims whitespace and caps messages at 1000 characters', () {
      expect(ReportConversationService.validateMessage('  '), isNotNull);
      expect(ReportConversationService.validateMessage('  Halo  '), isNull);
      expect(ReportConversationService.validateMessage('x' * 1001), isNotNull);
    });
  });

  group('Student notification state', () {
    test('counts unread notifications without exposing message content', () {
      final state = StudentNotificationState(
        notifications: [
          StudentNotification(
            id: 'n1',
            type: 'report_message',
            title: 'Pesan baru',
            body: 'Ada pesan baru pada laporan RPT-1.',
            targetType: 'report',
            targetId: 'r1',
            read: false,
            createdAt: DateTime(2026),
          ),
          StudentNotification(
            id: 'n2',
            type: 'borrow_active',
            title: 'Peminjaman aktif',
            body: 'Status berubah.',
            targetType: 'borrow_request',
            targetId: 'b1',
            read: true,
            createdAt: DateTime(2026),
          ),
        ],
      );
      expect(state.unreadCount, 1);
      expect(state.notifications.first.body, isNot(contains('plaintext')));
    });

    test('markRead delegates to the own-notification update service', () async {
      final service = MockStudentNotificationService();
      when(() => service.markRead('n1')).thenAnswer((_) async {});
      final cubit = StudentNotificationCubit(service);

      await cubit.markRead('n1');

      expect(cubit.state.readingIds, isEmpty);
      expect(cubit.state.errorMessage, isEmpty);
      verify(() => service.markRead('n1')).called(1);
      await cubit.close();
    });
  });

  test(
    'StudentBorrowingDetailCubit combines realtime sources and closes them',
    () async {
      final service = MockStudentBorrowingDetailService();
      final request = BorrowRequest(
        id: 'request-1',
        requestNumber: 'BRW-1',
        studentId: 'student-1',
        labId: 'lab-1',
        purpose: 'Praktikum',
        borrowDate: DateTime(2026, 10, 26),
        expectedReturnDate: DateTime(2026, 10, 27),
        status: 'active',
        studentNote: null,
        approvedBy: 'admin-1',
        approvedAt: null,
        rejectionReason: null,
        createdAt: DateTime(2026, 10, 25),
        updatedAt: DateTime(2026, 10, 25),
      );
      when(() => service.watchRequest('request-1'))
          .thenAnswer((_) => Stream.value(request));
      when(() => service.watchItems('request-1'))
          .thenAnswer((_) => Stream.value(const <BorrowRequestItem>[]));
      when(() => service.watchAssignments('request-1'))
          .thenAnswer((_) => Stream.value(const <StudentAssignedBorrowing>[]));
      when(() => service.loadLaboratoryName('lab-1'))
          .thenAnswer((_) async => 'Lab IoT');

      final cubit = StudentBorrowingDetailCubit(service);
      final loaded = expectLater(
        cubit.stream,
        emitsThrough(
          isA<StudentBorrowingDetailState>().having(
            (state) => state.status,
            'status',
            StudentBorrowingDetailStatus.loaded,
          ),
        ),
      );
      cubit.watch('request-1');
      await loaded;
      expect(cubit.state.request?.requestNumber, 'BRW-1');
      expect(cubit.state.laboratoryName, 'Lab IoT');
      await cubit.close();
      verify(() => service.watchRequest('request-1')).called(1);
    },
  );
}
