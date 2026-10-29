import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_notification.dart';
import '../domain/notification_feed_mapper.dart';

/// In-app notification feed derived from authorized domain events. No client
/// writes are made to the shared notifications collection.
class NotificationCenterService {
  NotificationCenterService({
    required this.role,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final String role;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<AppNotification>> watchMine() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.error(
        const NotificationCenterException('Sesi pengguna tidak ditemukan.'),
      );
    }
    if (!{'student', 'lab_admin', 'superadmin'}.contains(role)) {
      return Stream.error(
        const NotificationCenterException('Role notifikasi tidak dikenal.'),
      );
    }

    late StreamController<List<AppNotification>> controller;
    final events = <String, AppNotification>{};
    final reads = <String>{};
    final subs = <StreamSubscription<dynamic>>[];
    final scopedSubs = <String, StreamSubscription<dynamic>>{};
    final messageSubs = <String, StreamSubscription<dynamic>>{};
    Set<String> currentLabs = {};

    void emit() {
      if (controller.isClosed) return;
      final items =
          events.values
              .map((item) => _copyRead(item, reads.contains(item.id)))
              .toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime(1970)).compareTo(
                a.createdAt ?? DateTime(1970),
              ),
            );
      controller.add(items.take(50).toList(growable: false));
    }

    void addEvent(AppNotification item) {
      events[item.id] = item;
      emit();
    }

    void addSnapshots(
      QuerySnapshot<Map<String, dynamic>> snapshot,
      String type,
    ) {
      for (final doc in snapshot.docs) {
        final event = type == 'borrow'
            ? NotificationFeedMapper.borrowing(
                role: role,
                uid: uid,
                labIds: currentLabs,
                documentId: doc.id,
                data: doc.data(),
                readStateIds: reads,
              )
            : NotificationFeedMapper.report(
                role: role,
                uid: uid,
                labIds: currentLabs,
                documentId: doc.id,
                data: doc.data(),
                readStateIds: reads,
              );
        if (event != null) addEvent(event);
      }
    }

    void watchReportMessages({
      required String reportId,
      required String reportOwnerId,
      required String labId,
    }) {
      if (messageSubs.containsKey(reportId)) return;
      messageSubs[reportId] = _firestore
          .collection('reports')
          .doc(reportId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snapshot) {
            for (final message in snapshot.docs) {
              final data = message.data();
              final event = NotificationFeedMapper.chat(
                role: role,
                uid: uid,
                labIds: currentLabs,
                reportId: reportId,
                reportOwnerId: reportOwnerId,
                labId: labId,
                messageId: message.id,
                data: data,
                readStateIds: reads,
              );
              if (event != null) addEvent(event);
            }
          }, onError: controller.addError);
    }

    controller = StreamController<List<AppNotification>>(
      onListen: () {
        subs.add(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('notification_states')
              .snapshots()
              .listen((snapshot) {
                reads
                  ..clear()
                  ..addAll(
                    snapshot.docs
                        .where((d) => d.data()['isRead'] == true)
                        .map((d) => d.id),
                  );
                emit();
              }, onError: controller.addError),
        );

        if (role == 'student') {
          subs.add(
            _firestore
                .collection('borrow_requests')
                .where('studentId', isEqualTo: uid)
                .limit(50)
                .snapshots()
                .listen(
                  (s) => addSnapshots(s, 'borrow'),
                  onError: controller.addError,
                ),
          );
          subs.add(
            _firestore
                .collection('reports')
                .where('reporterId', isEqualTo: uid)
                .limit(50)
                .snapshots()
                .listen((s) {
                  addSnapshots(s, 'report');
                  for (final report in s.docs) {
                    watchReportMessages(
                      reportId: report.id,
                      reportOwnerId: uid,
                      labId: (report.data()['labId'] as String? ?? ''),
                    );
                  }
                }, onError: controller.addError),
          );
        } else if (role == 'superadmin') {
          subs.add(
            _firestore
                .collection('activity_logs')
                .orderBy('createdAt', descending: true)
                .limit(50)
                .snapshots()
                .listen((snapshot) {
                  for (final doc in snapshot.docs) {
                    final event = NotificationFeedMapper.activity(
                      role: role,
                      documentId: doc.id,
                      data: doc.data(),
                      readStateIds: reads,
                    );
                    if (event != null) addEvent(event);
                  }
                }, onError: controller.addError),
          );
        } else {
          subs.add(
            _firestore
                .collection('lab_memberships')
                .where('userId', isEqualTo: uid)
                .where('active', isEqualTo: true)
                .snapshots()
                .listen((memberships) {
                  final labIds = memberships.docs
                      .map((d) => d.data()['labId'])
                      .whereType<String>()
                      .where((id) => id.isNotEmpty)
                      .toSet();
                  if (!setEquals(currentLabs, labIds)) {
                    for (final sub in scopedSubs.values) {
                      unawaited(sub.cancel());
                    }
                    for (final sub in messageSubs.values) {
                      unawaited(sub.cancel());
                    }
                    scopedSubs.clear();
                    messageSubs.clear();
                    events.clear();
                    currentLabs = labIds;
                  }
                  for (final labId in labIds) {
                    if (scopedSubs.containsKey('$labId:borrow')) continue;
                    final requests = _firestore
                        .collection('borrow_requests')
                        .where('labId', isEqualTo: labId)
                        .limit(50)
                        .snapshots();
                    scopedSubs['$labId:borrow'] = requests.listen(
                      (s) => addSnapshots(s, 'borrow'),
                      onError: controller.addError,
                    );
                    final reports = _firestore
                        .collection('reports')
                        .where('labId', isEqualTo: labId)
                        .limit(50)
                        .snapshots();
                    scopedSubs['$labId:report'] = reports.listen((s) {
                      addSnapshots(s, 'report');
                      for (final report in s.docs) {
                        watchReportMessages(
                          reportId: report.id,
                          reportOwnerId:
                              (report.data()['reporterId'] as String? ?? ''),
                          labId: labId,
                        );
                      }
                    }, onError: controller.addError);
                  }
                }, onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        for (final sub in subs) {
          await sub.cancel();
        }
        for (final sub in scopedSubs.values) {
          await sub.cancel();
        }
        for (final sub in messageSubs.values) {
          await sub.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<void> markRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const NotificationCenterException('Sesi pengguna tidak ditemukan.');
    }
    await _state(
      uid,
      notificationId,
    ).set({'isRead': true, 'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> markAllRead(List<AppNotification> notifications) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const NotificationCenterException('Sesi pengguna tidak ditemukan.');
    }
    for (var offset = 0; offset < notifications.length; offset += 400) {
      final batch = _firestore.batch();
      for (final event in notifications.skip(offset).take(400)) {
        batch.set(_state(uid, event.id), {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  DocumentReference<Map<String, dynamic>> _state(String uid, String id) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('notification_states')
          .doc(id);

  static bool setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
  static AppNotification _copyRead(AppNotification e, bool read) =>
      AppNotification(
        id: e.id,
        eventId: e.eventId,
        type: e.type,
        title: e.title,
        body: e.body,
        isRead: read,
        createdAt: e.createdAt,
        entityType: e.entityType,
        entityId: e.entityId,
        route: e.route,
        actorId: e.actorId,
      );
}

class NotificationCenterException implements Exception {
  const NotificationCenterException(this.message);
  final String message;
}
