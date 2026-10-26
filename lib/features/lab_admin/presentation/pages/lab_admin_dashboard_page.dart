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

  String _firstName(String fullName) {
    final cleanName = fullName.trim();
    if (cleanName.isEmpty) {
      return 'Lab Admin';
    }

    return cleanName.split(RegExp(r'\s+')).first;
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
    final damaged = assets
        .where((asset) => asset.condition == 'damaged')
        .length;
    final minorDamage = assets
        .where((asset) => asset.condition == 'minor_damage')
        .length;
    final inactive = assets.where((asset) => asset.status == 'inactive').length;

    final readiness = total == 0 ? 0.0 : available / total;

    return RefreshIndicator(
      onRefresh: () async {
        final refreshedProfile = _authService.getCurrentUserProfile();

        setState(() {
          _profileFuture = refreshedProfile;
        });

        try {
          await refreshedProfile;
        } catch (_) {
          // Error ditampilkan oleh FutureBuilder setelah rebuild.
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat datang, ${_firstName(profile.fullName)}',
              style: const TextStyle(
                fontSize: 28,
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Berikut ringkasan operasional laboratorium hari ini.',
              style: TextStyle(fontSize: 14, height: 1.45, color: _muted),
            ),
            const SizedBox(height: 22),
            _buildLaboratoryHero(
              laboratories: laboratories,
              selectedLaboratory: selectedLaboratory,
            ),
            const SizedBox(height: 24),
            _sectionHeader('Ringkasan Aset'),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 132,
              children: [
                _buildStatCard(
                  label: 'Total Aset',
                  value: total.toString(),
                  supporting: total == 0 ? 'Belum ada aset' : 'Unit terdaftar',
                  icon: Icons.inventory_2_outlined,
                  accent: _ink,
                  iconBackground: _softLime,
                ),
                _buildStatCard(
                  label: 'Tersedia',
                  value: available.toString(),
                  supporting: total == 0
                      ? 'Belum ada data'
                      : '${(readiness * 100).round()}% siap pakai',
                  icon: Icons.check_circle_outline_rounded,
                  accent: const Color(0xFF188A55),
                  iconBackground: const Color(0xFFE5F6EC),
                ),
                _buildStatCard(
                  label: 'Dipinjam',
                  value: borrowed.toString(),
                  supporting: borrowed == 0
                      ? 'Tidak ada pinjaman'
                      : 'Unit aktif',
                  icon: Icons.swap_horiz_rounded,
                  accent: const Color(0xFF3559A6),
                  iconBackground: const Color(0xFFE8EEFF),
                ),
                _buildStatCard(
                  label: 'Maintenance',
                  value: openMaintenance.toString(),
                  supporting: openMaintenance == 0
                      ? 'Tidak ada perbaikan'
                      : 'Perlu ditangani',
                  icon: Icons.build_outlined,
                  accent: const Color(0xFFA86E00),
                  iconBackground: const Color(0xFFFFF0CF),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(child: _sectionHeader('Aksi Cepat')),
                TextButton(
                  onPressed: () {
                    context.go('/lab-admin/assets');
                  },
                  child: const Text('Lihat inventaris'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.add_rounded,
                    label: 'Tambah\nAset',
                    badge: null,
                    onTap: _createAsset,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'Kelola\nInventaris',
                    badge: total == 0 ? null : total.toString(),
                    onTap: () {
                      context.go('/lab-admin/assets');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Review\nPinjaman',
                    badge: null,
                    onTap: () {
                      context.go('/lab-admin/borrowing');
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.build_outlined,
                    label: 'Maintenance',
                    badge: openMaintenance == 0
                        ? null
                        : openMaintenance.toString(),
                    onTap: () {
                      context.push('/lab-admin/maintenance');
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _sectionHeader('Kesehatan Inventaris'),
            const SizedBox(height: 12),
            _buildInventoryHealthCard(
              total: total,
              available: available,
              borrowed: borrowed,
              maintenance: maintenanceAssets,
              damaged: damaged,
              minorDamage: minorDamage,
              inactive: inactive,
            ),
            const SizedBox(height: 18),
            _buildMembershipNote(laboratories.length),
          ],
        ),
      ),
    );
  }

  Widget _buildLaboratoryHero({
    required List<Laboratory> laboratories,
    required Laboratory selectedLaboratory,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: _lime,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science_outlined, color: _ink, size: 27),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laboratorium aktif',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 3),
                Text(
                  selectedLaboratory.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${selectedLaboratory.code} · ${selectedLaboratory.location}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB8BCB3),
                  ),
                ),
              ],
            ),
          ),
          if (laboratories.length > 1)
            PopupMenuButton<String>(
              tooltip: 'Pilih laboratorium',
              color: Colors.white,
              iconColor: Colors.white,
              initialValue: selectedLaboratory.id,
              onSelected: (value) {
                setState(() {
                  _selectedLabId = value;
                });
              },
              itemBuilder: (context) {
                return laboratories.map((laboratory) {
                  return PopupMenuItem<String>(
                    value: laboratory.id,
                    child: Text('${laboratory.code} · ${laboratory.name}'),
                  );
                }).toList();
              },
              icon: const Icon(Icons.expand_more_rounded),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String supporting,
    required IconData icon,
    required Color accent,
    required Color iconBackground,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            supporting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
        ],
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
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: _softLime,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 21, color: _ink),
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
                style: const TextStyle(
                  fontSize: 11,
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

  Widget _buildInventoryHealthCard({
    required int total,
    required int available,
    required int borrowed,
    required int maintenance,
    required int damaged,
    required int minorDamage,
    required int inactive,
  }) {
    final readiness = total == 0 ? 0.0 : available / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Rasio kesiapan aset',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                total == 0 ? '0%' : '${(readiness * 100).round()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF188A55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: readiness,
              minHeight: 8,
              backgroundColor: const Color(0xFFEDF0E9),
              valueColor: const AlwaysStoppedAnimation<Color>(_lime),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _healthChip('Tersedia', available, const Color(0xFF188A55)),
              _healthChip('Dipinjam', borrowed, const Color(0xFF3559A6)),
              _healthChip('Maintenance', maintenance, const Color(0xFFA86E00)),
              _healthChip('Rusak', damaged, const Color(0xFFBD3232)),
              _healthChip('Ringan', minorDamage, const Color(0xFF8A6515)),
              _healthChip('Inactive', inactive, _muted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _healthChip(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
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
