import '../../domain/borrow_request.dart';

enum AdminBorrowRequestDetailStatus { initial, loading, loaded, failure }

enum AdminBorrowRequestActionStatus { idle, success, warning, failure }

/// State detail permintaan peminjaman.
///
/// State mutation dipisahkan dari loading awal sehingga UI tetap dapat
/// menampilkan data detail ketika proses Setujui/Tolak sedang berlangsung.
class AdminBorrowRequestDetailState {
  const AdminBorrowRequestDetailState({
    this.status = AdminBorrowRequestDetailStatus.initial,
    this.request,
    this.items = const <BorrowRequestItem>[],
    this.itemsLoading = false,
    this.itemsError = '',
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = AdminBorrowRequestActionStatus.idle,
    this.actionMessage = '',
  });

  final AdminBorrowRequestDetailStatus status;
  final BorrowRequest? request;
  final List<BorrowRequestItem> items;
  final bool itemsLoading;
  final String itemsError;
  final bool isProcessing;
  final String errorMessage;
  final AdminBorrowRequestActionStatus actionStatus;
  final String actionMessage;

  AdminBorrowRequestDetailState copyWith({
    AdminBorrowRequestDetailStatus? status,
    BorrowRequest? request,
    List<BorrowRequestItem>? items,
    bool? itemsLoading,
    String? itemsError,
    bool? isProcessing,
    String? errorMessage,
    AdminBorrowRequestActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return AdminBorrowRequestDetailState(
      status: status ?? this.status,
      request: request ?? this.request,
      items: items ?? this.items,
      itemsLoading: itemsLoading ?? this.itemsLoading,
      itemsError: itemsError ?? this.itemsError,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
