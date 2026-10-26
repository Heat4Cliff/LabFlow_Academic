import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../../shared/presentation/states/labflow_no_search_results_state.dart';
import '../../../asset/data/asset_service.dart';
import '../../../asset/domain/laboratory_asset.dart';
import '../../../laboratory/data/lab_membership_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../cubit/asset_management_cubit.dart';
import '../cubit/asset_management_state.dart';
import '../widgets/asset_management_widgets.dart';
import '../widgets/lab_admin_bottom_navigation.dart';

class AssetManagementPage extends StatelessWidget {
  const AssetManagementPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        AssetManagementCubit(LabMembershipService(), AssetService())..start(),
    child: const _AssetManagementView(),
  );
}

class _AssetManagementView extends StatefulWidget {
  const _AssetManagementView();

  @override
  State<_AssetManagementView> createState() => _AssetManagementViewState();
}

class _AssetManagementViewState extends State<_AssetManagementView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createAsset() async {
    final created = await context.push<bool>('/lab-admin/assets/create');
    if (!mounted || created != true) return;
    showLabFlowNotification(
      context: context,
      title: 'Aset berhasil dibuat',
      message: 'Aset baru berhasil ditambahkan ke inventaris laboratorium.',
      type: LabFlowNotificationType.success,
    );
  }

  Future<void> _openAssetDetail(LaboratoryAsset asset) async {
    final result = await context.push<String>('/lab-admin/assets/${asset.id}');
    if (!mounted || result != 'deleted') return;
    showLabFlowNotification(
      context: context,
      title: 'Aset berhasil dihapus',
      message: '${asset.name} telah dihapus dari inventaris.',
      type: LabFlowNotificationType.success,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F9EF),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF6F9EF),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Inventaris Aset',
        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF111111)),
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
    body: BlocBuilder<AssetManagementCubit, AssetManagementState>(
      builder: (context, state) => _buildBody(context, state),
    ),
    bottomNavigationBar: const LabAdminBottomNavigation(currentIndex: 1),
  );

  Widget _buildBody(BuildContext context, AssetManagementState state) {
    switch (state.status) {
      case AssetManagementStatus.initial:
      case AssetManagementStatus.loading:
        return const LabFlowLoadingState(
          title: 'Memuat inventaris',
          message: 'Menyiapkan laboratorium dan aset terbaru.',
        );
      case AssetManagementStatus.failure:
        return LabFlowConnectionErrorState(
          title: 'Inventaris tidak dapat dimuat',
          message: state.errorMessage,
          onRetry: context.read<AssetManagementCubit>().retry,
        );
      case AssetManagementStatus.noMembership:
        return AssetManagementEmptyState.noMembership();
      case AssetManagementStatus.noLaboratory:
        return AssetManagementEmptyState.noLaboratory();
      case AssetManagementStatus.loaded:
        final laboratory = state.selectedLaboratory;
        if (laboratory == null) return const SizedBox.shrink();
        return _buildInventory(context, state, laboratory);
    }
  }

  Widget _buildInventory(
    BuildContext context,
    AssetManagementState state,
    Laboratory laboratory,
  ) {
    final filteredAssets = state.filteredAssets;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _laboratorySelector(context, state, laboratory),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _searchField(context, state),
        ),
        const SizedBox(height: 14),
        _statusFilters(context, state),
        const SizedBox(height: 10),
        Expanded(child: _assetList(context, state, laboratory, filteredAssets)),
      ],
    );
  }

  Widget _laboratorySelector(
    BuildContext context,
    AssetManagementState state,
    Laboratory selected,
  ) => Container(
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
                selected.name,
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
                '${selected.code} · ${selected.location}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFFB8BCB3)),
              ),
            ],
          ),
        ),
        if (state.laboratories.length > 1)
          Theme(
            data: Theme.of(context).copyWith(canvasColor: Colors.white),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: state.selectedLabId,
                icon: const Icon(
                  Icons.expand_more_rounded,
                  color: Colors.white,
                ),
                items: state.laboratories
                    .map(
                      (lab) => DropdownMenuItem(
                        value: lab.id,
                        child: Text(lab.code),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _searchController.clear();
                  context.read<AssetManagementCubit>().selectLaboratory(value);
                },
              ),
            ),
          ),
      ],
    ),
  );

  Widget _searchField(BuildContext context, AssetManagementState state) =>
      TextField(
        controller: _searchController,
        onChanged: context.read<AssetManagementCubit>().updateSearch,
        decoration: InputDecoration(
          hintText: 'Cari nama, kode, kategori, atau lokasi...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: state.searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: () {
                    _searchController.clear();
                    context.read<AssetManagementCubit>().updateSearch('');
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

  Widget _statusFilters(BuildContext context, AssetManagementState state) =>
      SizedBox(
        height: 44,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          children: [
            _filterChip(context, state, 'Semua', AssetStatusFilter.all),
            const SizedBox(width: 8),
            _filterChip(
              context,
              state,
              'Available',
              AssetStatusFilter.available,
            ),
            const SizedBox(width: 8),
            _filterChip(context, state, 'Borrowed', AssetStatusFilter.borrowed),
            const SizedBox(width: 8),
            _filterChip(
              context,
              state,
              'Maintenance',
              AssetStatusFilter.maintenance,
            ),
            const SizedBox(width: 8),
            _filterChip(context, state, 'Inactive', AssetStatusFilter.inactive),
          ],
        ),
      );

  Widget _filterChip(
    BuildContext context,
    AssetManagementState state,
    String label,
    AssetStatusFilter filter,
  ) {
    final selected = state.statusFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) =>
          context.read<AssetManagementCubit>().selectStatus(filter),
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

  Widget _assetList(
    BuildContext context,
    AssetManagementState state,
    Laboratory laboratory,
    List<LaboratoryAsset> assets,
  ) {
    if (state.assets.isEmpty) {
      return AssetManagementEmptyState.noAssets(laboratory);
    }
    if (assets.isEmpty) {
      return const LabFlowNoSearchResultsState(
        title: 'Aset tidak ditemukan',
        message: 'Coba ubah kata pencarian atau filter status yang digunakan.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      itemCount: assets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '${assets.length} dari ${state.assets.length} aset',
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
            ),
          );
        }
        final asset = assets[index - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LaboratoryAssetCard(
            asset: asset,
            onTap: () => _openAssetDetail(asset),
          ),
        );
      },
    );
  }
}
