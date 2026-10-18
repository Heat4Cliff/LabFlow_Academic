import 'package:flutter/material.dart';

import 'router/app_router.dart';
import 'theme/app_theme.dart';

class LabFlowApp extends StatelessWidget {
  const LabFlowApp({required this.initialLocation, super.key});

  final String initialLocation;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LabFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: createAppRouter(initialLocation: initialLocation),
    );
  }
}
