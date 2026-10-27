import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_access_denied_state.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../../shared/presentation/states/labflow_suspended_account_state.dart';
import '../../../asset/data/asset_service.dart';
import '../../../asset/domain/laboratory_asset.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../maintenance/data/maintenance_service.dart';
import '../../../maintenance/domain/maintenance_record.dart';
import '../widgets/lab_admin_bottom_navigation.dart';

class LabAdminDashboardPage extends StatefulWidget {
  const LabAdminDashboardPage({super.key});

  @override
  State<LabAdminDashboardPage> createState() => _LabAdminDashboardPageState();
}

class _LabAdminDashboardPageState extends State<LabAdminDashboardPage> {
  static const Color _paper = Color(0xFFF6F9EF);
  static const Color _ink = Color(0xFF111111);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _line = Color(0xFFDDE2D5);
  static const Color _lime = Color(0xFFB9F33D);
  static const Color _softLime = Color(0xFFEAFBCB);

  final AuthService _authService = AuthService();
  final LabMembershipService _membershipService = LabMembershipService();
  final AssetService _assetService = AssetService();
  final MaintenanceService _maintenanceService = MaintenanceService();

  late Future<UserProfile> _profileFuture;
  String? _selectedLabId;

  @override
  void initState() {
    super.initState();
    _profileFuture = _authService.getCurrentUserProfile();
  }

  Future<void> _goToOwnHome(UserProfile profile) async {
    switch (profile.role) {
      case 'superadmin':
        context.go('/superadmin');
        return;
      case 'student':
        context.go('/student');
        return;
      case 'lab_admin':
        context.go('/lab-admin');
        return;
      default:
        await _authService.signOut();

        if (!mounted) {
          return;
        }

        context.go('/login');
    }
  }

  Future<void> _createAsset() async {
    final created = await context.push<bool>('/lab-admin/assets/create');

    if (!mounted || created != true) {
      return;
    }

    showLabFlowNotification(
      context: context,
      title: 'Aset berhasil dibuat',
      message: 'Aset baru berhasil ditambahkan ke inventaris laboratorium.',
      type: LabFlowNotificationType.success,
    );
  }

  String _resolveSelectedLabId(List<Laboratory> laboratories) {
    final current = _selectedLabId;

    if (current != null &&
        laboratories.any((laboratory) => laboratory.id == current)) {
      return current;
    }

    return laboratories.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<UserProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LabFlowLoadingState(
                title: 'Memuat dashboard',
                message: 'Menyiapkan data akun Lab Admin.',
              );
            }

            if (snapshot.hasError) {
              final error = snapshot.error;

              if (error is AuthServiceException && error.isAccountSuspended) {
                return LabFlowSuspendedAccountState(
                  onAction: () {
                    context.go('/login');
                  },
                );
              }

              return const LabFlowConnectionErrorState(
                title: 'Dashboard tidak dapat dimuat',
                message:
                    'Data akun Lab Admin tidak dapat diambil saat ini. '
                    'Periksa koneksi Anda lalu coba lagi.',
              );
            }

            final profile = snapshot.data;

            if (profile == null) {
              return _buildErrorState('Profil pengguna tidak ditemukan.');
            }

            if (!profile.isLabAdmin) {
              return LabFlowAccessDeniedState(
                title: 'Akses Lab Admin ditolak',
                message:
                    'Akun ini tidak memiliki role Lab Admin sehingga '
                    'tidak dapat mengakses halaman Lab Admin.',
                actionLabel: 'Ke Halaman Saya',
                onAction: () {
                  _goToOwnHome(profile);
                },
              );
            }

