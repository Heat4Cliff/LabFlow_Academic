import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/connectivity/connectivity_service.dart';
import '../../asset/data/asset_image_service.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_profile.dart';

abstract class ProfileEditor {
  Future<UserProfile> load();
  Future<UserProfile> saveProfile({
    required String fullName,
    required String phoneNumber,
    XFile? photo,
    bool removePhoto = false,
  });
}

class ProfileEditService implements ProfileEditor {
  ProfileEditService({AuthService? authService, FirebaseFirestore? firestore})
    : _authService = authService ?? AuthService(),
      _firestore = firestore ?? FirebaseFirestore.instance;

  final AuthService _authService;
  final FirebaseFirestore _firestore;
  final AssetImageService _images = AssetImageService();
  final ConnectivityService _connectivity = PluginConnectivityService();

  static String? validateFullName(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return 'Nama lengkap wajib diisi.';
    if (clean.length > 100) return 'Nama lengkap maksimal 100 karakter.';
    return null;
  }

  static String? validatePhoneNumber(String value) =>
      value.trim().length > 20 ? 'Nomor HP maksimal 20 karakter.' : null;

  @override
  Future<UserProfile> load() => _authService.getCurrentUserProfile();

  @override
  Future<UserProfile> saveProfile({
    required String fullName,
    required String phoneNumber,
    XFile? photo,
    bool removePhoto = false,
  }) async {
    final error = validateFullName(fullName);
    if (error != null) throw ProfileEditException(error);
    final phoneError = validatePhoneNumber(phoneNumber);
    if (phoneError != null) throw ProfileEditException(phoneError);

    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      throw const ProfileEditException('Sesi login tidak ditemukan.');
    }

    try {
      final update = <String, Object?>{
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim().isEmpty ? null : phoneNumber.trim(),
      };
      if (photo != null) {
        if (!await _connectivity.hasNetworkInterface()) {
          throw const ProfileEditException(
            'Foto membutuhkan koneksi internet.',
          );
        }
        update['profilePhotoUrl'] = (await _images.uploadImage(
          image: photo,
          folder: 'labflow/profiles/$uid',
          maximumBytes: 5 * 1024 * 1024,
        )).secureUrl;
      } else if (removePhoto) {
        update['profilePhotoUrl'] = null;
      }
      await _firestore.collection('users').doc(uid).update(update);
      return await _authService.getCurrentUserProfile();
    } on AssetImageException catch (error) {
      throw ProfileEditException(error.message);
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
