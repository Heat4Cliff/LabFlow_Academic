import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// User Firebase yang sedang login.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Login menggunakan Firebase Authentication.
  ///
  /// Setelah email dan password berhasil diverifikasi,
  /// profil pengguna dibaca dari Firestore berdasarkan UID.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return await getCurrentUserProfile();
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_firebaseMessage(error.code));
    }
  }

  /// Membaca profil user yang sedang login dari Firestore.
  ///
  /// Method ini juga digunakan oleh halaman berdasarkan role
  /// supaya akses tidak hanya bergantung pada routing UI.
  Future<UserProfile> getCurrentUserProfile() async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw const AuthServiceException(
        'Sesi login tidak ditemukan. Silakan masuk kembali.',
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
      );
    }

    final profile = UserProfile.fromDocument(profileDocument);

    if (!profile.isActive) {
      await signOut();

      throw const AuthServiceException(
        'Akun Anda sedang dinonaktifkan. Hubungi Admin Lab.',
      );
    }

    return profile;
  }

  /// Keluar dari Firebase Authentication.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  String _firebaseMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid.';

      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';

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

class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
