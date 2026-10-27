import 'package:flutter/material.dart';

import '../../../../shared/presentation/navigation/labflow_back_fallback.dart';

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDDE2D5))),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF111111)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 24),
        ],
      ),
    ),
  );
}

class ProfileSubpageScaffold extends StatelessWidget {
  const ProfileSubpageScaffold({
    required this.title,
    required this.returnPath,
    required this.child,
    super.key,
  });

  final String title;
  final String returnPath;
  final Widget child;

  @override
  Widget build(BuildContext context) => LabFlowBackFallback(
    fallbackPath: returnPath,
    child: Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        title: Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          tooltip: 'Kembali',
          icon: const Icon(Icons.arrow_back_rounded, size: 25),
          onPressed: () => popOrGo(context, returnPath),
        ),
      ),
      body: SafeArea(child: child),
    ),
  );
}
