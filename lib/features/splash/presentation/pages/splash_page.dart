import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/app_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    _continueFromSplash();
  }

  /// Menampilkan splash LabFlow pada first launch,
  /// kemudian melanjutkan ke onboarding.
  Future<void> _continueFromSplash() async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    // Menandai bahwa splash sudah pernah ditampilkan
    // pada device ini.
    await AppPreferences.markSplashAsSeen();

    if (!mounted) return;

    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB9F33D),
      body: SafeArea(
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash/splash_labflow.png',
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
