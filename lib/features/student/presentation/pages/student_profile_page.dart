import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import '../cubit/student_data_state.dart';
import '../cubit/student_profile_cubit.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_ui.dart';

class StudentProfilePage extends StatelessWidget {
  const StudentProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StudentProfileCubit(StudentService())..load(),
      child: const _StudentProfileView(),
    );
  }
}

class _StudentProfileView extends StatelessWidget {
  const _StudentProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      bottomNavigationBar: const StudentBottomNavigation(currentIndex: 4),
      body: SafeArea(
        bottom: false,
        child:
            BlocBuilder<StudentProfileCubit, StudentDataState<StudentProfile>>(
              builder: (context, state) {
                if (state.status == StudentLoadStatus.initial ||
                    state.status == StudentLoadStatus.loading) {
                  return const StudentLoading(
                    message: 'Memuat profil mahasiswa.',
                  );
                }
                if (state.status == StudentLoadStatus.failure ||
                    state.data == null) {
                  return StudentErrorState(
                    message: state.errorMessage,
                    onRetry: context.read<StudentProfileCubit>().load,
                  );
                }
                return _content(context, state.data!);
              },
            ),
      ),
    );
  }

  Widget _content(BuildContext context, StudentProfile profile) {
    return RefreshIndicator(
      onRefresh: context.read<StudentProfileCubit>().load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: [
          const StudentPageTitle(title: 'Profil'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: studentSoftLime,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: studentSoftLime,
                    shape: BoxShape.circle,
                    border: Border.all(color: studentInk),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Student',
                          style: TextStyle(fontSize: 8, color: studentMuted),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        profile.email,
                        style: const TextStyle(
                          fontSize: 9,
                          color: studentMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _menu(
            Icons.manage_accounts_outlined,
            'Edit Profil',
            onTap: () async {
              final updated = await context.push<bool>('/student/profile/edit');
              if (updated == true && context.mounted) {
                await context.read<StudentProfileCubit>().load();
              }
            },
          ),
          _menu(Icons.menu_book_outlined, 'Panduan Aplikasi'),
          _menu(Icons.tune_rounded, 'Pengaturan'),
          _menu(Icons.science_outlined, 'Tentang LabFlow'),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await _confirmLogout(context);
                if (confirmed != true || !context.mounted) return;
                await context.read<StudentProfileCubit>().signOut();
                if (!context.mounted) return;
                context.go('/login');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: studentInk,
                side: const BorderSide(color: studentBorder),
                backgroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text(
                'Keluar',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'LabFlow · Versi 1.0.0',
              style: TextStyle(fontSize: 9, color: studentMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menu(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: studentBorder)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: studentInk),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12))),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Keluar dari LabFlow?'),
        content: const Text(
          'Anda perlu masuk kembali untuk mengakses layanan laboratorium.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Tetap di Sini'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: studentPinkText,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
