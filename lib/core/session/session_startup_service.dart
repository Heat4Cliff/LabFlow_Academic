import '../../features/auth/data/auth_service.dart';

/// Memulihkan tujuan awal dari Auth dan profil Firestore, bukan role lokal.
class SessionStartupService {
  SessionStartupService(this._authService);

  final AuthService _authService;

  Future<String> restoreRoute() async {
    if (_authService.currentUid == null) {
      await _safeSignOut();
      return '/login';
    }

    try {
      final profile = await _authService.getCurrentUserProfile();
      switch (profile.role) {
        case 'student':
          return '/student';
        case 'lab_admin':
          return '/lab-admin';
        case 'superadmin':
          return '/superadmin';
        default:
          await _safeSignOut();
          return '/login';
      }
    } catch (_) {
      // Termasuk sesi hilang/rusak/kedaluwarsa dan profil yang tidak valid.
      await _safeSignOut();
      return '/login';
    }
  }

  Future<void> _safeSignOut() async {
    try {
      await _authService.signOut();
    } catch (_) {
      // Route tetap fail closed; protected gate akan memeriksa ulang sesi.
    }
  }
}
