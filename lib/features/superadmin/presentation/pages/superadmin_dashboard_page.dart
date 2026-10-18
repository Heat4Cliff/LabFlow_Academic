import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_service.dart';

class SuperadminDashboardPage extends StatelessWidget {
  const SuperadminDashboardPage({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();

    if (!context.mounted) return;

    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        title: const Text(
          'Superadmin',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dashboard Superadmin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Kelola pengguna, laboratorium, dan konfigurasi global LabFlow.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),

              const SizedBox(height: 24),

              /// Menu Manajemen Pengguna.
              _buildMenuCard(
                context: context,
                icon: Icons.people_outline_rounded,
                title: 'Manajemen Pengguna',
                description: 'Lihat dan kelola akun LabFlow.',
                onTap: () {
                  context.push('/superadmin/users');
                },
              ),

              const SizedBox(height: 12),

              /// Menu Manajemen Laboratorium.
              _buildMenuCard(
                context: context,
                icon: Icons.science_outlined,
                title: 'Manajemen Laboratorium',
                description: 'Kelola data dan konfigurasi laboratorium.',
                onTap: () {
                  context.push('/superadmin/labs');
                },
              ),

              const SizedBox(height: 12),
              _buildMenuCard(
                context: context,
                icon: Icons.link_rounded,
                title: 'Membership Laboratorium',
                description: 'Hubungkan Lab Admin dengan laboratorium.',
                onTap: () {
                  context.push('/superadmin/memberships');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Card menu reusable agar tampilan menu Superadmin
  /// tetap konsisten dan tidak mengulang banyak kode.
  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E6DC)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFB9F33D),
              foregroundColor: const Color(0xFF111111),
              child: Icon(icon),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            const Icon(Icons.chevron_right_rounded, color: Color(0xFF111111)),
          ],
        ),
      ),
    );
  }
}
