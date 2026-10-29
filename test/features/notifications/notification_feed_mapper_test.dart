import 'package:flutter_test/flutter_test.dart';
import 'package:labflow/features/notifications/domain/notification_feed_mapper.dart';

void main() {
  final reads = <String>{};
  final time = DateTime.utc(2026, 10, 29);

  test('student feed maps only own borrowing and report records', () {
    final request = NotificationFeedMapper.borrowing(
      role: 'student',
      uid: 'student-a',
      labIds: const {},
      documentId: 'doc-1',
      data: {
        'studentId': 'student-a',
        'requestNumber': 'BRW-01',
        'status': 'pending',
        'createdAt': time,
      },
      readStateIds: reads,
    );
    expect(request?.entityId, 'doc-1');
    expect(request?.body, contains('BRW-01'));
    expect(
      NotificationFeedMapper.borrowing(
        role: 'student',
        uid: 'student-a',
        labIds: const {},
        documentId: 'doc-2',
        data: {'studentId': 'student-b', 'status': 'pending'},
        readStateIds: reads,
      ),
      isNull,
    );
    final report = NotificationFeedMapper.report(
      role: 'student',
      uid: 'student-a',
      labIds: const {},
      documentId: 'report-1',
      data: {
        'reporterId': 'student-a',
        'reportNumber': 'RPT-01',
        'status': 'open',
        'updatedAt': time,
      },
      readStateIds: reads,
    );
    expect(report?.entityType, 'report');
    expect(report?.body, contains('RPT-01'));
  });

  test('Lab Admin feed is constrained to managed lab ids', () {
    final inScope = NotificationFeedMapper.borrowing(
      role: 'lab_admin',
      uid: 'admin-a',
      labIds: {'lab-a'},
      documentId: 'req',
      data: {
        'labId': 'lab-a',
        'requestNumber': 'BRW-02',
        'status': 'pending',
        'createdAt': time,
      },
      readStateIds: reads,
    );
    final outsideScope = NotificationFeedMapper.borrowing(
      role: 'lab_admin',
      uid: 'admin-a',
      labIds: {'lab-a'},
      documentId: 'req-2',
      data: {
        'labId': 'lab-b',
        'requestNumber': 'BRW-03',
        'status': 'pending',
        'createdAt': time,
      },
      readStateIds: reads,
    );
    expect(inScope, isNotNull);
    expect(outsideScope, isNull);
    expect(
      NotificationFeedMapper.report(
        role: 'lab_admin',
        uid: 'admin-a',
        labIds: {'lab-a'},
        documentId: 'report',
        data: {'labId': 'lab-b', 'reportNumber': 'RPT-02', 'status': 'open'},
        readStateIds: reads,
      ),
      isNull,
    );
  });

  test(
    'chat feed accepts only the other role and never exposes sender UID',
    () {
      final studentEvent = NotificationFeedMapper.chat(
        role: 'student',
        uid: 'student-a',
        labIds: const {},
        reportId: 'report-1',
        reportOwnerId: 'student-a',
        labId: 'lab-a',
        messageId: 'message-1',
        data: {
          'senderRole': 'lab_admin',
          'senderId': 'private-admin-uid',
          'createdAt': time,
        },
        readStateIds: reads,
      );
      expect(studentEvent?.body, 'Ada pesan baru dalam percakapan laporan.');
      expect(studentEvent?.body, isNot(contains('private-admin-uid')));
      expect(
        NotificationFeedMapper.chat(
          role: 'student',
          uid: 'student-a',
          labIds: const {},
          reportId: 'report-1',
          reportOwnerId: 'student-a',
          labId: 'lab-a',
          messageId: 'message-2',
          data: {'senderRole': 'student'},
          readStateIds: reads,
        ),
        isNull,
      );
      expect(
        NotificationFeedMapper.chat(
          role: 'lab_admin',
          uid: 'admin-a',
          labIds: {'lab-a'},
          reportId: 'report-1',
          reportOwnerId: 'student-a',
          labId: 'lab-b',
          messageId: 'message-3',
          data: {'senderRole': 'student'},
          readStateIds: reads,
        ),
        isNull,
      );
    },
  );

  test('superadmin feed maps actual activity log source only and retains per-event read state', () {
    final data = {
      'title': 'Pengguna diperbarui',
      'description': 'Aksi tercatat',
      'createdAt': time,
    };
    final unread = NotificationFeedMapper.activity(
      role: 'superadmin',
      documentId: 'activity-1',
      data: data,
      readStateIds: reads,
    );
    expect(unread?.entityType, 'admin_activity');
    final readIds = {unread!.id};
    expect(
      NotificationFeedMapper.activity(
        role: 'superadmin',
        documentId: 'activity-1',
        data: data,
        readStateIds: readIds,
      )?.isRead,
      isTrue,
    );
    expect(
      NotificationFeedMapper.activity(
        role: 'student',
        documentId: 'activity-1',
        data: data,
        readStateIds: reads,
      ),
      isNull,
    );
  });
}
