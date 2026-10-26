import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/maintenance_service.dart';
import '../../domain/maintenance_record.dart';
import 'create_maintenance_state.dart';

class CreateMaintenanceCubit extends Cubit<CreateMaintenanceState> {
  CreateMaintenanceCubit(
    this._service,
    this._laboratoryId, {
    String? initialAssetId,
    String sourceType = 'manual',
    String? sourceId,
    String initialDescription = '',
  }) : _initialAssetId = initialAssetId?.trim(),
       _sourceType = sourceType.trim(),
       _sourceId = sourceId?.trim(),
       super(CreateMaintenanceState(description: initialDescription));

  final MaintenanceService _service;
  final String _laboratoryId;
  final String? _initialAssetId;
  final String _sourceType;
  final String? _sourceId;

  StreamSubscription<List<MaintenanceAssetOption>>? _assetSubscription;

  void start() {
    if (_laboratoryId.trim().isEmpty) {
      emit(
        const CreateMaintenanceState(
          status: CreateMaintenanceStatus.failure,
          errorMessage: 'Laboratorium tidak valid.',
        ),
      );
      return;
    }

    emit(state.copyWith(status: CreateMaintenanceStatus.loading));

    _assetSubscription = _service
        .watchAvailableAssets(_laboratoryId)
        .listen(
          (assets) {
            final selectedId = state.selectedAssetId;
            final selectionStillValid =
                selectedId != null &&
                assets.any((asset) => asset.id == selectedId);

            final preferredId =
                selectedId ??
                (_initialAssetId != null &&
                        assets.any((asset) => asset.id == _initialAssetId)
                    ? _initialAssetId
                    : null);

            emit(
              state.copyWith(
                status: CreateMaintenanceStatus.ready,
                assets: assets,
                selectedAssetId: preferredId,
                clearSelectedAsset: selectedId != null && !selectionStillValid,
                errorMessage: '',
              ),
            );
          },
          onError: (_) {
            emit(
              state.copyWith(
                status: CreateMaintenanceStatus.failure,
                errorMessage: 'Aset tersedia tidak dapat dimuat.',
              ),
            );
          },
        );
  }

  void selectAsset(String? assetId) {
    emit(
      state.copyWith(
        selectedAssetId: assetId,
        clearSelectedAsset: assetId == null,
        quantity: 1,
        actionStatus: CreateMaintenanceActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void setQuantity(int value) {
    emit(
      state.copyWith(
        quantity: value < 1 ? 1 : value,
        actionStatus: CreateMaintenanceActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void setCondition(MaintenanceIssueCondition value) {
    emit(
      state.copyWith(
        condition: value,
        actionStatus: CreateMaintenanceActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  void setDescription(String value) {
    emit(
      state.copyWith(
        description: value,
        actionStatus: CreateMaintenanceActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  Future<void> submit() async {
    final asset = state.selectedAsset;

    if (state.isProcessing) {
      return;
    }

    final validation = state.validationMessage;

    if (validation != null || asset == null) {
      emit(
        state.copyWith(
          actionStatus: CreateMaintenanceActionStatus.warning,
          actionMessage: validation ?? 'Data maintenance belum lengkap.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isProcessing: true,
        actionStatus: CreateMaintenanceActionStatus.idle,
        actionMessage: '',
      ),
    );

    try {
      await _service.createManualMaintenance(
        laboratoryId: _laboratoryId,
        assetId: asset.id,
        quantity: state.quantity,
        condition: state.condition,
        description: state.description,
        sourceType: _sourceType,
        sourceId: _sourceId,
      );

      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: CreateMaintenanceActionStatus.success,
          actionMessage: 'Maintenance baru berhasil dibuat.',
        ),
      );
    } on MaintenanceException catch (error) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: CreateMaintenanceActionStatus.warning,
          actionMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isProcessing: false,
          actionStatus: CreateMaintenanceActionStatus.failure,
          actionMessage:
              'Maintenance gagal dibuat. Periksa koneksi lalu coba lagi.',
        ),
      );
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        actionStatus: CreateMaintenanceActionStatus.idle,
        actionMessage: '',
      ),
    );
  }

  @override
  Future<void> close() async {
    await _assetSubscription?.cancel();
    return super.close();
  }
}
