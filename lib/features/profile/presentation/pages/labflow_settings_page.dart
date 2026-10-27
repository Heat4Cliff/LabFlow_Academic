import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/app_session_manager.dart';
import '../../../auth/data/auth_service.dart';
import '../widgets/profile_navigation_widgets.dart';

class LabFlowSettingsPage extends StatefulWidget {
  const LabFlowSettingsPage({
    required this.role,
    required this.returnPath,
    this.authService,
    this.sessionManager,
    super.key,
  });

  final String role;
  final String returnPath;
  final AuthService? authService;
  final AppSessionManager? sessionManager;

  @override
  State<LabFlowSettingsPage> createState() => _LabFlowSettingsPageState();
}

class _LabFlowSettingsPageState extends State<LabFlowSettingsPage>
    with WidgetsBindingObserver {
  late final AuthService _authService = widget.authService ?? AuthService();
  late final AppSessionManager _sessionManager =
      widget.sessionManager ?? AppSessionManager.instance;
  late Future<AppSession?> _session;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  void _refresh() {
    _session = _sessionManager.validFor(_authService.currentUid ?? '');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(_refresh);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _logout() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await _authService.signOut();
    } finally {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) => ProfileSubpageScaffold(
    title: 'Pengaturan',
    returnPath: widget.returnPath,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'Keamanan & Sesi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 14),
        FutureBuilder<AppSession?>(
          future: _session,
          builder: (context, snapshot) {
            final session = snapshot.data;
            final sessionText =
                snapshot.connectionState == ConnectionState.waiting
                ? 'Memeriksa sesi...'
                : session == null
                ? 'Sesi tidak aktif'
                : 'Berakhir pukul ${TimeOfDay.fromDateTime(session.expiresAt.toLocal()).format(context)}';
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBCB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sesi login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(sessionText, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 14),
                  const Text(
                    'Durasi sesi: 1 jam sejak login',
                    style: TextStyle(fontSize: 14, color: Color(0xFF4C5545)),
                  ),
                ],
              ),
            );
          },
        ),
        if (widget.role == 'student') ...[
          const SizedBox(height: 24),
          const Text(
            'Akses cepat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          ProfileMenuTile(
            icon: Icons.notifications_outlined,
            title: 'Buka Pusat Notifikasi',
            onTap: () => context.push('/student/notifications'),
          ),
          ProfileMenuTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Buka Scan QR',
            onTap: () => context.push('/student/scanner'),
          ),
        ],
        const SizedBox(height: 30),
        SizedBox(
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _signingOut ? null : _logout,
            icon: const Icon(Icons.logout_rounded, size: 22),
            label: const Text(
              'Keluar sekarang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
