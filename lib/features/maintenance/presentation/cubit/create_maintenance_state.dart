import '../../domain/maintenance_record.dart';

enum CreateMaintenanceStatus { initial, loading, ready, failure }

enum CreateMaintenanceActionStatus { idle, success, warning, failure }

class CreateMaintenanceState {
  const CreateMaintenanceState({
    this.status = CreateMaintenanceStatus.initial,
    this.assets = const <MaintenanceAssetOption>[],
    this.selectedAssetId,
    this.quantity = 1,
    this.condition = MaintenanceIssueCondition.minorDamage,
    this.description = '',
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = CreateMaintenanceActionStatus.idle,
    this.actionMessage = '',
  });

  final CreateMaintenanceStatus status;
  final List<MaintenanceAssetOption> assets;
  final String? selectedAssetId;
  final int quantity;
  final MaintenanceIssueCondition condition;
  final String description;
  final bool isProcessing;
  final String errorMessage;
  final CreateMaintenanceActionStatus actionStatus;
  final String actionMessage;

  MaintenanceAssetOption? get selectedAsset {
    final id = selectedAssetId;

    if (id == null) {
      return null;
    }

    for (final asset in assets) {
      if (asset.id == id) {
        return asset;
      }
    }

    return null;
  }

  String? get validationMessage {
    final asset = selectedAsset;

    if (asset == null) {
      return 'Pilih aset yang akan ditangani.';
    }

    if (quantity < 1) {
      return 'Jumlah unit maintenance minimal 1.';
    }

    if (quantity > asset.stock) {
      return 'Jumlah maintenance melebihi stok tersedia.';
    }

    if (description.trim().isEmpty) {
      return 'Deskripsi masalah wajib diisi.';
    }

    return null;
  }

  bool get canSubmit =>
      status == CreateMaintenanceStatus.ready &&
      !isProcessing &&
      validationMessage == null;

  CreateMaintenanceState copyWith({
    CreateMaintenanceStatus? status,
    List<MaintenanceAssetOption>? assets,
    String? selectedAssetId,
    bool clearSelectedAsset = false,
    int? quantity,
    MaintenanceIssueCondition? condition,
    String? description,
    bool? isProcessing,
    String? errorMessage,
    CreateMaintenanceActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return CreateMaintenanceState(
      status: status ?? this.status,
      assets: assets ?? this.assets,
      selectedAssetId: clearSelectedAsset
          ? null
          : selectedAssetId ?? this.selectedAssetId,
      quantity: quantity ?? this.quantity,
      condition: condition ?? this.condition,
      description: description ?? this.description,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
