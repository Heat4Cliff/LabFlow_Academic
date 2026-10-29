'use strict';

const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { logger } = require('firebase-functions');
const { setGlobalOptions } = require('firebase-functions/v2');
const { onDocumentCreated, onDocumentUpdated } = require('firebase-functions/v2/firestore');
const {
  ANDROID_CHANNEL_ID,
  activeLabAdminIds,
  buildNotification,
  isPermanentTokenError,
  reportMessageRecipients,
} = require('./notification_core');

initializeApp();
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

const db = getFirestore();
const ROLE_COLLECTION = 'users';

async function activeProfile(uid, expectedRole) {
  if (!uid || typeof uid !== 'string') return null;
  const snapshot = await db.collection(ROLE_COLLECTION).doc(uid).get();
  const profile = snapshot.data();
  if (
    !snapshot.exists ||
    profile?.status !== 'active' ||
    (expectedRole && profile.role !== expectedRole)
  ) {
    return null;
  }
  return profile;
}

async function activeLabAdmins(labId, excludedUid = '') {
  if (!labId || typeof labId !== 'string') return [];
  const snapshot = await db
    .collection('lab_memberships')
    .where('labId', '==', labId)
    .get();
  const memberships = snapshot.docs
    .map((document) => ({ id: document.id, ...document.data() }))
    .filter((membership) =>
      membership.id === `${membership.userId}__${labId}` &&
      membership.role === 'lab_admin' &&
      membership.active === true,
    );
  const uniqueIds = [...new Set(memberships.map((membership) => membership.userId))]
    .filter((uid) => uid !== excludedUid);
  const activeUsers = await Promise.all(
    uniqueIds.map(async (uid) =>
      (await activeProfile(uid, 'lab_admin')) ? uid : null,
    ),
  );
  const activeUserIds = new Set(activeUsers.filter(Boolean));
  return activeLabAdminIds(memberships, activeUserIds, excludedUid);
}

async function activeSuperadmins(excludedUid = '') {
  const snapshot = await db
    .collection(ROLE_COLLECTION)
    .where('role', '==', 'superadmin')
    .where('status', '==', 'active')
    .get();
  return snapshot.docs
    .map((document) => document.id)
    .filter((uid) => uid !== excludedUid);
}

async function writeNotification({ eventId, recipientId, recipientRole, type,
  entityType, entityId, actorId, createdAt }) {
  const notice = buildNotification({
    eventId,
    recipientId,
    recipientRole,
    type,
    entityType,
    entityId,
    actorId,
    createdAt: createdAt || FieldValue.serverTimestamp(),
  });
  if (!notice) return false;
  const data = { ...notice.data };
  // Keep legacy Student clients readable during migration.
  if (recipientRole === 'student') data.studentId = recipientId;
  await db.collection('notifications').doc(notice.id).create(data).catch((error) => {
    if (error.code === 6 || error.code === 'already-exists') return;
    throw error;
  });
  return true;
}

async function notifyMany({ eventId, recipientIds, recipientRole, type,
  entityType, entityId, actorId }) {
  const unique = [...new Set(recipientIds)].filter((uid) => uid && uid !== actorId);
  await Promise.all(unique.map((recipientId) => writeNotification({
    eventId,
    recipientId,
    recipientRole,
    type,
    entityType,
    entityId,
    actorId,
  })));
}

exports.onBorrowRequestCreated = onDocumentCreated(
  { document: 'borrow_requests/{requestId}', retry: true },
  async (event) => {
    const request = event.data?.data();
    if (!request || request.status !== 'pending') return;
    const studentIsActive = await activeProfile(request.studentId, 'student');
    if (!studentIsActive) return;
    const recipientIds = await activeLabAdmins(request.labId, request.studentId);
    await notifyMany({
      eventId: event.id,
      recipientIds,
      recipientRole: 'lab_admin',
      type: 'borrow_request',
      entityType: 'borrow_request',
      entityId: event.params.requestId,
      actorId: request.studentId,
    });
  },
);

