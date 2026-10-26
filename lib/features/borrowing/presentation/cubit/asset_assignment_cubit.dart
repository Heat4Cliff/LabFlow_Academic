import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/borrow_request_service.dart';
import '../../data/borrowing_assignment_service.dart';
import '../../domain/borrow_assignment.dart';
import '../cubit/asset_assignment_state.dart';

class AssetAssignmentCubit extends Cubit<AssetAssignmentState> {
  AssetAssignmentCubit(this._borrowRequestService, this._assignmentService)
    : super(const AssetAssignmentState());

  final BorrowRequestService _borrowRequestService;
  final BorrowingAssignmentService _assignmentService;

  StreamSubscription<List<AssignmentRequestItem>>? _itemSubscription;
  StreamSubscription<List<AssignableAsset>>? _assetSubscription;

  String? _requestId;

  /// Memuat request approved lalu memantau item dan aset tersedia.
  Future<void> load(String requestId) async {
    final cleanId = requestId.trim();

    if (cleanId.isEmpty) {
      emit(
        const AssetAssignmentState(
          status: AssetAssignmentStatus.failure,
          errorMessage: 'ID permintaan peminjaman tidak valid.',
        ),
      );
      return;
    }

    _requestId = cleanId;

    emit(const AssetAssignmentState(status: AssetAssignmentStatus.loading));

    try {
      final request = await _borrowRequestService.getRequest(cleanId);

      if (request.status != 'approved') {
        emit(
          AssetAssignmentState(
            status: AssetAssignmentStatus.failure,
            request: request,
            errorMessage: request.status == 'waiting_pickup'
                ? 'Aset untuk permintaan ini sudah ditugaskan dan menunggu pengambilan.'
                : 'Penugasan aset hanya dapat dilakukan untuk permintaan yang sudah disetujui.',
          ),
        );
        return;
      }

      emit(
        AssetAssignmentState(
          status: AssetAssignmentStatus.loaded,
          request: request,
          itemsLoading: true,
          assetsLoading: true,
        ),
      );

      await _itemSubscription?.cancel();
      await _assetSubscription?.cancel();

      _itemSubscription = _assignmentService
          .watchRequestItems(cleanId)
          .listen(
            (items) {
              if (_requestId != cleanId) {
                return;
              }

              final validItemIds = items.map((item) => item.documentId).toSet();
              final selections = Map<String, String>.from(
                state.selectedAssetByItem,
              )..removeWhere((itemId, _) => !validItemIds.contains(itemId));

              emit(
                state.copyWith(
                  status: AssetAssignmentStatus.loaded,
                  items: items,
                  selectedAssetByItem: selections,
                  itemsLoading: false,
                  errorMessage: '',
                ),
              );
            },
            onError: (_) {
              if (_requestId != cleanId) {
                return;
              }

              emit(
                state.copyWith(
                  status: AssetAssignmentStatus.failure,
                  itemsLoading: false,
                  errorMessage: 'Item permintaan tidak dapat dimuat saat ini.',
                ),
              );
            },
          );

      _assetSubscription = _assignmentService
          .watchAssignableAssets(request.labId)
          .listen(
            (assets) {
              if (_requestId != cleanId) {
                return;
              }

              final availableAssetIds = assets.map((asset) => asset.id).toSet();
              final selections =
                  Map<String, String>.from(state.selectedAssetByItem)
                    ..removeWhere(
                      (_, assetId) => !availableAssetIds.contains(assetId),
                    );

              emit(
                state.copyWith(
                  status: AssetAssignmentStatus.loaded,
                  assets: assets,
                  selectedAssetByItem: selections,
                  assetsLoading: false,
                  errorMessage: '',
                ),
              );
            },
            onError: (_) {
              if (_requestId != cleanId) {
                return;
              }

              emit(
                state.copyWith(
                  status: AssetAssignmentStatus.failure,
                  assetsLoading: false,
                  errorMessage:
                      'Daftar aset tersedia tidak dapat dimuat saat ini.',
                ),
              );
            },
          );
    } on BorrowRequestException catch (error) {
      emit(
        AssetAssignmentState(
          status: AssetAssignmentStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        const AssetAssignmentState(
          status: AssetAssignmentStatus.failure,
          errorMessage: 'Data penugasan aset tidak dapat dimuat.',
        ),
      );
    }
  }

  void selectAsset({required String requestItemId, required String? assetId}) {
    if (state.isProcessing) {
      return;
    }

    final selections = Map<String, String>.from(state.selectedAssetByItem);

    if (assetId == null || assetId.trim().isEmpty) {
      selections.remove(requestItemId);
    } else {
      selections[requestItemId] = assetId.trim();
    }

    emit(
      state.copyWith(
        selectedAssetByItem: selections,
        actionStatus: AssetAssignmentActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  Future<void> confirmAssignment() async {
    final request = state.request;

    if (request == null || state.isProcessing) {
      return;
    }

    final validationMessage = state.validationMessage;

    if (validationMessage != null) {
      emit(
        state.copyWith(
          actionStatus: AssetAssignmentActionStatus.warning,
          actionMessage: validationMessage,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: AssetAssignmentActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _assignmentService.assignApprovedRequest(
        requestId: request.id,
        assetByRequestItem: state.selectedAssetByItem,
      );

      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AssetAssignmentActionStatus.success,
          actionMessage:
              'Aset berhasil ditugaskan dan siap masuk proses pengambilan.',
        ),
      );
    } on BorrowingAssignmentException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AssetAssignmentActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: AssetAssignmentActionStatus.failure,
          actionMessage:
              'Penugasan aset gagal diproses. Periksa koneksi lalu coba lagi.',
        ),
      );
    }
  }

  void clearActionFeedback() {
    emit(
      state.copyWith(
        actionStatus: AssetAssignmentActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _itemSubscription?.cancel();
    await _assetSubscription?.cancel();
    return super.close();
  }
}
