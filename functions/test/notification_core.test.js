'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const {
  activeLabAdminIds,
  buildNotification,
  isPermanentTokenError,
  reportMessageRecipients,
  routeFor,
  stableNotificationId,
} = require('../src/notification_core');

test('notification id is stable per event and recipient', () => {
  assert.equal(stableNotificationId('evt-1', 'user-1'), stableNotificationId('evt-1', 'user-1'));
  assert.notEqual(stableNotificationId('evt-1', 'user-1'), stableNotificationId('evt-1', 'user-2'));
});

test('only active lab admins with active profiles are recipients', () => {
  const rows = [
    { userId: 'a', labId: 'lab', role: 'lab_admin', active: true },
    { userId: 'b', labId: 'lab', role: 'lab_admin', active: false },
    { userId: 'c', labId: 'lab', role: 'student', active: true },
  ];
  assert.deepEqual(activeLabAdminIds(rows, new Set(['a', 'b', 'c']), 'a'), []);
  assert.deepEqual(activeLabAdminIds(rows, new Set(['a']), ''), ['a']);
});

test('report chat recipients exclude sender and notify only opposite side', () => {
  assert.deepEqual(reportMessageRecipients({
    senderRole: 'student', senderId: 'student', reporterId: 'student', labAdminIds: ['admin'],
  }), ['admin']);
  assert.deepEqual(reportMessageRecipients({
    senderRole: 'lab_admin', senderId: 'admin', reporterId: 'student', labAdminIds: ['admin'],
  }), ['student']);
});

test('notification content is generic and routes are derived from role and entity', () => {
  const notice = buildNotification({
    eventId: 'evt', recipientId: 'student', recipientRole: 'student',
    type: 'borrow_approved', entityType: 'borrow_request', entityId: 'req/1',
    actorId: 'admin', createdAt: 'now',
  });
  assert.equal(notice.data.route, '/student/borrowing/req%2F1');
  assert.equal(notice.data.isRead, false);
  assert.equal(notice.data.body.includes('student'), false);
  assert.equal(routeFor('superadmin', 'admin_activity', 'x'), '/superadmin/activity');
  assert.equal(buildNotification({
    eventId: 'evt', recipientId: 'admin', recipientRole: 'lab_admin',
    type: 'borrow_request', entityType: 'borrow_request', entityId: 'req', actorId: 'admin',
  }), null);
});

test('only permanent registration errors qualify for token deletion', () => {
  assert.equal(isPermanentTokenError('messaging/registration-token-not-registered'), true);
  assert.equal(isPermanentTokenError('messaging/installation-id-not-registered'), true);
  assert.equal(isPermanentTokenError('messaging/invalid-registration-token'), true);
  assert.equal(isPermanentTokenError('messaging/internal-error'), false);
});