const BORROW_STATUS_TYPES = Object.freeze({
  approved: 'borrow_approved',
  rejected: 'borrow_rejected',
  waiting_pickup: 'borrow_waiting_pickup',
  active: 'borrow_active',
  returned: 'borrow_returned',
  cancelled: 'borrow_cancelled',
  canceled: 'borrow_cancelled',
});

exports.onBorrowRequestUpdated = onDocumentUpdated(
  { document: 'borrow_requests/{requestId}', retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    const type = BORROW_STATUS_TYPES[after.status];
    if (!type) return;
    if (type === 'borrow_cancelled') {
      const actorId = after.cancelledBy || after.canceledBy || after.studentId;
      const recipientIds = await activeLabAdmins(after.labId, actorId);
      await notifyMany({
        eventId: event.id, recipientIds, recipientRole: 'lab_admin', type,
        entityType: 'borrow_request', entityId: event.params.requestId, actorId,
      });
      return;
    }
    if (!(await activeProfile(after.studentId, 'student'))) return;
    const actorId = after.approvedBy || after.rejectedBy || after.updatedBy || null;
    await notifyMany({
      eventId: event.id,
      recipientIds: [after.studentId],
      recipientRole: 'student',
      type,
      entityType: 'borrow_request',
      entityId: event.params.requestId,
      actorId,
    });
  },
);

exports.onReportCreated = onDocumentCreated(
  { document: 'reports/{reportId}', retry: true },
  async (event) => {
    const report = event.data?.data();
    if (!report || report.status !== 'open') return;
    if (!(await activeProfile(report.reporterId, 'student'))) return;
    const recipientIds = await activeLabAdmins(report.labId, report.reporterId);
    await notifyMany({
      eventId: event.id,
      recipientIds,
      recipientRole: 'lab_admin',
      type: 'report_created',
      entityType: 'report',
      entityId: event.params.reportId,
      actorId: report.reporterId,
    });
  },
);

exports.onReportUpdated = onDocumentUpdated(
  { document: 'reports/{reportId}', retry: true },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after || before.status === after.status) return;
    if (!(await activeProfile(after.reporterId, 'student'))) return;
    await notifyMany({
      eventId: event.id,
      recipientIds: [after.reporterId],
      recipientRole: 'student',
      type: 'report_status_changed',
      entityType: 'report',
      entityId: event.params.reportId,
      actorId: after.assignedTo || null,
    });
  },
);

exports.onReportMessageCreated = onDocumentCreated(
  {
    document: 'reports/{reportId}/messages/{messageId}',
    retry: true,
  },
  async (event) => {
    const message = event.data?.data();
    if (!message || message.deletedAt != null) return;
    const reportSnapshot = await db.collection('reports').doc(event.params.reportId).get();
    const report = reportSnapshot.data();
    if (!reportSnapshot.exists || !report) return;
    const sender = await activeProfile(message.senderId);
    if (!sender || !['student', 'lab_admin'].includes(sender.role)) return;
    if (message.senderRole !== sender.role) return;

    let recipients;
    if (sender.role === 'student' && message.senderId === report.reporterId) {
      recipients = await activeLabAdmins(report.labId, message.senderId);
    } else if (
      sender.role === 'lab_admin' &&
      (await activeLabAdmins(report.labId)).includes(message.senderId) &&
      (await activeProfile(report.reporterId, 'student'))
    ) {
      recipients = [report.reporterId];
    } else {
      return;
    }
    await notifyMany({
      eventId: event.id,
      recipientIds: recipients,
      recipientRole: sender.role === 'student' ? 'lab_admin' : 'student',
      type: 'report_message',
      entityType: 'report',
      entityId: event.params.reportId,
      actorId: message.senderId,
    });
  },
);

