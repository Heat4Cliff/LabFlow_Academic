import 'package:flutter/material.dart';

import '../../../auth/domain/user_profile.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';

class LabMembershipPage extends StatefulWidget {
  const LabMembershipPage({super.key});

  @override
  State<LabMembershipPage> createState() => _LabMembershipPageState();
}

class _LabMembershipPageState extends State<LabMembershipPage> {
  final LabMembershipService _service = LabMembershipService();

  String? _selectedAdminId;
  String? _selectedLabId;

  bool _isLoading = false;

  Future<void> _assign() async {
    if (_selectedAdminId == null || _selectedLabId == null || _isLoading) {
      _showMessage('Pilih Lab Admin dan laboratorium terlebih dahulu.');

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _service.assignLabAdmin(
        userId: _selectedAdminId!,
        labId: _selectedLabId!,
      );

      if (!mounted) return;

      _showMessage('Lab Admin berhasil ditugaskan.');
    } on LabMembershipException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Gagal membuat membership laboratorium.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        title: const Text(
          'Membership Laboratorium',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<UserProfile>>(
        stream: _service.watchLabAdmins(),
        builder: (context, adminSnapshot) {
          if (!adminSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final admins = adminSnapshot.data ?? [];

          return StreamBuilder<List<Laboratory>>(
            stream: _service.watchActiveLaboratories(),
            builder: (context, labSnapshot) {
              if (!labSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final laboratories = labSnapshot.data ?? [];

              return StreamBuilder<List<LabMembership>>(
                stream: _service.watchMemberships(),
                builder: (context, membershipSnapshot) {
                  final memberships = membershipSnapshot.data ?? [];

                  return _buildContent(
                    admins: admins,
                    laboratories: laboratories,
                    memberships: memberships,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContent({
    required List<UserProfile> admins,
    required List<Laboratory> laboratories,
    required List<LabMembership> memberships,
  }) {
    final adminById = {for (final admin in admins) admin.uid: admin};

    final laboratoryById = {
      for (final laboratory in laboratories) laboratory.id: laboratory,
    };

    final activeMemberships = memberships
        .where((membership) => membership.active)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text(
          'Assign Lab Admin',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 8),

        const Text(
          'Pilih akun Lab Admin dan laboratorium yang akan menjadi tanggung jawabnya.',
          style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
        ),

        const SizedBox(height: 24),

        DropdownButtonFormField<String>(
          initialValue: _selectedAdminId,
          decoration: _inputDecoration('Lab Admin', Icons.person_outline),
          items: admins
              .map(
                (admin) => DropdownMenuItem(
                  value: admin.uid,
                  child: Text(admin.fullName),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedAdminId = value;
            });
          },
        ),

        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          initialValue: _selectedLabId,
          decoration: _inputDecoration('Laboratorium', Icons.science_outlined),
          items: laboratories
              .map(
                (laboratory) => DropdownMenuItem(
                  value: laboratory.id,
                  child: Text('${laboratory.code} — ${laboratory.name}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedLabId = value;
            });
          },
        ),

        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: _isLoading ? null : _assign,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF111111),
              foregroundColor: Colors.white,
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
                : const Text(
                    'Tetapkan Lab Admin',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),

        const SizedBox(height: 32),

        const Text(
          'Assignment Aktif',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: 12),

        if (activeMemberships.isEmpty)
          const Text(
            'Belum ada Lab Admin yang ditugaskan.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),

        for (final membership in activeMemberships)
          _buildMembershipCard(
            membership,
            adminById[membership.userId],
            laboratoryById[membership.labId],
          ),
      ],
    );
  }

  Widget _buildMembershipCard(
    LabMembership membership,
    UserProfile? admin,
    Laboratory? laboratory,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E6DC)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFEAFBCB),
            child: Icon(Icons.admin_panel_settings),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin?.fullName ?? membership.userId,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 4),

                Text(
                  laboratory == null
                      ? membership.labId
                      : '${laboratory.code} — ${laboratory.name}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Nonaktifkan assignment',
            onPressed: () async {
              await _service.deactivateMembership(membership.id);
            },
            icon: const Icon(Icons.link_off_rounded),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8DDD0)),
      ),
    );
  }
}
