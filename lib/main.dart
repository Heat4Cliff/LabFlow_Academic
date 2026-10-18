import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/storage/app_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Menghubungkan aplikasi Flutter dengan project Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// Mengecek status first-launch pada device.
  final hasSeenSplash = await AppPreferences.hasSeenSplash();
  final hasCompletedOnboarding = await AppPreferences.hasCompletedOnboarding();

  late final String initialLocation;

  if (!hasSeenSplash) {
    initialLocation = '/splash';
  } else if (!hasCompletedOnboarding) {
    initialLocation = '/onboarding';
  } else {
    initialLocation = '/login';
  }

  runApp(ProviderScope(child: LabFlowApp(initialLocation: initialLocation)));
}