exports.onSuperadminActivityCreated = onDocumentCreated(
  { document: 'activity_logs/{activityId}', retry: true },
  async (event) => {
    const activity = event.data?.data();
    if (!activity || !['user', 'laboratory', 'membership'].includes(activity.type)) return;
    if (!(await activeProfile(activity.actorUid, 'superadmin'))) return;
    const recipientIds = await activeSuperadmins(activity.actorUid);
    await notifyMany({
      eventId: event.id,
      recipientIds,
      recipientRole: 'superadmin',
      type: 'admin_activity',
      entityType: 'admin_activity',
      entityId: event.params.activityId,
      actorId: activity.actorUid,
    });
  },
);

async function claimPush(notificationRef) {
  return db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(notificationRef);
    if (!snapshot.exists) return null;
    const data = snapshot.data();
    const state = data.pushState || 'pending';
    if (['sent', 'no_tokens'].includes(state)) return null;
    if (state === 'sending') {
      const claimedAt = data.pushClaimedAt;
      if (claimedAt instanceof Timestamp && Date.now() - claimedAt.toMillis() < 180_000) {
        return null;
      }
    }
    transaction.update(notificationRef, {
      pushState: 'sending',
      pushClaimedAt: FieldValue.serverTimestamp(),
      pushAttempts: FieldValue.increment(1),
    });
    return data;
  });
}

function invalidTokenIds(response, tokenDocs) {
  const ids = [];
  response.responses.forEach((item, index) => {
    if (!item.success && isPermanentTokenError(item.error?.code)) {
      ids.push(tokenDocs[index].id);
    }
  });
  return ids;
}

exports.dispatchNotificationPush = onDocumentCreated(
  { document: 'notifications/{notificationId}', retry: true },
  async (event) => {
    const notificationRef = event.data?.ref;
    if (!notificationRef) return;
    const data = await claimPush(notificationRef);
    if (!data) return;

    const tokensSnapshot = await db
      .collection('users')
      .doc(data.recipientId)
      .collection('fcmTokens')
      .get();
    const tokenDocs = tokensSnapshot.docs.filter((document) =>
      typeof document.data().fid === 'string' && document.data().fid.length > 0,
    );
    if (tokenDocs.length === 0) {
      await notificationRef.update({ pushState: 'no_tokens' });
      return;
    }

    let successCount = 0;
    let failureCount = 0;
    const staleTokenIds = [];
    try {
      for (let offset = 0; offset < tokenDocs.length; offset += 500) {
        const chunk = tokenDocs.slice(offset, offset + 500);
        const response = await getMessaging().sendEachForMulticast({
          fids: chunk.map((document) => document.data().fid),
          notification: { title: data.title, body: data.body },
          data: {
            eventId: String(data.eventId),
            notificationId: event.params.notificationId,
            type: String(data.type),
            entityType: String(data.entityType),
            entityId: String(data.entityId),
            route: String(data.route),
          },
          android: {
            priority: 'high',
            notification: {
              channelId: ANDROID_CHANNEL_ID,
              sound: 'default',
              tag: event.params.notificationId,
              icon: 'ic_stat_labflow',
            },
          },
        });
        successCount += response.successCount;
        failureCount += response.failureCount;
        staleTokenIds.push(...invalidTokenIds(response, chunk));
      }
      if (staleTokenIds.length > 0) {
        const batch = db.batch();
        for (const tokenId of staleTokenIds) batch.delete(
          db.collection('users').doc(data.recipientId).collection('fcmTokens').doc(tokenId),
        );
        await batch.commit();
      }
      await notificationRef.update({
        pushState: successCount > 0 ? 'sent' : 'failed',
        pushSuccessCount: successCount,
        pushFailureCount: failureCount,
        pushCompletedAt: FieldValue.serverTimestamp(),
      });
      logger.info('Notification push dispatch completed', {
        notificationId: event.params.notificationId,
        recipientId: data.recipientId,
        successCount,
        failureCount,
        staleTokenCount: staleTokenIds.length,
      });
      if (successCount === 0 && failureCount > staleTokenIds.length) {
        throw new Error('FCM delivery failed for all currently registered tokens.');
      }
    } catch (error) {
      await notificationRef.update({
        pushState: 'pending',
        pushLastErrorCode: typeof error?.code === 'string' ? error.code : 'send-failed',
      });
      throw error;
    }
  },
);
