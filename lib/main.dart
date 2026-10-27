import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/session/session_startup_service.dart';
import 'core/storage/app_preferences.dart';
import 'features/auth/data/auth_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Menghubungkan aplikasi Flutter dengan project Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Native Android/iOS Firestore persistence is on by default; keep it explicit
  // so offline cached reads and safe SDK writes remain enabled.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  /// Mengecek status first-launch pada device.
  final hasSeenSplash = await AppPreferences.hasSeenSplash();
  final hasCompletedOnboarding = await AppPreferences.hasCompletedOnboarding();

  late final String initialLocation;

  if (!hasSeenSplash) {
    initialLocation = '/splash';
  } else if (!hasCompletedOnboarding) {
    initialLocation = '/onboarding';
  } else {
    initialLocation = await SessionStartupService(AuthService()).restoreRoute();
  }

  runApp(LabFlowApp(initialLocation: initialLocation));
}
