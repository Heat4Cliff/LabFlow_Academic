import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/user_profile.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  /// Login menggunakan Firebase Authentication.
  ///
  /// Setelah kredensial berhasil diverifikasi Firebase,
  /// profil pengguna dibaca dari Firestore berdasarkan UID.
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        throw const AuthServiceException(
          'Firebase tidak mengembalikan data pengguna.',
        );
      }

      final profileDocument = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!profileDocument.exists) {
        await _firebaseAuth.signOut();

        throw const AuthServiceException(
          'Profil akun tidak ditemukan di database.',
        );
      }

      final profile = UserProfile.fromDocument(profileDocument);

      if (!profile.isActive) {
        await _firebaseAuth.signOut();

        throw const AuthServiceException(
          'Akun Anda sedang dinonaktifkan. Hubungi Admin Lab.',
        );
      }

      return profile;
    } on FirebaseAuthException catch (error) {
      throw AuthServiceException(_firebaseMessage(error.code));
    }
  }

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
