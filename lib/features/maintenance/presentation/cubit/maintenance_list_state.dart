import '../../../laboratory/domain/laboratory.dart';
import '../../domain/maintenance_record.dart';

enum MaintenanceListStatus { initial, loading, loaded, failure }

class MaintenanceListState {
  const MaintenanceListState({
    this.status = MaintenanceListStatus.initial,
    this.laboratories = const <Laboratory>[],
    this.selectedLabId,
    this.records = const <MaintenanceRecord>[],
    this.statusFilter = 'pending',
    this.searchQuery = '',
    this.recordsLoading = false,
    this.errorMessage = '',
  });

  final MaintenanceListStatus status;
  final List<Laboratory> laboratories;
  final String? selectedLabId;
  final List<MaintenanceRecord> records;
  final String statusFilter;
  final String searchQuery;
  final bool recordsLoading;
  final String errorMessage;

  Laboratory? get selectedLaboratory {
    final id = selectedLabId;

    if (id == null) {
      return laboratories.isEmpty ? null : laboratories.first;
    }

    for (final laboratory in laboratories) {
      if (laboratory.id == id) {
        return laboratory;
      }
    }

    return laboratories.isEmpty ? null : laboratories.first;
  }

  List<MaintenanceRecord> get filteredRecords {
    final query = searchQuery.trim().toLowerCase();

    return records
        .where((record) {
          final statusMatches =
              statusFilter == 'all' || record.status == statusFilter;

          final searchMatches =
              query.isEmpty ||
              record.assetName.toLowerCase().contains(query) ||
              record.assetCode.toLowerCase().contains(query) ||
              record.description.toLowerCase().contains(query);

          return statusMatches && searchMatches;
        })
        .toList(growable: false);
  }

  MaintenanceListState copyWith({
    MaintenanceListStatus? status,
    List<Laboratory>? laboratories,
    String? selectedLabId,
    List<MaintenanceRecord>? records,
    String? statusFilter,
    String? searchQuery,
    bool? recordsLoading,
    String? errorMessage,
  }) {
    return MaintenanceListState(
      status: status ?? this.status,
      laboratories: laboratories ?? this.laboratories,
      selectedLabId: selectedLabId ?? this.selectedLabId,
      records: records ?? this.records,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      recordsLoading: recordsLoading ?? this.recordsLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
