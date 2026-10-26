import '../../../laboratory/domain/laboratory.dart';
import '../../domain/borrow_request.dart';

enum AdminBorrowRequestsStatus { initial, loading, loaded, failure }

/// State untuk antrean permintaan peminjaman milik Lab Admin.
///
/// Status `waiting_pickup` tetap dikelompokkan ke filter `approved` karena
/// secara bisnis request sudah disetujui dan sedang berada pada tahap
/// operasional setelah approval.
class AdminBorrowRequestsState {
  const AdminBorrowRequestsState({
    this.status = AdminBorrowRequestsStatus.initial,
    this.laboratories = const <Laboratory>[],
    this.selectedLabId,
    this.requests = const <BorrowRequest>[],
    this.statusFilter = 'pending',
    this.searchQuery = '',
    this.requestsLoading = false,
    this.errorMessage = '',
  });

  final AdminBorrowRequestsStatus status;
  final List<Laboratory> laboratories;
  final String? selectedLabId;
  final List<BorrowRequest> requests;
  final String statusFilter;
  final String searchQuery;
  final bool requestsLoading;
  final String errorMessage;

  Laboratory? get selectedLaboratory {
    final selectedId = selectedLabId;

    if (selectedId == null) {
      return laboratories.isEmpty ? null : laboratories.first;
    }

    for (final laboratory in laboratories) {
      if (laboratory.id == selectedId) {
        return laboratory;
      }
    }

    return laboratories.isEmpty ? null : laboratories.first;
  }

  List<BorrowRequest> get filteredRequests {
    final query = searchQuery.trim().toLowerCase();

    return requests
        .where((request) {
          final statusMatches = switch (statusFilter) {
            'all' => true,
            'approved' =>
              request.status == 'approved' ||
                  request.status == 'waiting_pickup' ||
                  request.status == 'active' ||
                  request.status == 'returned',
            _ => request.status == statusFilter,
          };

          final searchMatches =
              query.isEmpty ||
              request.requestNumber.toLowerCase().contains(query) ||
              request.studentId.toLowerCase().contains(query) ||
              request.purpose.toLowerCase().contains(query);

          return statusMatches && searchMatches;
        })
        .toList(growable: false);
  }

  AdminBorrowRequestsState copyWith({
    AdminBorrowRequestsStatus? status,
    List<Laboratory>? laboratories,
    String? selectedLabId,
    List<BorrowRequest>? requests,
    String? statusFilter,
    String? searchQuery,
    bool? requestsLoading,
    String? errorMessage,
  }) {
    return AdminBorrowRequestsState(
      status: status ?? this.status,
      laboratories: laboratories ?? this.laboratories,
      selectedLabId: selectedLabId ?? this.selectedLabId,
      requests: requests ?? this.requests,
      statusFilter: statusFilter ?? this.statusFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      requestsLoading: requestsLoading ?? this.requestsLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
