import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../firebase_options.dart';
import '../../auth/domain/user_profile.dart';

/// Service khusus Superadmin untuk membaca
/// dan mengelola data pengguna LabFlow.
class UserManagementService {
  UserManagementService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Mengambil seluruh pengguna LabFlow secara realtime.
  Stream<List<UserProfile>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map(UserProfile.fromDocument).toList();

      users.sort(
        (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
      );

      return users;
    });
  }

  /// Membuat akun Firebase Authentication baru tanpa
  /// mengganti session Firebase milik Superadmin.
  ///
  /// Proses:
  /// 1. Membuat Firebase App secondary.
  /// 2. Membuat akun menggunakan secondary Auth.
  /// 3. Mendapatkan UID Firebase Authentication.
  /// 4. Membuat profile users/{uid} di Firestore.
  /// 5. Menutup secondary session.
  Future<UserProfile> createUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String status,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw const UserManagementException('Nama pengguna wajib diisi.');
    }

    if (!_allowedRoles.contains(role)) {
      throw const UserManagementException('Role pengguna tidak valid.');
    }

    if (!_allowedStatuses.contains(status)) {
      throw const UserManagementException('Status pengguna tidak valid.');
    }

    FirebaseApp? secondaryApp;
    FirebaseAuth? secondaryAuth;
    User? createdAuthUser;

    try {
      /// Menggunakan nama unik agar secondary Firebase App
      /// tidak berbenturan dengan proses sebelumnya.
      final secondaryAppName =
          'user-provisioning-${DateTime.now().microsecondsSinceEpoch}';

      secondaryApp = await Firebase.initializeApp(
        name: secondaryAppName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      /// Membuat user pada Firebase Authentication.
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      createdAuthUser = credential.user;

      if (createdAuthUser == null) {
        throw const UserManagementException(
          'Firebase tidak mengembalikan data akun baru.',
        );
      }

      final uid = createdAuthUser.uid;

      /// Profile aplikasi disimpan menggunakan UID yang sama
      /// dengan Firebase Authentication.
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': cleanEmail,
        'fullName': cleanName,
        'role': role,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return UserProfile(
        uid: uid,
        email: cleanEmail,
        fullName: cleanName,
        role: role,
        status: status,
      );
    } on FirebaseAuthException catch (error) {
      throw UserManagementException(_firebaseAuthMessage(error.code));
    } on FirebaseException catch (error) {
      /// Jika Authentication berhasil tetapi Firestore gagal,
      /// usahakan hapus akun Auth agar tidak menjadi orphan.
      if (createdAuthUser != null) {
        try {
          await createdAuthUser.delete();
        } catch (_) {
          // Cleanup bersifat best-effort.
        }
      }

      throw UserManagementException(
        'Gagal menyimpan profil pengguna: '
        '${error.message ?? error.code}',
      );
    } on UserManagementException {
      rethrow;
    } catch (_) {
      if (createdAuthUser != null) {
        try {
          await createdAuthUser.delete();
        } catch (_) {
          // Cleanup bersifat best-effort.
        }
      }

      throw const UserManagementException(
        'Terjadi kesalahan saat membuat pengguna.',
      );
    } finally {
      /// Secondary Auth selalu ditutup.
      if (secondaryAuth != null) {
        try {
          await secondaryAuth.signOut();
        } catch (_) {
          // Cleanup bersifat best-effort.
        }
      }

      /// Firebase App secondary juga dihapus setelah selesai.
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete();
        } catch (_) {
          // Cleanup bersifat best-effort.
        }
      }
    }
  }

  /// Role yang boleh dibuat melalui halaman User Management.
  ///
  /// Superadmin baru sengaja tidak bisa dibuat dari form umum.
  static const Set<String> _allowedRoles = {'student', 'lab_admin'};

  static const Set<String> _allowedStatuses = {'active', 'suspended'};

  String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email tersebut sudah digunakan oleh akun lain.';

      case 'invalid-email':
        return 'Format email tidak valid.';

      case 'weak-password':
        return 'Password terlalu lemah.';

      case 'network-request-failed':
        return 'Tidak dapat terhubung ke Firebase. '
            'Periksa koneksi internet.';

      case 'too-many-requests':
        return 'Terlalu banyak percobaan. '
            'Silakan coba kembali nanti.';

      default:
        return 'Gagal membuat akun pengguna.';
    }
  }
}

/// Exception khusus proses User Management agar pesan
/// error dapat ditampilkan dengan jelas pada UI.
class UserManagementException implements Exception {
  const UserManagementException(this.message);

  final String message;

  @override
  String toString() => message;
}
