import '../../../laboratory/domain/laboratory.dart';
import '../../domain/lab_report.dart';

enum ReportListStatus { initial, loading, loaded, failure }

class ReportListState {
  const ReportListState({
    this.status = ReportListStatus.initial,
    this.laboratories = const <Laboratory>[],
    this.selectedLabId,
    this.reports = const <LabReport>[],
    this.statusFilter = 'open',
    this.searchQuery = '',
    this.reportsLoading = false,
    this.errorMessage = '',
  });

  final ReportListStatus status;
  final List<Laboratory> laboratories;
  final String? selectedLabId;
  final List<LabReport> reports;
  final String statusFilter;
  final String searchQuery;
  final bool reportsLoading;
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

  List<LabReport> get filteredReports {
    final query = searchQuery.trim().toLowerCase();

    return reports
        .where((report) {
          final statusMatches = switch (statusFilter) {
            'open' => report.status == 'open',
            'handling' =>
              report.status == 'acknowledged' || report.status == 'in_progress',
            'done' => report.status == 'resolved' || report.status == 'closed',
            'rejected' => report.status == 'rejected',
            'all' => true,
            _ => true,
          };

          final searchMatches =
              query.isEmpty ||
              report.reportNumber.toLowerCase().contains(query) ||
              report.title.toLowerCase().contains(query) ||
              report.category.toLowerCase().contains(query) ||
              report.location.toLowerCase().contains(query) ||
              report.reporterId.toLowerCase().contains(query);

          return statusMatches && searchMatches;
        })
        .toList(growable: false);
  }

  ReportListState copyWith({
    ReportListStatus? status,
    List<Laboratory>? laboratories,
    String? selectedLabId,
    List<LabReport>? reports,
    String? statusFilter,
    String? searchQuery,
    bool? reportsLoading,
    String? errorMessage,
  }) {
    return ReportListState(
      status: status ?? this.status,
      laboratories: laboratories ?? this.laboratories,
      selectedLabId: selectedLabId ?? this.selectedLabId,
      reports: reports ?? this.reports,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      reportsLoading: reportsLoading ?? this.reportsLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
