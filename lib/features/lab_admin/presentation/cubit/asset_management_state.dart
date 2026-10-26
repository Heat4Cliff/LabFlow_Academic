import '../../../asset/domain/laboratory_asset.dart';
import '../../../laboratory/domain/laboratory.dart';

enum AssetManagementStatus {
  initial,
  loading,
  loaded,
  noMembership,
  noLaboratory,
  failure,
}

enum AssetStatusFilter { all, available, borrowed, maintenance, inactive }

class AssetManagementState {
  const AssetManagementState({
    this.status = AssetManagementStatus.initial,
    this.laboratories = const [],
    this.selectedLabId,
    this.assets = const [],
    this.searchQuery = '',
    this.statusFilter = AssetStatusFilter.all,
    this.errorMessage = '',
  });

  final AssetManagementStatus status;
  final List<Laboratory> laboratories;
  final String? selectedLabId;
  final List<LaboratoryAsset> assets;
  final String searchQuery;
  final AssetStatusFilter statusFilter;
  final String errorMessage;

  Laboratory? get selectedLaboratory {
    for (final laboratory in laboratories) {
      if (laboratory.id == selectedLabId) return laboratory;
    }
    return laboratories.isEmpty ? null : laboratories.first;
  }

  List<LaboratoryAsset> get filteredAssets {
    final query = searchQuery.trim().toLowerCase();
    return assets
        .where((asset) {
          final matchesQuery =
              query.isEmpty ||
              asset.name.toLowerCase().contains(query) ||
              asset.code.toLowerCase().contains(query) ||
              asset.category.toLowerCase().contains(query) ||
              asset.location.toLowerCase().contains(query);
          final matchesStatus = switch (statusFilter) {
            AssetStatusFilter.all => true,
            AssetStatusFilter.available => asset.status == 'available',
            AssetStatusFilter.borrowed => asset.status == 'borrowed',
            AssetStatusFilter.maintenance => asset.status == 'maintenance',
            AssetStatusFilter.inactive => asset.status == 'inactive',
          };
          return matchesQuery && matchesStatus;
        })
        .toList(growable: false);
  }

  AssetManagementState copyWith({
    AssetManagementStatus? status,
    List<Laboratory>? laboratories,
    String? selectedLabId,
    bool clearSelectedLabId = false,
    List<LaboratoryAsset>? assets,
    String? searchQuery,
    AssetStatusFilter? statusFilter,
    String? errorMessage,
  }) => AssetManagementState(
    status: status ?? this.status,
    laboratories: laboratories ?? this.laboratories,
    selectedLabId: clearSelectedLabId
        ? null
        : selectedLabId ?? this.selectedLabId,
    assets: assets ?? this.assets,
    searchQuery: searchQuery ?? this.searchQuery,
    statusFilter: statusFilter ?? this.statusFilter,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
