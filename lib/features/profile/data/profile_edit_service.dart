import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_profile.dart';

abstract class ProfileEditor {
  Future<UserProfile> load();
  Future<UserProfile> saveFullName(String fullName);
}

class ProfileEditService implements ProfileEditor {
  ProfileEditService({AuthService? authService, FirebaseFirestore? firestore})
    : _authService = authService ?? AuthService(),
      _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;

  static String? validateFullName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'Nama lengkap wajib diisi.';
    if (clean.length > 100) return 'Nama lengkap maksimal 100 karakter.';
    return null;
  }

  @override
  Future<UserProfile> load() => _authService.getCurrentUserProfile();

  @override
  Future<UserProfile> saveFullName(String fullName) async {
    final error = validateFullName(fullName);
    if (error != null) throw ProfileEditException(error);

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      throw const ProfileEditException('Sesi login tidak ditemukan.');
    }

    try {
      await _firestore.collection('users').doc(uid).update({
        'fullName': fullName.trim(),
      });
      return await _authService.getCurrentUserProfile();
    } on FirebaseException catch (exception) {
      if (exception.code == 'permission-denied') {
        throw const ProfileEditException('Akses ubah profil ditolak.');
      }
      throw const ProfileEditException(
        'Profil tidak dapat disimpan. Periksa koneksi dan coba lagi.',
      );
    }
  }
}

class ProfileEditException implements Exception {
  const ProfileEditException(this.message);
  final String message;
}
