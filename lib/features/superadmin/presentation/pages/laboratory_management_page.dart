import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';

import '../../../../shared/presentation/states/labflow_connection_error_state.dart';

import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../../shared/presentation/states/labflow_no_search_results_state.dart';

import '../../../laboratory/data/laboratory_service.dart';

import '../../../laboratory/domain/laboratory.dart';

import '../widgets/superadmin_bottom_navigation.dart';

enum _LaboratoryFilter { all, active, inactive }

class LaboratoryManagementPage extends StatefulWidget {
  const LaboratoryManagementPage({super.key});

  @override
  State<LaboratoryManagementPage> createState() =>
      _LaboratoryManagementPageState();
}

class _LaboratoryManagementPageState extends State<LaboratoryManagementPage> {
  final LaboratoryService _laboratoryService = LaboratoryService();

  final TextEditingController _searchController = TextEditingController();

  _LaboratoryFilter _selectedFilter = _LaboratoryFilter.all;

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),

      body: SafeArea(
        bottom: false,

        child: Column(
          children: [
            /// Header halaman sesuai reference Figma.

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),

              child: _buildHeader(),
            ),

            const SizedBox(height: 20),

            /// Search dan filter.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),

              child: _buildSearchBar(),
            ),

            const SizedBox(height: 20),

            /// Data laboratorium realtime dari Firestore.
            Expanded(
              child: StreamBuilder<List<Laboratory>>(
                stream: _laboratoryService.watchLaboratories(),

                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const LabFlowLoadingState(
                      title: 'Memuat laboratorium',

                      message: 'Mengambil daftar laboratorium terbaru.',
                    );
                  }

                  if (snapshot.hasError) {
                    return const LabFlowConnectionErrorState(
                      title: 'Laboratorium tidak dapat dimuat',

                      message:
                          'Data laboratorium tidak dapat diambil saat ini. '
                          'Periksa koneksi Anda lalu coba lagi.',
                    );
                  }

                  final laboratories = snapshot.data ?? <Laboratory>[];

                  final filteredLaboratories = _filterLaboratories(
                    laboratories,
                  );

                  if (laboratories.isEmpty) {
                    return _buildEmptyState();
                  }

                  if (filteredLaboratories.isEmpty) {
                    return const LabFlowNoSearchResultsState(
                      title: 'Laboratorium tidak ditemukan',
                      message: 'Coba ubah kata pencarian atau filter yang digunakan.',
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),

                    children: [
                      for (
                        int index = 0;

                        index < filteredLaboratories.length;

                        index++
                      ) ...[
                        _buildLaboratoryCard(filteredLaboratories[index]),

                        if (index != filteredLaboratories.length - 1)
                          const SizedBox(height: 14),
                      ],

                      const SizedBox(height: 22),

                      /// Ringkasan sederhana menggunakan

                      /// data yang tersedia.
                      _buildSummary(laboratories),

                      const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const SuperadminBottomNavigation(currentIndex: 1),
    );
  }

  /// Header besar + tombol tambah.

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Laboratorium',

            style: TextStyle(
              fontSize: 30,

              height: 1,

              fontWeight: FontWeight.w800,

              color: Color(0xFF111111),
            ),
          ),
        ),

        const SizedBox(width: 16),

        Material(
          color: Colors.white,

          shape: const CircleBorder(),

          child: InkWell(
            customBorder: const CircleBorder(),

            onTap: _createLaboratory,

            child: const SizedBox(
              width: 52,

              height: 52,

              child: Icon(
                Icons.add_rounded,

                size: 28,

                color: Color(0xFF111111),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Search field mengikuti visual LabFlow.

  Widget _buildSearchBar() {
    return Container(
      height: 54,

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(999),

        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),

      child: Row(
        children: [
          const SizedBox(width: 16),

          const Icon(Icons.search_rounded, size: 24, color: Color(0xFF111111)),

          const SizedBox(width: 12),

          Expanded(
            child: TextField(
              controller: _searchController,

              onChanged: (_) {
                setState(() {});
              },

              textInputAction: TextInputAction.search,

              decoration: const InputDecoration(
                hintText: 'Cari laboratorium...',

                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8B929F)),

                border: InputBorder.none,

                isDense: true,
              ),
            ),
          ),

          IconButton(
            tooltip: 'Filter laboratorium',

            onPressed: _openFilterSheet,

            icon: Icon(
              Icons.tune_rounded,

              color: _selectedFilter == _LaboratoryFilter.all
                  ? const Color(0xFF111111)
                  : const Color(0xFF6C9B00),
            ),
          ),

          const SizedBox(width: 6),
        ],
      ),
    );
  }

  /// Card laboratorium.

  Widget _buildLaboratoryCard(Laboratory laboratory) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),

      onTap: () async {
        final result = await context.push<String>(
          '/superadmin/labs/${laboratory.id}/edit',
        );

        if (!mounted) {
          return;
        }

        if (result == 'updated') {
          _showSuccessMessage(
            title: 'Laboratorium diperbarui',

            message: '${laboratory.code} berhasil diperbarui.',
          );
        } else if (result == 'deleted') {
          _showSuccessMessage(
            title: 'Laboratorium dihapus',

            message: '${laboratory.code} berhasil dihapus dari sistem.',
          );
        }
      },

      child: Container(
        width: double.infinity,

        padding: const EdgeInsets.fromLTRB(16, 18, 14, 18),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(24),
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                SizedBox(
                  width: 30,

                  height: 30,

                  child: Icon(
                    _laboratoryIcon(laboratory.name),

                    size: 26,

                    color: const Color(0xFF111111),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    laboratory.name,

                    maxLines: 2,

                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 17,

                      height: 1.15,

                      fontWeight: FontWeight.w800,

                      color: Color(0xFF111111),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.north_east_rounded,

                  size: 20,

                  color: Color(0xFF111111),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Expanded(child: _buildInformation(laboratory.code, 'Kode')),

                const SizedBox(width: 10),

                Expanded(
                  flex: 2,

                  child: _buildInformation(laboratory.location, 'Lokasi'),
                ),

                const SizedBox(width: 10),

                Expanded(child: _buildStatusInformation(laboratory.isActive)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Informasi kecil di bagian bawah card.

  Widget _buildInformation(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          value,

          maxLines: 2,

          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            fontSize: 12,

            height: 1.25,

            fontWeight: FontWeight.w600,

            color: Color(0xFF111111),
          ),
        ),

        const SizedBox(height: 3),

        Text(
          label,

          style: const TextStyle(fontSize: 10, color: Color(0xFF8B929F)),
        ),
      ],
    );
  }

  Widget _buildStatusInformation(bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          isActive ? 'Aktif' : 'Tidak Aktif',

          maxLines: 1,

          style: TextStyle(
            fontSize: 12,

            fontWeight: FontWeight.w700,

            color: isActive ? const Color(0xFF188A55) : const Color(0xFFC93434),
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'Status',

          style: TextStyle(fontSize: 10, color: Color(0xFF8B929F)),
        ),
      ],
    );
  }

  /// Icon berdasarkan jenis/nama laboratorium.

  IconData _laboratoryIcon(String name) {
    final normalized = name.toLowerCase();

    if (normalized.contains('iot') ||
        normalized.contains('internet of things')) {
      return Icons.sensors_rounded;
    }

    if (normalized.contains('jaringan') || normalized.contains('network')) {
      return Icons.router_outlined;
    }

    if (normalized.contains('multimedia')) {
      return Icons.live_tv_outlined;
    }

    if (normalized.contains('elektronika') ||
        normalized.contains('electronic')) {
      return Icons.developer_board_outlined;
    }

    if (normalized.contains('komputer') ||
        normalized.contains('computer') ||
        normalized.contains('kom')) {
      return Icons.desktop_windows_outlined;
    }

    return Icons.science_outlined;
  }

  /// Ringkasan jumlah laboratorium.

  Widget _buildSummary(List<Laboratory> laboratories) {
    final activeCount = laboratories
        .where((laboratory) => laboratory.isActive)
        .length;

    return Text(
      '${laboratories.length} laboratorium · '
      '$activeCount aktif',

      style: const TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
    );
  }

  /// Search + filter lokal.

  List<Laboratory> _filterLaboratories(List<Laboratory> laboratories) {
    final query = _searchController.text.trim().toLowerCase();

    return laboratories.where((laboratory) {
      final matchesSearch =
          query.isEmpty ||
          laboratory.name.toLowerCase().contains(query) ||
          laboratory.code.toLowerCase().contains(query) ||
          laboratory.location.toLowerCase().contains(query);

      final matchesFilter = switch (_selectedFilter) {
        _LaboratoryFilter.all => true,

        _LaboratoryFilter.active => laboratory.isActive,

        _LaboratoryFilter.inactive => !laboratory.isActive,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  /// Filter status melalui bottom sheet.

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<_LaboratoryFilter>(
      context: context,

      showDragHandle: true,

      backgroundColor: const Color(0xFFF6F9EF),

      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  'Filter Laboratorium',

                  style: TextStyle(
                    fontSize: 22,

                    fontWeight: FontWeight.w800,

                    color: Color(0xFF111111),
                  ),
                ),

                const SizedBox(height: 16),

                _buildFilterOption(
                  context: context,

                  value: _LaboratoryFilter.all,

                  icon: Icons.apps_rounded,

                  label: 'Semua Laboratorium',
                ),

                _buildFilterOption(
                  context: context,

                  value: _LaboratoryFilter.active,

                  icon: Icons.check_circle_outline_rounded,

                  label: 'Aktif',
                ),

                _buildFilterOption(
                  context: context,

                  value: _LaboratoryFilter.inactive,

                  icon: Icons.block_rounded,

                  label: 'Tidak Aktif',
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedFilter = result;
    });
  }

  Widget _buildFilterOption({
    required BuildContext context,

    required _LaboratoryFilter value,

    required IconData icon,

    required String label,
  }) {
    final selected = _selectedFilter == value;

    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(
        backgroundColor: selected ? const Color(0xFFB9F33D) : Colors.white,

        foregroundColor: const Color(0xFF111111),

        child: Icon(icon),
      ),

      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),

      trailing: selected ? const Icon(Icons.check_rounded) : null,

      onTap: () {
        Navigator.of(context).pop(value);
      },
    );
  }

  /// Membuka form Create Laboratory.

  Future<void> _createLaboratory() async {
    final created = await context.push<bool>('/superadmin/labs/create');

    if (!mounted) {
      return;
    }

    if (created == true) {
      _showSuccessMessage(
        title: 'Laboratorium dibuat',

        message: 'Laboratorium baru berhasil ditambahkan ke sistem.',
      );
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(Icons.science_outlined, size: 56),

            SizedBox(height: 16),

            Text(
              'Belum ada laboratorium',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            SizedBox(height: 8),

            Text(
              'Tambahkan laboratorium pertama melalui tombol + di atas.',

              textAlign: TextAlign.center,

              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  /// Shared floating notification untuk operasi sukses.

  ///

  /// Menggantikan SnackBar hitam bawaan Flutter.

  void _showSuccessMessage({required String title, required String message}) {
    showLabFlowNotification(
      context: context,

      title: title,

      message: message,

      type: LabFlowNotificationType.success,
    );
  }
}
