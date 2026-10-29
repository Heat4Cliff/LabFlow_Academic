'use strict';

const { createHash } = require('node:crypto');

const ANDROID_CHANNEL_ID = 'labflow_important';

function stableNotificationId(eventId, recipientId) {
  return createHash('sha256')
    .update(`${eventId}\n${recipientId}`)
    .digest('hex');
}

function activeLabAdminIds(memberships, activeUserIds, excludedUid = '') {
  const recipients = new Set();
  for (const membership of memberships) {
    const uid = typeof membership.userId === 'string' ? membership.userId : '';
    if (
      membership.role === 'lab_admin' &&
      membership.active === true &&
      membership.labId &&
      uid &&
      uid !== excludedUid &&
      activeUserIds.has(uid)
    ) {
      recipients.add(uid);
    }
  }
  return [...recipients];
}

function reportMessageRecipients({ senderRole, senderId, reporterId, labAdminIds }) {
  if (senderRole === 'student') {
    return labAdminIds.filter((uid) => uid !== senderId);
  }
  if (senderRole === 'lab_admin' && reporterId !== senderId) {
    return [reporterId];
  }
  return [];
}

function routeFor(role, entityType, entityId) {
  const id = encodeURIComponent(entityId || '');
  if (entityType === 'borrow_request') {
    if (role === 'student') return `/student/borrowing/${id}`;
    if (role === 'lab_admin') return `/lab-admin/borrowing/${id}`;
  }
  if (entityType === 'report') {
    if (role === 'student') return `/student/reports/${id}`;
    if (role === 'lab_admin') return `/lab-admin/reports/${id}`;
  }
  if (entityType === 'admin_activity' && role === 'superadmin') {
    return '/superadmin/activity';
  }
  return role === 'student'
    ? '/student/notifications'
    : role === 'lab_admin'
      ? '/lab-admin/notifications'
      : role === 'superadmin'
        ? '/superadmin/notifications'
        : '/login';
}

const CONTENT = Object.freeze({
  borrow_request: {
    borrow_request: {
      title: 'Permintaan Peminjaman Baru',
      body: 'Ada permintaan peminjaman yang perlu diperiksa.',
    },
    borrow_approved: {
      title: 'Peminjaman Disetujui',
      body: 'Permintaan peminjaman Anda telah disetujui.',
    },
    borrow_rejected: {
      title: 'Peminjaman Ditolak',
      body: 'Status permintaan peminjaman Anda telah diperbarui.',
    },
    borrow_waiting_pickup: {
      title: 'Aset Siap Diambil',
      body: 'Aset yang Anda ajukan siap untuk diambil.',
    },
    borrow_active: {
      title: 'Peminjaman Dimulai',
      body: 'Status peminjaman aset Anda telah diperbarui.',
    },
    borrow_returned: {
      title: 'Pengembalian Diproses',
      body: 'Pengembalian aset Anda telah diproses.',
    },
    borrow_cancelled: {
      title: 'Permintaan Dibatalkan',
      body: 'Permintaan peminjaman pada laboratorium Anda dibatalkan.',
    },
  },
  report: {
    report_created: {
      title: 'Laporan Baru',
      body: 'Ada laporan baru yang perlu ditinjau.',
    },
    report_status_changed: {
      title: 'Status Laporan Diperbarui',
      body: 'Status laporan Anda telah diperbarui.',
    },
    report_message: {
      title: 'Balasan Laporan Baru',
      body: 'Ada balasan baru pada percakapan laporan.',
    },
  },
  admin_activity: {
    admin_activity: {
      title: 'Aktivitas Administratif',
      body: 'Ada pembaruan administrasi yang perlu ditinjau.',
    },
  },
});

function buildNotification({
  eventId,
  recipientId,
  recipientRole,
  type,
  entityType,
  entityId,
  actorId = null,
  createdAt,
}) {
  if (!eventId || !recipientId || !recipientRole || !entityType || !entityId) {
    return null;
  }
  if (actorId && actorId === recipientId) return null;

  const content = CONTENT[entityType]?.[type];
  if (!content) return null;

  const notificationId = stableNotificationId(eventId, recipientId);
  return {
    id: notificationId,
    data: {
      recipientId,
      recipientRole,
      type,
      title: content.title,
      body: content.body,
      isRead: false,
      read: false,
      createdAt,
      eventId,
      entityType,
      entityId,
      targetType: entityType,
      targetId: entityId,
      route: routeFor(recipientRole, entityType, entityId),
      ...(actorId ? { actorId } : {}),
      pushState: 'pending',
    },
  };
}

function isPermanentTokenError(code) {
  return code === 'messaging/invalid-registration-token' ||
    code === 'messaging/registration-token-not-registered' ||
    code === 'messaging/installation-id-not-registered';
}

module.exports = {
  ANDROID_CHANNEL_ID,
  activeLabAdminIds,
  buildNotification,
  isPermanentTokenError,
  reportMessageRecipients,
  routeFor,
  stableNotificationId,
};
