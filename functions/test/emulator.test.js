'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { initializeApp, getApps } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

const projectId = process.env.GCLOUD_PROJECT || 'demo-labflow-notifications';
const app = getApps()[0] || initializeApp({ projectId });
const db = getFirestore(app);

async function waitForNotification(recipientId, entityId, type) {
  const deadline = Date.now() + 15_000;
  while (Date.now() < deadline) {
    let query = db.collection('notifications')
      .where('recipientId', '==', recipientId)
      .where('entityId', '==', entityId)
      .limit(10);
    if (type) query = query.where('type', '==', type);
    const result = await query.get();
    if (!result.empty) return result.docs[0].data();
    await new Promise((resolve) => setTimeout(resolve, 200));
  }
  throw new Error(`Timed out waiting for notification to ${recipientId} about ${entityId}`);
}

test('Firestore events create role-scoped borrowing, report, and chat notifications', async () => {
  await db.collection('users').doc('student-u').set({ role: 'student', status: 'active' });
  await db.collection('users').doc('lab-admin-u').set({ role: 'lab_admin', status: 'active' });
  await db.collection('users').doc('superadmin-actor').set({ role: 'superadmin', status: 'active' });
  await db.collection('users').doc('superadmin-recipient').set({ role: 'superadmin', status: 'active' });
  await db.collection('lab_memberships').doc('lab-admin-u__lab-u').set({
    userId: 'lab-admin-u', labId: 'lab-u', role: 'lab_admin', active: true,
  });

  await db.collection('borrow_requests').doc('borrow-u').set({
    studentId: 'student-u', labId: 'lab-u', status: 'pending',
  });
  const borrowNotice = await waitForNotification('lab-admin-u', 'borrow-u');
  assert.equal(borrowNotice.entityType, 'borrow_request');
  assert.equal(borrowNotice.recipientRole, 'lab_admin');
  await db.collection('borrow_requests').doc('borrow-u').update({
    status: 'approved', approvedBy: 'lab-admin-u',
  });
  const studentBorrowNotice = await waitForNotification('student-u', 'borrow-u', 'borrow_approved');
  assert.equal(studentBorrowNotice.recipientRole, 'student');

  await db.collection('reports').doc('report-u').set({
    reporterId: 'student-u', labId: 'lab-u', status: 'open',
  });
  const reportNotice = await waitForNotification('lab-admin-u', 'report-u');
  assert.equal(reportNotice.type, 'report_created');

  await db.collection('reports').doc('report-u').collection('messages').doc('message-u').set({
    senderId: 'student-u', senderRole: 'student', text: 'Pembaruan',
    createdAt: FieldValue.serverTimestamp(), deletedAt: null,
  });
  const chatNotice = await waitForNotification('lab-admin-u', 'report-u', 'report_message');
  assert.equal(chatNotice.recipientId, 'lab-admin-u');

  await db.collection('activity_logs').doc('activity-u').set({
    type: 'user', actorUid: 'superadmin-actor',
  });
  const adminNotice = await waitForNotification(
    'superadmin-recipient', 'activity-u', 'admin_activity',
  );
  assert.equal(adminNotice.recipientRole, 'superadmin');
});
