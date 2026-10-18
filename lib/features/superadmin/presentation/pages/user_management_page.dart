import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/user_management_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final UserManagementService _userService = UserManagementService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        title: const Text(
          'Manajemen Pengguna',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _userService.watchUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildUserCard(users[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateUser,
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'Tambah User',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Membuka halaman pembuatan pengguna baru.
  ///
  /// Jika pembuatan berhasil, halaman Create User
  /// mengembalikan nilai true.
  Future<void> _openCreateUser() async {
    final created = await context.push<bool>('/superadmin/users/create');

    if (!mounted) return;

    if (created == true) {
      _showMessage('Pengguna berhasil dibuat.');
    }
  }

  /// Membuka halaman Edit User berdasarkan UID Firebase.
  ///
  /// Result dari halaman Edit digunakan untuk menentukan
  /// feedback yang ditampilkan pada halaman ini.
  Future<void> _openEditUser(UserProfile user) async {
    final result = await context.push<String>(
      '/superadmin/users/${user.uid}/edit',
    );

    if (!mounted) return;

    switch (result) {
      case 'updated':
        _showMessage('Pengguna berhasil diperbarui.');
        break;

      case 'suspended':
        _showMessage('Pengguna berhasil dinonaktifkan.');
        break;

      case 'activated':
        _showMessage('Pengguna berhasil diaktifkan kembali.');
        break;
    }
  }

  /// Card pengguna.
  ///
  /// Seluruh card dapat ditekan untuk membuka halaman Edit User.
  Widget _buildUserCard(UserProfile user) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        _openEditUser(user);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E6DC)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFEAFBCB),
              foregroundColor: const Color(0xFF111111),
              child: Text(
                _initial(user.fullName),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName.isEmpty ? 'Tanpa Nama' : user.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        _roleLabel(user.role),
                        const Color(0xFFEAFBCB),
                      ),
                      _buildBadge(
                        user.isActive ? 'Aktif' : 'Suspended',
                        user.isActive
                            ? const Color(0xFFE5F6EC)
                            : const Color(0xFFFFE8E8),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            /// Petunjuk visual bahwa card dapat dibuka
            /// untuk melihat dan mengubah pengguna.
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF111111)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111111),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline_rounded, size: 60),
            SizedBox(height: 16),
            Text(
              'Belum ada pengguna',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              'Data pengguna Firebase akan muncul di sini.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat pengguna',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  /// Feedback untuk operasi Create, Update,
  /// Suspend, maupun Activate.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _initial(String name) {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return '?';
    }

    return trimmed.substring(0, 1).toUpperCase();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'superadmin':
        return 'Superadmin';

      case 'lab_admin':
        return 'Lab Admin';

      case 'student':
        return 'Student';

      default:
        return role;
    }
  }
}
