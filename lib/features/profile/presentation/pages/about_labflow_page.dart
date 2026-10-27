import 'package:flutter/material.dart';

import '../widgets/profile_navigation_widgets.dart';

class AboutLabFlowPage extends StatelessWidget {
  const AboutLabFlowPage({required this.returnPath, super.key});

  final String returnPath;

  @override
  Widget build(BuildContext context) => ProfileSubpageScaffold(
    title: 'Tentang LabFlow',
    returnPath: returnPath,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Image.asset(
                'assets/branding/labflow_app_icon_1024.png',
                height: 128,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 14),
              const Text(
                'LabFlow',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Laboratory Asset & Service Management System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFFD5DACF)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Tentang aplikasi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        const Text(
          'LabFlow membantu mahasiswa dan pengelola laboratorium melihat aset, '
          'mengelola peminjaman, melaporkan masalah, dan mengikuti tindak lanjutnya.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text(
          'Fitur utama',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            'Inventory',
            'Borrowing',
            'Reporting',
            'Maintenance',
            'Notification',
            'QR Asset',
          ].map((feature) => Chip(label: Text(feature))).toList(),
        ),
        const SizedBox(height: 26),
        const Text(
          'Versi 1.0.0 · Academic Project',
          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
      ],
    ),
  );
}
