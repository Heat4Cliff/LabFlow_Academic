import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/borrow_request_service.dart';
import '../../domain/borrow_request.dart';
import 'admin_borrow_request_detail_state.dart';

/// Mengelola detail, item, dan mutation permintaan peminjaman Lab Admin.
///
/// Business rule untuk update Firestore tetap berada pada
/// [BorrowRequestService]. Cubit hanya mengatur state loading, data, dan
/// feedback proses agar halaman tidak lagi mengelola async state menggunakan
/// setState/FutureBuilder/StreamBuilder.
class AdminBorrowRequestDetailCubit
    extends Cubit<AdminBorrowRequestDetailState> {
  AdminBorrowRequestDetailCubit(this._service)
    : super(const AdminBorrowRequestDetailState());

  final BorrowRequestService _service;

  StreamSubscription<List<BorrowRequestItem>>? _itemsSubscription;
  String? _requestId;

  /// Memuat dokumen request lalu mulai memantau item request secara realtime.
  Future<void> load(String requestId) async {
    final cleanId = requestId.trim();
    if (cleanId.isEmpty) {
      emit(
        const AdminBorrowRequestDetailState(
          status: AdminBorrowRequestDetailStatus.failure,
          errorMessage: 'ID permintaan peminjaman tidak valid.',
        ),
      );
      return;
    }

    _requestId = cleanId;

    emit(
      const AdminBorrowRequestDetailState(
        status: AdminBorrowRequestDetailStatus.loading,
      ),
    );

    try {
      final request = await _service.getRequest(cleanId);

      emit(
        AdminBorrowRequestDetailState(
          status: AdminBorrowRequestDetailStatus.loaded,
          request: request,
          itemsLoading: true,
        ),
      );

      await _itemsSubscription?.cancel();
      _itemsSubscription = _service
          .watchRequestItems(cleanId)
          .listen(
            (items) {
              if (_requestId != cleanId) {
                return;
              }

              emit(
                state.copyWith(
                  status: AdminBorrowRequestDetailStatus.loaded,
                  items: items,
                  itemsLoading: false,
                  itemsError: '',
                ),
              );
            },
            onError: (_) {
              if (_requestId != cleanId) {
                return;
              }

              emit(
                state.copyWith(
                  itemsLoading: false,
                  itemsError: 'Detail item permintaan tidak dapat dimuat.',
                ),
              );
            },
          );
    } on BorrowRequestException catch (error) {
      emit(
        AdminBorrowRequestDetailState(
          status: AdminBorrowRequestDetailStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const AdminBorrowRequestDetailState(
          status: AdminBorrowRequestDetailStatus.failure,
          errorMessage: 'Permintaan peminjaman tidak dapat dimuat.',
        ),
      );
    }
  }

  /// Menyetujui request yang masih berstatus pending.
  Future<void> approve() async {
    final request = state.request;
    if (request == null || state.isProcessing || !request.isPending) {
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: AdminBorrowRequestActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _service.approveRequest(request.id);
      final updatedRequest = await _service.getRequest(request.id);

      emit(
        state.copyWith(
          request: updatedRequest,
          isProcessing: false,
          actionStatus: AdminBorrowRequestActionStatus.success,
          actionMessage:
              'Permintaan disetujui dan siap dilanjutkan ke penugasan aset.',
        ),
      );
    } on BorrowRequestException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AdminBorrowRequestActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AdminBorrowRequestActionStatus.failure,
          actionMessage: 'Permintaan tidak dapat disetujui saat ini.',
        ),
      );
    }
  }

  /// Menolak request pending dengan alasan yang diberikan Lab Admin.
  Future<void> reject(String reason) async {
    final request = state.request;
    if (request == null || state.isProcessing || !request.isPending) {
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: AdminBorrowRequestActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _service.rejectRequest(requestId: request.id, reason: reason);

      final updatedRequest = await _service.getRequest(request.id);

      emit(
        state.copyWith(
          request: updatedRequest,
          isProcessing: false,
          actionStatus: AdminBorrowRequestActionStatus.success,
          actionMessage: 'Permintaan ditolak dan alasan telah disimpan.',
        ),
      );
    } on BorrowRequestException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AdminBorrowRequestActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AdminBorrowRequestActionStatus.failure,
          actionMessage: 'Permintaan tidak dapat ditolak saat ini.',
        ),
      );
    }
  }

  /// Menghapus feedback mutation setelah notification ditampilkan oleh UI.
  void clearActionFeedback() {
    if (state.actionStatus == AdminBorrowRequestActionStatus.idle &&
        state.actionMessage.isEmpty) {
      return;
    }

    emit(
      state.copyWith(
        actionStatus: AdminBorrowRequestActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _itemsSubscription?.cancel();
    return super.close();
  }
}