            return _buildMembershipContent(profile);
          },
        ),
      ),
      bottomNavigationBar: const LabAdminBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildMembershipContent(UserProfile profile) {
    return StreamBuilder<List<LabMembership>>(
      stream: _membershipService.watchCurrentLabAdminMemberships(),
      builder: (context, membershipSnapshot) {
        if (membershipSnapshot.connectionState == ConnectionState.waiting &&
            !membershipSnapshot.hasData) {
          return const LabFlowLoadingState(
            title: 'Memuat laboratorium',
            message: 'Memeriksa assignment laboratorium Anda.',
          );
        }

        if (membershipSnapshot.hasError) {
          return const LabFlowConnectionErrorState(
            title: 'Assignment tidak dapat dimuat',
            message:
                'Akses laboratorium tidak dapat diperiksa saat ini. '
                'Periksa koneksi Anda lalu coba lagi.',
          );
        }

        final memberships = membershipSnapshot.data ?? <LabMembership>[];

        if (memberships.isEmpty) {
          return _buildNoMembershipState();
        }

        return StreamBuilder<List<Laboratory>>(
          stream: _membershipService.watchActiveLaboratories(),
          builder: (context, laboratorySnapshot) {
            if (laboratorySnapshot.connectionState == ConnectionState.waiting &&
                !laboratorySnapshot.hasData) {
              return const LabFlowLoadingState(
                title: 'Memuat laboratorium',
                message: 'Menyiapkan laboratorium aktif Anda.',
              );
            }

            if (laboratorySnapshot.hasError) {
              return const LabFlowConnectionErrorState(
                title: 'Laboratorium tidak dapat dimuat',
                message:
                    'Data laboratorium tidak dapat diambil saat ini. '
                    'Periksa koneksi Anda lalu coba lagi.',
              );
            }

            final membershipLabIds = memberships
                .map((membership) => membership.labId)
                .toSet();

            final laboratories =
                (laboratorySnapshot.data ?? <Laboratory>[])
                    .where(
                      (laboratory) => membershipLabIds.contains(laboratory.id),
                    )
                    .toList()
                  ..sort(
                    (a, b) =>
                        a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                  );

            if (laboratories.isEmpty) {
              return _buildNoActiveLaboratoryState();
            }

            final selectedLabId = _resolveSelectedLabId(laboratories);
            final selectedLaboratory = laboratories.firstWhere(
              (laboratory) => laboratory.id == selectedLabId,
            );

            return StreamBuilder<List<LaboratoryAsset>>(
              stream: _assetService.watchAssetsByLaboratory(selectedLabId),
              builder: (context, assetSnapshot) {
                if (assetSnapshot.connectionState == ConnectionState.waiting &&
                    !assetSnapshot.hasData) {
                  return const LabFlowLoadingState(
                    title: 'Memuat ringkasan',
                    message: 'Menyiapkan statistik inventaris laboratorium.',
                  );
                }

                if (assetSnapshot.hasError) {
                  return const LabFlowConnectionErrorState(
                    title: 'Ringkasan tidak dapat dimuat',
                    message:
                        'Statistik aset tidak dapat diambil saat ini. '
                        'Periksa koneksi Anda lalu coba lagi.',
                  );
                }

                return StreamBuilder<List<MaintenanceRecord>>(
                  stream: _maintenanceService.watchByLaboratory(selectedLabId),
                  builder: (context, maintenanceSnapshot) {
                    if (maintenanceSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !maintenanceSnapshot.hasData) {
                      return const LabFlowLoadingState(
                        title: 'Memuat maintenance',
                        message: 'Menyiapkan antrean maintenance laboratorium.',
                      );
                    }

                    if (maintenanceSnapshot.hasError) {
                      return const LabFlowConnectionErrorState(
                        title: 'Maintenance tidak dapat dimuat',
                        message:
                            'Ringkasan maintenance tidak dapat diambil saat ini. '
                            'Periksa koneksi Anda lalu coba lagi.',
                      );
                    }

                    return _buildDashboard(
                      profile: profile,
                      laboratories: laboratories,
                      selectedLaboratory: selectedLaboratory,
                      assets: assetSnapshot.data ?? <LaboratoryAsset>[],
                      maintenanceRecords:
                          maintenanceSnapshot.data ?? <MaintenanceRecord>[],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard({
    required UserProfile profile,
    required List<Laboratory> laboratories,
    required Laboratory selectedLaboratory,
    required List<LaboratoryAsset> assets,
    required List<MaintenanceRecord> maintenanceRecords,
  }) {
    final total = assets.length;
    final available = assets
        .where((asset) => asset.status == 'available')
        .length;
    final borrowed = assets.where((asset) => asset.status == 'borrowed').length;
    final maintenanceAssets = assets
        .where((asset) => asset.status == 'maintenance')
        .length;
    final openMaintenance = maintenanceRecords
        .where(
          (record) =>
              record.status == 'pending' || record.status == 'in_progress',
        )
        .length;
    final readiness = total == 0 ? 0.0 : available / total;

    return RefreshIndicator(
      onRefresh: () async {
        final refreshedProfile = _authService.getCurrentUserProfile();
        setState(() => _profileFuture = refreshedProfile);
        try {
          await refreshedProfile;
        } catch (_) {
          // Error ditampilkan oleh FutureBuilder setelah rebuild.
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lab Admin',
                        style: TextStyle(
                          fontSize: 30,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Semantics(
                        label: profile.fullName,
                        child: Text(
                          selectedLaboratory.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, color: _muted),
                        ),
                      ),
                    ],
                  ),
                ),
                ClipOval(
                  child: profile.profilePhotoUrl?.isNotEmpty == true
                      ? Image.network(
                          profile.profilePhotoUrl!,
                          width: 42,
                          height: 42,
                          cacheWidth: 126,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _adminAvatarFallback(profile.fullName),
                        )
                      : _adminAvatarFallback(profile.fullName),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _lime,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Aset',
                          style: TextStyle(fontSize: 14, color: _ink),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 54,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _summaryMetric('$available', 'Tersedia'),
                            ),
                            Expanded(
                              child: _summaryMetric('$borrowed', 'Dipinjam'),
                            ),
                            Expanded(
                              child: _summaryMetric(
                                '$maintenanceAssets',
                                'Maintenance',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 84,
                          height: 84,
                          child: CircularProgressIndicator(
                            value: readiness,
                            strokeWidth: 11,
                            backgroundColor: const Color(0xFF1E4D72),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              _ink,
                            ),
                          ),
                        ),
                        Text(
                          '${(readiness * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.add_rounded,
                    label: 'Tambah Aset',
                    badge: null,
                    onTap: _createAsset,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.handshake_outlined,
                    label: 'Proses Pinjaman',
                    badge: null,
                    onTap: () => context.go('/lab-admin/borrowing'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.assignment_outlined,
                    label: 'Laporan',
                    badge: null,
                    onTap: () => context.go('/lab-admin/reports'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.build_outlined,
                    label: 'Maintenance',
                    badge: openMaintenance == 0 ? null : '$openMaintenance',
                    onTap: () => context.go('/lab-admin/maintenance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeader('Perlu ditangani'),
            const SizedBox(height: 8),
            _attentionRow(
              icon: Icons.handshake_outlined,
              title: 'Permintaan Peminjaman',
              badge: 'Tinjau',
              badgeColor: const Color(0xFFFFE8C4),
              badgeText: const Color(0xFFA56600),
              onTap: () => context.go('/lab-admin/borrowing'),
            ),
            _attentionRow(
              icon: Icons.assignment_outlined,
              title: 'Laporan Terbuka',
              badge: 'Buka',
              badgeColor: const Color(0xFFFCE2DF),
              badgeText: const Color(0xFFD14334),
              onTap: () => context.go('/lab-admin/reports'),
            ),
            _attentionRow(
              icon: Icons.build_outlined,
              title: 'Maintenance Aktif',
              badge: '$openMaintenance aset',
              badgeColor: const Color(0xFFDDEAFE),
              badgeText: const Color(0xFF2C5CA8),
              onTap: () => context.go('/lab-admin/maintenance'),
            ),
            if (laboratories.length > 1) ...[
              const SizedBox(height: 16),
              _buildMembershipNote(laboratories.length),
            ],
          ],
        ),
      ),
    );
  }

  Widget _adminAvatarFallback(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    final initials = parts.isEmpty
        ? 'LA'
        : parts.length == 1
        ? parts.first.substring(0, 1).toUpperCase()
        : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      color: _lime,
      child: Text(
        initials,
        style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
      ),
    );
  }

  Widget _summaryMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: _ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          style: const TextStyle(fontSize: 11, color: _ink),
        ),
      ],
    );
  }

  Widget _attentionRow({
    required IconData icon,
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: _ink),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: badgeText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required String? badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 108),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: _softLime,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: _ink),
                  ),
                  if (badge != null)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _ink,
                          borderRadius: BorderRadius.all(Radius.circular(999)),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipNote(int laboratoryCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softLime,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.admin_panel_settings_outlined, color: _ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              laboratoryCount == 1
                  ? 'Akses dashboard mengikuti 1 membership laboratorium aktif yang diberikan oleh Superadmin.'
                  : 'Anda memiliki akses ke $laboratoryCount laboratorium aktif. Gunakan pemilih laboratorium pada kartu di atas untuk berpindah konteks.',
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.25,
        color: _ink,
      ),
    );
  }

  Widget _buildNoMembershipState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_late_outlined, size: 60, color: _muted),
            SizedBox(height: 18),
            Text(
              'Belum ada assignment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Akun Lab Admin ini belum memiliki membership laboratorium aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoActiveLaboratoryState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 60, color: _muted),
            SizedBox(height: 18),
            Text(
              'Laboratorium tidak tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Assignment ditemukan, tetapi tidak ada laboratorium aktif yang dapat ditampilkan.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.45, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted),
        ),
      ),
    );
  }
}
