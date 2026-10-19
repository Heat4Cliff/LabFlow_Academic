import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/states/labflow_access_denied_state.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../../shared/presentation/states/labflow_suspended_account_state.dart';
import '../../data/auth_service.dart';
import '../../domain/user_profile.dart';

/// Gate untuk memastikan protected route hanya dibuka setelah
/// session, status akun, dan role berhasil diverifikasi.
///
/// Jika [requiredRole] tidak diberikan, gate hanya memeriksa
/// session dan status aktif akun.
class LabFlowAccountStatusGate extends StatefulWidget {
  const LabFlowAccountStatusGate({
    required this.child,
    this.requiredRole,
    super.key,
  });

  final Widget child;
  final String? requiredRole;

  @override
  State<LabFlowAccountStatusGate> createState() =>
      _LabFlowAccountStatusGateState();
}

class _LabFlowAccountStatusGateState extends State<LabFlowAccountStatusGate> {
  final AuthService _authService = AuthService();

  late Future<UserProfile> _profileFuture;

  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUserProfile();
  }

  void _retry() {
    setState(() {
      _redirectScheduled = false;
      _profileFuture = _authService.getCurrentUserProfile();
    });
  }

  void _redirectToLogin() {
    if (_redirectScheduled) {
      return;
    }

    _redirectScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.go('/login');
    });
  }

  Future<void> _goToOwnHome(UserProfile profile) async {
    switch (profile.role) {
      case 'superadmin':
        context.go('/superadmin');
        return;

      case 'lab_admin':
        context.go('/lab-admin');
        return;

      case 'student':
        context.go('/student');
        return;

      default:
        await _authService.signOut();

        if (!mounted) {
          return;
        }

        context.go('/login');
    }
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
        return 'pengguna';
    }
  }

  Widget _buildPageState(Widget child) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      body: SafeArea(child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildPageState(
            const LabFlowLoadingState(
              title: 'Memeriksa sesi',
              message: 'Memastikan akun Anda masih dapat mengakses LabFlow.',
            ),
          );
        }

        if (snapshot.hasError) {
          final error = snapshot.error;

          if (error is AuthServiceException) {
            if (error.isAccountSuspended) {
              return _buildPageState(
                LabFlowSuspendedAccountState(
                  onAction: () {
                    context.go('/login');
                  },
                ),
              );
            }

            if (error.code == AuthServiceException.sessionNotFound ||
                error.code == AuthServiceException.profileNotFound) {
              _redirectToLogin();

              return _buildPageState(
                const LabFlowLoadingState(
                  title: 'Sesi berakhir',
                  message: 'Mengalihkan Anda ke halaman login.',
                ),
              );
            }
          }

          return _buildPageState(
            LabFlowConnectionErrorState(
              title: 'Sesi tidak dapat diverifikasi',
              message:
                  'LabFlow mengalami kendala saat memeriksa akun Anda. '
                  'Periksa koneksi lalu coba lagi.',
              onRetry: _retry,
            ),
          );
        }

        final profile = snapshot.data;

        if (profile == null) {
          _redirectToLogin();

          return _buildPageState(
            const LabFlowLoadingState(
              title: 'Sesi tidak tersedia',
              message: 'Mengalihkan Anda ke halaman login.',
            ),
          );
        }

        final requiredRole = widget.requiredRole;

        if (requiredRole != null && profile.role != requiredRole) {
          return _buildPageState(
            LabFlowAccessDeniedState(
              title: 'Akses ditolak',
              message:
                  'Akun ${_roleLabel(profile.role)} tidak memiliki izin '
                  'untuk mengakses area ${_roleLabel(requiredRole)}.',
              actionLabel: 'Ke Halaman Saya',
              onAction: () {
                _goToOwnHome(profile);
              },
            ),
          );
        }

        return widget.child;
      },
    );
  }
}
