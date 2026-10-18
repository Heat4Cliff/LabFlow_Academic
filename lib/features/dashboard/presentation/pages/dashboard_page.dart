import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dashboard sementara untuk memastikan alur navigasi aplikasi bekerja.
///
/// Dashboard final nantinya akan berbeda berdasarkan role pengguna.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabFlow'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () {
              // Logout asli akan ditambahkan ketika Firebase Auth
              // sudah terintegrasi.
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Foundation LabFlow berhasil dijalankan.'),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Riverpod, GoRouter, dan theme LabFlow siap digunakan.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
