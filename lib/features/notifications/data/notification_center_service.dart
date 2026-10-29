import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/app_notification.dart';

class NotificationCenterService {
  NotificationCenterService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<List<AppNotification>> watchMine() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.error(
        const NotificationCenterException('Sesi pengguna tidak ditemukan.'),
      );
    }

    final controller = StreamController<List<AppNotification>>();
    final current = <String, AppNotification>{};
    final legacy = <String, AppNotification>{};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? currentSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? legacySub;

    void emit() {
      if (controller.isClosed) return;
      final merged =
          <String, AppNotification>{...legacy, ...current}.values.toList()
            ..sort(
              (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                  .compareTo(
                    a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                  ),
            );
      controller.add(merged.take(50).toList(growable: false));
    }

    controller.onListen = () {
      currentSub = _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
            current
              ..clear()
              ..addEntries(
                snapshot.docs.map(
                  (document) => MapEntry(
                    document.id,
                    AppNotification.fromDocument(document),
                  ),
                ),
              );
            emit();
          }, onError: controller.addError);
      // Older Student notifications used studentId without recipientId.
      legacySub = _firestore
          .collection('notifications')
          .where('studentId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots()
          .listen((snapshot) {
            legacy
              ..clear()
              ..addEntries(
                snapshot.docs.map(
                  (document) => MapEntry(
                    document.id,
                    AppNotification.fromDocument(document),
                  ),
                ),
              );
            emit();
          }, onError: controller.addError);
    };
    controller.onCancel = () async {
      await currentSub?.cancel();
      await legacySub?.cancel();
    };
    return controller.stream;
  }

  Future<void> markRead(String notificationId) => _firestore
      .collection('notifications')
      .doc(notificationId)
      .update({'isRead': true, 'read': true});

  Future<void> markAllRead(List<AppNotification> notifications) async {
    final unread = notifications.where((item) => !item.isRead).toList();
    for (var offset = 0; offset < unread.length; offset += 400) {
      final batch = _firestore.batch();
      for (final item in unread.skip(offset).take(400)) {
        batch.update(_firestore.collection('notifications').doc(item.id), {
          'isRead': true,
          'read': true,
        });
      }
      await batch.commit();
    }
  }
}

class NotificationCenterException implements Exception {
  const NotificationCenterException(this.message);
  final String message;
}
