import 'package:shared_preferences/shared_preferences.dart';

/// Menangani preferensi lokal sederhana milik LabFlow.
///
/// Untuk saat ini digunakan untuk mengetahui apakah device sudah pernah
/// menampilkan splash dan menyelesaikan onboarding.
abstract final class AppPreferences {
  static const String _hasSeenSplashKey = 'has_seen_splash';
  static const String _onboardingCompletedKey = 'onboarding_completed';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  /// Mengecek apakah custom splash LabFlow sudah pernah ditampilkan.
  static Future<bool> hasSeenSplash() async {
    return await _preferences.getBool(_hasSeenSplashKey) ?? false;
  }

  /// Menandai custom splash sudah pernah ditampilkan.
  static Future<void> markSplashAsSeen() async {
    await _preferences.setBool(_hasSeenSplashKey, true);
  }

  /// Mengecek apakah onboarding sudah selesai atau dilewati.
  static Future<bool> hasCompletedOnboarding() async {
    return await _preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Menandai onboarding telah selesai.
  static Future<void> markOnboardingAsCompleted() async {
    await _preferences.setBool(_onboardingCompletedKey, true);
  }
}
