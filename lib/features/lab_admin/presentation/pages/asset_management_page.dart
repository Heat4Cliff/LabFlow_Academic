import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../../shared/presentation/states/labflow_no_search_results_state.dart';
import '../../../asset/data/asset_service.dart';
import '../../../asset/domain/laboratory_asset.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/lab_membership.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../widgets/lab_admin_bottom_navigation.dart';

enum _AssetStatusFilter { all, available, borrowed, maintenance, inactive }

class AssetManagementPage extends StatefulWidget {
  const AssetManagementPage({super.key});
  @override
  State<AssetManagementPage> createState() => _AssetManagementPageState();
}

class _AssetManagementPageState extends State<AssetManagementPage> {
  final LabMembershipService _membershipService = LabMembershipService();
  final AssetService _assetService = AssetService();
  final TextEditingController _searchController = TextEditingController();
  _AssetStatusFilter _selectedFilter = _AssetStatusFilter.all;
  String? _selectedLabId;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _openAssetDetail(LaboratoryAsset asset) async {
    final result = await context.push<String>('/lab-admin/assets/${asset.id}');

    if (!mounted || result != 'deleted') {
      return;
    }

    showLabFlowNotification(
      context: context,
      title: 'Aset berhasil dihapus',
      message: '${asset.name} telah dihapus dari inventaris.',
      type: LabFlowNotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Inventaris Aset',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Tambah aset',
            onPressed: _createAsset,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<LabMembership>>(
        stream: _membershipService.watchCurrentLabAdminMemberships(),
        builder: (context, membershipSnapshot) {
          if (membershipSnapshot.connectionState == ConnectionState.waiting &&
              !membershipSnapshot.hasData) {
            return const LabFlowLoadingState(
              title: 'Memuat akses laboratorium',
              message:
                  'Memeriksa laboratorium yang menjadi tanggung jawab Anda.',
            );
          }
          if (membershipSnapshot.hasError) {
            return const LabFlowConnectionErrorState(
              title: 'Akses laboratorium tidak dapat dimuat',
              message:
                  'Assignment laboratorium tidak dapat diperiksa saat ini. '
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
              if (laboratorySnapshot.connectionState ==
                      ConnectionState.waiting &&
                  !laboratorySnapshot.hasData) {
                return const LabFlowLoadingState(
                  title: 'Memuat laboratorium',
                  message:
                      'Menyiapkan laboratorium yang ditugaskan kepada Anda.',
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
              final laboratories = laboratorySnapshot.data ?? <Laboratory>[];
              final membershipLabIds = memberships
                  .map((membership) => membership.labId)
                  .toSet();
              final assignedLaboratories = laboratories
                  .where(
                    (laboratory) => membershipLabIds.contains(laboratory.id),
                  )
                  .toList();
              assignedLaboratories.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              );
              if (assignedLaboratories.isEmpty) {
                return _buildNoActiveLaboratoryState();
              }
              final selectedLabId = _resolveSelectedLabId(assignedLaboratories);
              final selectedLaboratory = assignedLaboratories.firstWhere(
                (laboratory) => laboratory.id == selectedLabId,
              );
              return _buildInventory(
                assignedLaboratories: assignedLaboratories,
                selectedLaboratory: selectedLaboratory,
              );
            },
          );
        },
      ),
      bottomNavigationBar: const LabAdminBottomNavigation(currentIndex: 1),
    );
  }

  String _resolveSelectedLabId(List<Laboratory> assignedLaboratories) {
    final current = _selectedLabId;
    if (current != null &&
        assignedLaboratories.any((laboratory) => laboratory.id == current)) {
      return current;
    }
    return assignedLaboratories.first.id;
  }

  Widget _buildInventory({
    required List<Laboratory> assignedLaboratories,
    required Laboratory selectedLaboratory,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildLaboratorySelector(
            laboratories: assignedLaboratories,
            selectedLaboratory: selectedLaboratory,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildSearchField(),
        ),
        const SizedBox(height: 14),
        _buildStatusFilters(),
        const SizedBox(height: 10),
        Expanded(
          child: StreamBuilder<List<LaboratoryAsset>>(
            stream: _assetService.watchAssetsByLaboratory(
              selectedLaboratory.id,
            ),
            builder: (context, assetSnapshot) {
              if (assetSnapshot.connectionState == ConnectionState.waiting &&
                  !assetSnapshot.hasData) {
                return const LabFlowLoadingState(
                  title: 'Memuat aset',
                  message: 'Mengambil inventaris laboratorium terbaru.',
                );
              }
              if (assetSnapshot.hasError) {
                return const LabFlowConnectionErrorState(
                  title: 'Inventaris tidak dapat dimuat',
                  message:
                      'Data aset laboratorium tidak dapat diambil saat ini. '
                      'Periksa koneksi Anda lalu coba lagi.',
                );
              }
              final assets = assetSnapshot.data ?? <LaboratoryAsset>[];
              if (assets.isEmpty) {
                return _buildEmptyAssetState(selectedLaboratory);
              }
              final filteredAssets = _filterAssets(assets);
              if (filteredAssets.isEmpty) {
                return const LabFlowNoSearchResultsState(
                  title: 'Aset tidak ditemukan',
                  message: 'Coba ubah kata pencarian atau filter status yang digunakan.',
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    '${filteredAssets.length} dari ${assets.length} aset',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A8190),
                    ),
                  ),
                  const SizedBox(height: 14),
                  for (final asset in filteredAssets) ...[
                    _buildAssetCard(asset),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLaboratorySelector({
    required List<Laboratory> laboratories,
    required Laboratory selectedLaboratory,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFB9F33D),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.science_outlined, color: Color(0xFF111111)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laboratorium aktif',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedLaboratory.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${selectedLaboratory.code} · '
                  '${selectedLaboratory.location}',
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
            Theme(
              data: Theme.of(context).copyWith(canvasColor: Colors.white),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedLaboratory.id,
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    color: Colors.white,
                  ),
                  items: laboratories.map((laboratory) {
                    return DropdownMenuItem<String>(
                      value: laboratory.id,
                      child: Text(laboratory.code),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedLabId = value;
                      _searchController.clear();
                      _selectedFilter = _AssetStatusFilter.all;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: 'Cari nama, kode, kategori, atau lokasi...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Hapus pencarian',
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close_rounded),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFDDE2D5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFFDDE2D5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(color: Color(0xFF111111), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(label: 'Semua', value: _AssetStatusFilter.all),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Available',
            value: _AssetStatusFilter.available,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Borrowed',
            value: _AssetStatusFilter.borrowed,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Maintenance',
            value: _AssetStatusFilter.maintenance,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Inactive',
            value: _AssetStatusFilter.inactive,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _AssetStatusFilter value,
  }) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: const Color(0xFF111111),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF111111) : const Color(0xFFDDE2D5),
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? const Color(0xFFB9F33D) : const Color(0xFF111111),
      ),
      shape: const StadiumBorder(),
    );
  }

  List<LaboratoryAsset> _filterAssets(List<LaboratoryAsset> assets) {
    final query = _searchController.text.trim().toLowerCase();
    return assets.where((asset) {
      final searchMatches =
          query.isEmpty ||
          asset.name.toLowerCase().contains(query) ||
          asset.code.toLowerCase().contains(query) ||
          asset.category.toLowerCase().contains(query) ||
          asset.location.toLowerCase().contains(query);
      final statusMatches = switch (_selectedFilter) {
        _AssetStatusFilter.all => true,
        _AssetStatusFilter.available => asset.status == 'available',
        _AssetStatusFilter.borrowed => asset.status == 'borrowed',
        _AssetStatusFilter.maintenance => asset.status == 'maintenance',
        _AssetStatusFilter.inactive => asset.status == 'inactive',
      };
      return searchMatches && statusMatches;
    }).toList();
  }

  Widget _buildAssetCard(LaboratoryAsset asset) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          _openAssetDetail(asset);
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE2D5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAssetThumbnail(asset),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            asset.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(asset.status),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${asset.code} · ${asset.category}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A8190),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: Color(0xFF7A8190),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            asset.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D6458),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_outlined,
                          size: 16,
                          color: Color(0xFF7A8190),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Stock: ${asset.stock}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5D6458),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.health_and_safety_outlined,
                          size: 16,
                          color: Color(0xFF7A8190),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Kondisi: ${_conditionLabel(asset.condition)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5D6458),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Color(0xFF7A8190),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetThumbnail(LaboratoryAsset asset) {
    const size = 58.0;
    final imageUrl = asset.imageUrl.trim();

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBCB),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Icon(_assetIcon(asset.category), color: const Color(0xFF111111)),
      );
    }

    if (imageUrl.isEmpty) {
      return fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 180,
        cacheHeight: 180,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            width: size,
            height: size,
            color: const Color(0xFFF0F3EA),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final background = switch (status) {
      'available' => const Color(0xFFE5F6EC),
      'borrowed' => const Color(0xFFE8EEFF),
      'maintenance' => const Color(0xFFFFF0CF),
      'inactive' => const Color(0xFFF0F1EE),
      _ => const Color(0xFFF0F1EE),
    };
    final foreground = switch (status) {
      'available' => const Color(0xFF188A55),
      'borrowed' => const Color(0xFF3559A6),
      'maintenance' => const Color(0xFFA86E00),
      'inactive' => const Color(0xFF6B7280),
      _ => const Color(0xFF6B7280),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'borrowed':
        return 'Borrowed';
      case 'maintenance':
        return 'Maintenance';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  String _conditionLabel(String condition) {
    switch (condition) {
      case 'good':
        return 'Baik';
      case 'minor_damage':
        return 'Kerusakan Ringan';
      case 'damaged':
        return 'Rusak';
      default:
        return condition;
    }
  }

  IconData _assetIcon(String category) {
    final value = category.toLowerCase();
    if (value.contains('komputer') ||
        value.contains('laptop') ||
        value.contains('pc')) {
      return Icons.computer_rounded;
    }
    if (value.contains('jaringan') ||
        value.contains('router') ||
        value.contains('network')) {
      return Icons.router_outlined;
    }
    if (value.contains('elektronik')) {
      return Icons.memory_rounded;
    }
    return Icons.inventory_2_outlined;
  }

  Widget _buildEmptyAssetState(Laboratory laboratory) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFEAFBCB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 38,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada aset',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada inventaris yang terdaftar pada '
              '${laboratory.name}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
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
            Icon(
              Icons.assignment_late_outlined,
              size: 60,
              color: Color(0xFF6B7280),
            ),
            SizedBox(height: 18),
            Text(
              'Belum ada assignment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Akun Lab Admin ini belum memiliki akses aktif ke '
              'laboratorium mana pun. Hubungi Superadmin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
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
            Icon(Icons.science_outlined, size: 60, color: Color(0xFF6B7280)),
            SizedBox(height: 18),
            Text(
              'Laboratorium tidak aktif',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Assignment ditemukan, tetapi laboratorium yang '
              'ditugaskan sedang tidak aktif.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
