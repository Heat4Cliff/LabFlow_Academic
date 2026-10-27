import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/session/app_session_manager.dart';
import '../domain/user_profile.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    AppSessionManager? sessionManager,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _sessionManager = sessionManager ?? AppSessionManager.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final AppSessionManager _sessionManager;

  /// User Firebase yang sedang login.
  User? get currentUser => _firebaseAuth.currentUser;
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  /// Login menggunakan Firebase Authentication.
  ///
  /// Setelah email dan password berhasil diverifikasi,
  /// profil pengguna dibaca dari Firestore berdasarkan UID.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Login baru tidak boleh mewarisi timestamp dari percobaan sebelumnya.
      await _sessionManager.clear();
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final profile = await _loadCurrentUserProfile();
      if (!isSupportedRole(profile.role)) {
        await signOut();
        throw const AuthServiceException(
          'Role akun tidak dikenali.',
          code: AuthServiceException.invalidRole,
        );
      }
      try {
        await _sessionManager.start(profile.uid);
      } catch (_) {
        await signOut();
        throw const AuthServiceException(
          'Sesi lokal tidak dapat disimpan. Silakan coba login kembali.',
          code: AuthServiceException.sessionNotFound,
        );
      }
      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(
        _firebaseMessage(error.code),
        code: _firebaseErrorCode(error.code),
      );
    }
  }

  /// Membaca profil user yang sedang login dari Firestore.
  ///
  /// Method ini menjadi pemeriksaan authoritative untuk session,
  /// keberadaan profil, dan status aktif akun.
  ///
  /// Halaman berdasarkan role tetap memanggil method ini agar
  /// akses tidak hanya bergantung pada routing UI.
  Future<UserProfile> getCurrentUserProfile() async {
    await requireValidSession();
    return _loadCurrentUserProfile();
  }

  Future<AppSession> requireValidSession() async {
    final uid = _firebaseAuth.currentUser?.uid;
    if (uid != null) {
      final session = await _sessionManager.validFor(uid);
      if (session != null) return session;
    }
    await signOut();
    throw const AuthServiceException(
      'Sesi Anda telah berakhir. Silakan masuk kembali.',
      code: AuthServiceException.sessionNotFound,
    );
  }

  Future<UserProfile> _loadCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthServiceException(
        'Sesi login tidak ditemukan. Silakan masuk kembali.',
        code: AuthServiceException.sessionNotFound,
      );
    }

    final profileDocument = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!profileDocument.exists) {
      await signOut();

      throw const AuthServiceException(
        'Profil akun tidak ditemukan di database.',
        code: AuthServiceException.profileNotFound,
      );
    }

    final profile = UserProfile.fromDocument(profileDocument);

    if (!profile.isActive) {
      /// Session Firebase langsung diakhiri agar akun suspended
      /// tidak tetap memiliki session aktif pada client.
      await signOut();

      throw const AuthServiceException(
        'Akun Anda sedang dinonaktifkan. Hubungi Admin Lab.',
        code: AuthServiceException.accountSuspended,
      );
    }

    return profile;
  }

  /// Keluar dari Firebase Authentication.
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } finally {
      await _sessionManager.clear();
    }
  }

  static bool isSupportedRole(String role) =>
      role == 'student' || role == 'lab_admin' || role == 'superadmin';

  /// Mengubah kode error Firebase Authentication menjadi kode
  /// domain yang dapat dikenali presentation layer.
  ///
  /// Firebase `user-disabled` dipetakan ke account-suspended
  /// supaya menggunakan state UI yang sama dengan status
  /// suspended pada profil Firestore.
  String _firebaseErrorCode(String code) {
    switch (code) {
      case 'user-disabled':
        return AuthServiceException.accountSuspended;

      default:
        return code;
    }
  }

  /// Pesan aman yang ditampilkan ke pengguna.
  String _firebaseMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid.';

      case 'user-disabled':
        return 'Akun Anda sedang dinonaktifkan. Hubungi Admin Lab.';

      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password tidak sesuai.';

      case 'too-many-requests':
        return 'Terlalu banyak percobaan login. Coba lagi nanti.';

      case 'network-request-failed':
        return 'Tidak dapat terhubung ke internet.';

      default:
        return 'Login gagal. Silakan coba kembali.';
    }
  }
}

/// Exception domain untuk proses authentication LabFlow.
///
/// `code` digunakan oleh presentation layer untuk menentukan
/// state UI tanpa bergantung pada pencocokan isi message.
class AuthServiceException implements Exception {
  const AuthServiceException(this.message, {this.code = unknown});

  /// Kode domain yang digunakan lintas authentication flow.
  static const String sessionNotFound = 'session-not-found';
  static const String profileNotFound = 'profile-not-found';
  static const String accountSuspended = 'account-suspended';
  static const String invalidRole = 'invalid-role';
  static const String unknown = 'unknown';

  final String message;
  final String code;

  /// Memudahkan pemeriksaan kondisi suspended tanpa
  /// membandingkan string message pada presentation layer.
  bool get isAccountSuspended => code == accountSuspended;

  @override
  String toString() => message;
}
