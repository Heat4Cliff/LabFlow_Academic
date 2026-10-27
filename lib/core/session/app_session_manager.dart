import 'package:shared_preferences/shared_preferences.dart';

/// Waktu sesi aplikasi bersifat absolut sejak login, terpisah dari token Firebase.
class AppSession {
  const AppSession({
    required this.uid,
    required this.startedAtUtcMs,
    required this.expiresAtUtcMs,
  });

  final String uid;
  final int startedAtUtcMs;
  final int expiresAtUtcMs;

  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(expiresAtUtcMs, isUtc: true);

  bool isValidFor(String currentUid, DateTime now) {
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    return uid.isNotEmpty &&
        uid == currentUid &&
        startedAtUtcMs > 0 &&
        expiresAtUtcMs - startedAtUtcMs ==
            AppSessionManager.duration.inMilliseconds &&
        nowMs >= startedAtUtcMs &&
        nowMs < expiresAtUtcMs;
  }
}

abstract class AppSessionStorage {
  Future<AppSession?> read();
  Future<void> write(AppSession session);
  Future<void> clear();
}

class SharedPreferencesSessionStorage implements AppSessionStorage {
  SharedPreferencesSessionStorage({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _uidKey = 'session_uid';
  static const _startedKey = 'session_started_at';
  static const _expiresKey = 'session_expires_at';

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSession?> read() async {
    final uid = await _preferences.getString(_uidKey);
    final started = await _preferences.getInt(_startedKey);
    final expires = await _preferences.getInt(_expiresKey);
    if (uid == null || started == null || expires == null) return null;
    return AppSession(
      uid: uid,
      startedAtUtcMs: started,
      expiresAtUtcMs: expires,
    );
  }

  @override
  Future<void> write(AppSession session) async {
    await _preferences.setString(_uidKey, session.uid);
    await _preferences.setInt(_startedKey, session.startedAtUtcMs);
    await _preferences.setInt(_expiresKey, session.expiresAtUtcMs);
  }

  @override
  Future<void> clear() async {
    await _preferences.remove(_uidKey);
    await _preferences.remove(_startedKey);
    await _preferences.remove(_expiresKey);
  }
}

class AppSessionManager {
  AppSessionManager({required this.storage, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static final instance = AppSessionManager(
    storage: SharedPreferencesSessionStorage(),
  );
  static const duration = Duration(hours: 1);

  final AppSessionStorage storage;
  final DateTime Function() _now;

  Future<AppSession> start(String uid) async {
    if (uid.isEmpty) throw ArgumentError.value(uid, 'uid');
    final started = _now().toUtc().millisecondsSinceEpoch;
    final session = AppSession(
      uid: uid,
      startedAtUtcMs: started,
      expiresAtUtcMs: started + duration.inMilliseconds,
    );
    // Hapus sesi lama lebih dulu agar penulisan parsial tidak dapat dipakai.
    await storage.clear();
    await storage.write(session);
    return session;
  }

  Future<AppSession?> validFor(String uid) async {
    try {
      final session = await storage.read();
      if (session != null && session.isValidFor(uid, _now())) return session;
    } catch (_) {
      // Data lokal hilang atau rusak harus fail closed.
    }
    await storage.clear();
    return null;
  }

  Future<void> clear() => storage.clear();
}
