import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../data/activity_log_service.dart';
import '../cubit/lab_membership_cubit.dart';

class LabMembershipPage extends StatelessWidget {
  const LabMembershipPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        LabMembershipCubit(LabMembershipService(), ActivityLogService())
          ..start(),
    child: const _LabMembershipView(),
  );
}

class _LabMembershipView extends StatefulWidget {
  const _LabMembershipView();

  @override
  State<_LabMembershipView> createState() => _LabMembershipPageState();
}

class _LabMembershipPageState extends State<_LabMembershipView> {
  String? _selectedAdminId;
  String? _selectedLabId;
  bool get _isLoading => switch (context.read<LabMembershipCubit>().state) {
    LabMembershipLoaded(:final isMutating) => isMutating,
    _ => false,
  };
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LabMembershipCubit, LabMembershipState>(
      builder: (context, state) => Scaffold(
        backgroundColor: const Color(0xFFF6F9EF),
        body: SafeArea(
          child: switch (state) {
            LabMembershipLoading() => const LabFlowLoadingState(
              title: 'Memuat membership',
              message: 'Mengambil assignment laboratorium terbaru.',
            ),
            LabMembershipFailure(:final message) => LabFlowConnectionErrorState(
              title: 'Data membership tidak dapat dimuat',
              message: '$message Periksa koneksi Anda lalu coba lagi.',
            ),
            LabMembershipLoaded(
              :final admins,
              :final laboratories,
              :final memberships,
            ) =>
              _buildContent(
                admins: admins,
                laboratories: laboratories,
                memberships: memberships
                    .where((membership) => membership.active)
                    .toList(),
              ),
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<UserProfile> admins,
    required List<Laboratory> laboratories,
    required List<LabMembership> memberships,
  }) {
    final selectedAdmin = _findAdminById(admins, _selectedAdminId);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 22),
          _buildAdminSelector(admins, selectedAdmin),
          const SizedBox(height: 18),
          _buildAccessBanner(),
          const SizedBox(height: 18),
          _buildLaboratorySelector(laboratories),
          const SizedBox(height: 16),
          _buildFixedRoleField(),
          const SizedBox(height: 16),
          _buildMembershipStatusField(),
          const SizedBox(height: 16),
          _buildPermissionInformation(),
          const SizedBox(height: 20),
          _buildSaveButton(),
          if (memberships.isNotEmpty) ...[
            const SizedBox(height: 34),
            const Text(
              'Assignment Aktif',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lab Admin yang saat ini memiliki akses laboratorium.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF7A8190),
              ),
            ),
            const SizedBox(height: 16),
            for (int index = 0; index < memberships.length; index++) ...[
              _buildMembershipCard(
                membership: memberships[index],
                admins: admins,
                laboratories: laboratories,
              ),
              if (index != memberships.length - 1) const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

  /// Header mengikuti hierarchy Figma.
  Widget _buildHeader() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.arrow_back_rounded, color: Color(0xFF111111)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        const Text(
          'Membership',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }

  /// Pemilih akun Lab Admin.
  ///
  /// Setelah dipilih, bagian atas menampilkan identitas user
  /// seperti reference Figma.
  Widget _buildAdminSelector(
    List<UserProfile> admins,
    UserProfile? selectedAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedAdmin != null) ...[
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAFBCB),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF111111)),
                ),
                child: Text(
                  _initials(selectedAdmin.fullName),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAdmin.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedAdmin.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF7A8190),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _buildDropdownContainer(
          label: 'Lab Admin',
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAdminId,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              hint: const Text('Pilih Lab Admin'),
              items: admins.map((admin) {
                return DropdownMenuItem<String>(
                  value: admin.uid,
                  child: Text(admin.fullName, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _selectedAdminId = value;
                      });
                    },
            ),
          ),
        ),
        if (admins.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Belum ada akun dengan role Lab Admin.',
            style: TextStyle(fontSize: 12, color: Color(0xFFC93434)),
          ),
        ],
      ],
    );
  }

  Widget _buildAccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8FBC5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Akses yang tepat.',
            style: TextStyle(
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Atur laboratorium dan tanggung jawab tanpa mengubah akun pengguna.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaboratorySelector(List<Laboratory> laboratories) {
    return _buildDropdownContainer(
      label: 'Laboratorium',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLabId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          hint: const Text('Pilih laboratorium'),
          items: laboratories.map((laboratory) {
            return DropdownMenuItem<String>(
              value: laboratory.id,
              child: Text(
                '${laboratory.code} — ${laboratory.name}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: _isLoading
              ? null
              : (value) {
                  setState(() {
                    _selectedLabId = value;
                  });
                },
        ),
      ),
    );
  }

  /// Untuk implementasi kita saat ini role membership
  /// memang khusus Lab Admin.
  Widget _buildFixedRoleField() {
    return _buildStaticField(
      label: 'Peran',
      value: 'Lab Admin',
      icon: Icons.manage_accounts_outlined,
    );
  }

  /// Membership baru selalu dibuat aktif.
  Widget _buildMembershipStatusField() {
    return _buildStaticField(
      label: 'Status Membership',
      value: 'Aktif',
      icon: Icons.check_circle_outline_rounded,
    );
  }

  Widget _buildPermissionInformation() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.verified_user_outlined, size: 24, color: Color(0xFF188A55)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Lab Admin dapat mengelola aktivitas operasional pada laboratorium yang menjadi tanggung jawabnya.',
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF7A8190),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _isLoading ? null : _assign,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF777777),
          shape: const StadiumBorder(),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Simpan Membership',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMembershipCard({
    required LabMembership membership,
    required List<UserProfile> admins,
    required List<Laboratory> laboratories,
  }) {
    final admin = _findAdminById(admins, membership.userId);
    final laboratory = _findLaboratoryById(laboratories, membership.labId);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAFBCB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      admin?.fullName ?? 'Lab Admin',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      laboratory == null
                          ? membership.labId
                          : '${laboratory.code} — ${laboratory.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A8190),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: membership.active
                      ? const Color(0xFFE5F6EC)
                      : const Color(0xFFFFE1E1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  membership.active ? 'Aktif' : 'Tidak Aktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: membership.active
                        ? const Color(0xFF188A55)
                        : const Color(0xFFC93434),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      _confirmRevoke(
                        membership,
                        adminName: admin?.fullName ?? 'Lab Admin',
                        laboratoryName: laboratory?.name ?? 'laboratorium',
                      );
                    },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFC93434),
                side: const BorderSide(color: Color(0xFFE8C8C8)),
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.link_off_rounded, size: 19),
              label: const Text(
                'Cabut Akses Laboratorium',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContainer({
    required String label,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 9, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DDD0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A8190),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildStaticField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8DDD0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: const Color(0xFF111111)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A8190),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded),
        ],
      ),
    );
  }

  Future<void> _assign() async {
    if (_selectedAdminId == null) {
      _showMessage(
        'Pilih Lab Admin terlebih dahulu.',
        type: LabFlowNotificationType.warning,
        title: 'Lab Admin belum dipilih',
      );
      return;
    }
    if (_selectedLabId == null) {
      _showMessage(
        'Pilih laboratorium terlebih dahulu.',
        type: LabFlowNotificationType.warning,
        title: 'Laboratorium belum dipilih',
      );
      return;
    }
    try {
      final activityLogged = await context.read<LabMembershipCubit>().assign(
        userId: _selectedAdminId!,
        labId: _selectedLabId!,
      );
      if (!mounted) return;
      if (activityLogged) {
        _showMessage(
          'Lab Admin berhasil ditugaskan dan aktivitas dicatat.',
          type: LabFlowNotificationType.success,
          title: 'Membership berhasil disimpan',
        );
      } else {
        _showMessage(
          'Lab Admin berhasil ditugaskan, tetapi Activity Log gagal dicatat.',
          type: LabFlowNotificationType.warning,
          title: 'Membership tersimpan',
        );
      }
      setState(() {
        _selectedLabId = null;
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error.toString(),
        type: LabFlowNotificationType.error,
        title: 'Gagal menyimpan membership',
      );
    }
  }

  Future<void> _confirmRevoke(
    LabMembership membership, {
    required String adminName,
    required String laboratoryName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF6F9EF),
          title: const Text(
            'Cabut akses?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(
            '$adminName tidak lagi memiliki akses aktif ke $laboratoryName.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF111111)),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC93434),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cabut Akses'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
    await _revokeMembership(membership);
  }

  Future<void> _revokeMembership(LabMembership membership) async {
    try {
      final activityLogged = await context
          .read<LabMembershipCubit>()
          .deactivate(
            userId: membership.userId,
            labId: membership.labId,
            membershipId: membership.id,
          );
      if (!mounted) return;
      if (activityLogged) {
        _showMessage(
          'Akses laboratorium berhasil dicabut dan aktivitas dicatat.',
          type: LabFlowNotificationType.success,
          title: 'Akses berhasil dicabut',
        );
      } else {
        _showMessage(
          'Akses berhasil dicabut, tetapi Activity Log gagal dicatat.',
          type: LabFlowNotificationType.warning,
          title: 'Akses berhasil dicabut',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage(
        error.toString(),
        type: LabFlowNotificationType.error,
        title: 'Gagal mencabut akses',
      );
    }
  }

  UserProfile? _findAdminById(List<UserProfile> admins, String? userId) {
    if (userId == null) {
      return null;
    }
    for (final admin in admins) {
      if (admin.uid == userId) {
        return admin;
      }
    }
    return null;
  }

  Laboratory? _findLaboratoryById(List<Laboratory> laboratories, String labId) {
    for (final laboratory in laboratories) {
      if (laboratory.id == labId) {
        return laboratory;
      }
    }
    return null;
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final value = parts.first;
      if (value.length == 1) {
        return value.toUpperCase();
      }
      return value.substring(0, 2).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _showMessage(
    String message, {
    LabFlowNotificationType type = LabFlowNotificationType.info,
    String? title,
  }) {
    showLabFlowNotification(
      context: context,
      message: message,
      type: type,
      title: title,
    );
  }
}
