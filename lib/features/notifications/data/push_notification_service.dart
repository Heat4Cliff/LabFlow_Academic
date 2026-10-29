import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef NotificationOpenHandler = Future<void> Function(
  Map<String, Object?> payload,
);

class PushNotificationService {
  PushNotificationService({
    FirebaseMessaging? messaging,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static const channelId = 'labflow_important';
  static const channelName = 'LabFlow Notifications';
  static const _permissionPrefix = 'labflow_notifications_prompted_';
  static const _pendingTapKey = 'labflow_pending_notification_tap';
  static const _storedFid = 'labflow_fcm_registration_id';

  final FirebaseMessaging _messaging;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Map<String, DateTime> _recentTaps = {};
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  Future<void> _authQueue = Future<void>.value();
  NotificationOpenHandler? _onOpen;
  String? _activeUid;
  String? _currentToken;
  bool _initialized = false;

  Future<void> initialize({required NotificationOpenHandler onOpen}) async {
    if (_initialized) {
      _onOpen = onOpen;
      return;
    }
    _onOpen = onOpen;
    _initialized = true;
    const androidSettings = AndroidInitializationSettings('ic_stat_labflow');
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: (response) {
        final rawPayload = response.payload;
        if (rawPayload == null || rawPayload.isEmpty) return;
        unawaited(_handleTap(_decodePayload(rawPayload)));
      },
    );
    const channel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: 'Pembaruan borrowing, laporan, dan aktivitas administrasi.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
      (message) => unawaited(_showForeground(message)),
    );
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_handleTap(message.data)),
    );
    _tokenSubscription = _messaging.onRegistered.listen(
      (fid) => unawaited(_replaceFid(fid)),
    );
    _authSubscription = _auth.authStateChanges().listen(_queueAuthChange);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) await _handleTap(initialMessage.data);
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
    final responsePayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        responsePayload != null &&
        responsePayload.isNotEmpty) {
      await _handleTap(_decodePayload(responsePayload));
    }
  }

  void _queueAuthChange(User? user) {
    _authQueue = _authQueue
        .then((_) => _handleAuthChange(user))
        .catchError((Object _) {});
  }

  Future<void> _handleAuthChange(User? user) async {
    final nextUid = user?.uid;
    final previousUid = _activeUid;
    if (previousUid != null && previousUid != nextUid) {
      await _removeTokenForUser(previousUid);
    }
    _activeUid = nextUid;
    if (nextUid == null) return;
    await _ensurePermissionAndToken(nextUid);
    await _processPendingTap();
  }

  Future<void> refreshPermissionAndToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) await _ensurePermissionAndToken(uid);
  }

  Future<bool> notificationsEnabled() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  Future<bool> openNotificationSettings() => openAppSettings();

  Future<void> _ensurePermissionAndToken(String uid) async {
    try {
      var settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        final preferences = await SharedPreferences.getInstance();
        final key = '$_permissionPrefix$uid';
        if (preferences.getBool(key) != true) {
          settings = await _messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );
          await preferences.setBool(key, true);
        }
      }
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }
      await _messaging.register();
    } catch (_) {
      // Keep Notification Center usable even when FCM permission/token setup fails.
    }
  }

  Future<void> _replaceFid(String fid) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || fid.isEmpty) return;
    final oldToken = _currentToken;
    if (oldToken != null && oldToken != fid) {
      await _tokenReference(uid, oldToken).delete().catchError((Object _) {});
    }
    if (_auth.currentUser?.uid != uid) return;
    final reference = _tokenReference(uid, fid);
    final existing = await reference.get();
    await reference.set({
      'fid': fid,
      'platform': defaultTargetPlatform == TargetPlatform.iOS
          ? 'ios'
          : 'android',
      'createdAt': existing.exists
          ? (existing.data()?['createdAt'] ?? FieldValue.serverTimestamp())
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storedFid, fid);
    _activeUid = uid;
    _currentToken = fid;
  }

  DocumentReference<Map<String, dynamic>> _tokenReference(
    String uid,
    String token,
  ) {
    final hash = sha256.convert(utf8.encode(token)).toString();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(hash);
  }

  Future<void> _removeTokenForUser(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    final token = _currentToken ?? preferences.getString(_storedFid);
    if (token != null && token.isNotEmpty) {
      await _tokenReference(uid, token).delete().catchError((Object _) {});
    }
    await preferences.remove(_storedFid);
    if (_activeUid == uid) _currentToken = null;
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    final data = message.data.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    final id = _localId(data['notificationId'] ?? message.messageId ?? '');
    try {
      await _localNotifications.show(
        id: id,
        title: notification.title ?? 'Pembaruan LabFlow',
        body: notification.body ?? '',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Pembaruan LabFlow yang memerlukan perhatian.',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: 'ic_stat_labflow',
          ),
        ),
        payload: jsonEncode(data),
      );
    } catch (_) {
      // The Firestore notification remains available if local presentation fails.
    }
  }

  int _localId(String value) {
    if (value.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    }
    final digest = sha256.convert(utf8.encode(value)).bytes;
    return ((digest[0] << 24) |
            (digest[1] << 16) |
            (digest[2] << 8) |
            digest[3]) &
        0x7fffffff;
  }

  Map<String, Object?> _decodePayload(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } catch (_) {}
    return const {};
  }

  Future<void> _handleTap(Map<String, Object?> payload) async {
    final notificationId = payload['notificationId']?.toString() ?? '';
    if (notificationId.isNotEmpty) {
      final now = DateTime.now();
      _recentTaps.removeWhere(
        (_, time) => now.difference(time) > const Duration(minutes: 2),
      );
      if (_recentTaps.containsKey(notificationId)) return;
      _recentTaps[notificationId] = now;
    }
    if (_auth.currentUser == null) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_pendingTapKey, jsonEncode(payload));
      return;
    }
    await _onOpen?.call(payload);
  }

  Future<void> _processPendingTap() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_pendingTapKey);
    if (raw == null || raw.isEmpty) return;
    await preferences.remove(_pendingTapKey);
    await _onOpen?.call(_decodePayload(raw));
  }

  Future<void> close() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _initialized = false;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background notification payloads are shown by Android/FCM automatically.
  // Do not show a second local notification from this isolate.
  debugPrint(
    'LabFlow background push received: ${message.data['notificationId'] ?? 'event'}',
  );
}
