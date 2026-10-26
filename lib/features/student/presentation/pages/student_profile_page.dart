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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 34),
        children: [
          const StudentPageTitle(title: 'Profil'),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: studentInk,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: studentLime,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: studentInk,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student',
                        style: TextStyle(
                          color: Color(0xFFB8BCB3),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _info('Email', profile.email),
          const SizedBox(height: 10),
          _info(
            'Status Akun',
            profile.status == 'active' ? 'Aktif' : profile.status,
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await _confirmLogout(context);

                if (confirmed != true || !context.mounted) {
                  return;
                }

                await context.read<StudentProfileCubit>().signOut();

                if (!context.mounted) return;
                context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Keluar dari Akun',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB42318),
                side: const BorderSide(color: Color(0xFFB42318)),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: studentMuted, fontSize: 12),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmLogout(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: studentPaper,
          title: const Text('Keluar dari akun?'),
          content: const Text('Sesi Student pada perangkat ini akan diakhiri.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB42318),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }
}
