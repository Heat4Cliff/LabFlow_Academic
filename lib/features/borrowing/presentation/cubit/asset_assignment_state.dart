import '../../domain/borrow_assignment.dart';
import '../../domain/borrow_request.dart';

enum AssetAssignmentStatus { initial, loading, loaded, failure }

enum AssetAssignmentActionStatus { idle, success, warning, failure }

class AssetAssignmentState {
  const AssetAssignmentState({
    this.status = AssetAssignmentStatus.initial,
    this.request,
    this.items = const <AssignmentRequestItem>[],
    this.assets = const <AssignableAsset>[],
    this.selectedAssetByItem = const <String, String>{},
    this.itemsLoading = false,
    this.assetsLoading = false,
    this.isProcessing = false,
    this.errorMessage = '',
    this.actionStatus = AssetAssignmentActionStatus.idle,
    this.actionMessage = '',
  });

  final AssetAssignmentStatus status;
  final BorrowRequest? request;
  final List<AssignmentRequestItem> items;
  final List<AssignableAsset> assets;
  final Map<String, String> selectedAssetByItem;
  final bool itemsLoading;
  final bool assetsLoading;
  final bool isProcessing;
  final String errorMessage;
  final AssetAssignmentActionStatus actionStatus;
  final String actionMessage;

  AssignableAsset? assetById(String? assetId) {
    if (assetId == null || assetId.isEmpty) {
      return null;
    }

    for (final asset in assets) {
      if (asset.id == assetId) {
        return asset;
      }
    }

    return null;
  }

  String? get validationMessage {
    if (itemsLoading || assetsLoading) {
      return 'Data penugasan masih dimuat.';
    }

    if (items.isEmpty) {
      return 'Permintaan tidak memiliki item yang dapat ditugaskan.';
    }

    for (final item in items) {
      final assetId = selectedAssetByItem[item.documentId];

      if (assetId == null || assetId.isEmpty) {
        return 'Pilih aset untuk seluruh item permintaan.';
      }
    }

    final requiredQuantityByAsset = <String, int>{};

    for (final item in items) {
      final assetId = selectedAssetByItem[item.documentId]!;

      requiredQuantityByAsset.update(
        assetId,
        (current) => current + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    for (final entry in requiredQuantityByAsset.entries) {
      final asset = assetById(entry.key);

      if (asset == null) {
        return 'Salah satu aset yang dipilih sudah tidak tersedia.';
      }

      if (asset.stock < entry.value) {
        return 'Stok ${asset.name} hanya ${asset.stock}, '
            'sedangkan kebutuhan ${entry.value}.';
      }
    }

    return null;
  }

  bool get canSubmit =>
      status == AssetAssignmentStatus.loaded &&
      !isProcessing &&
      validationMessage == null;

  AssetAssignmentState copyWith({
    AssetAssignmentStatus? status,
    BorrowRequest? request,
    List<AssignmentRequestItem>? items,
    List<AssignableAsset>? assets,
    Map<String, String>? selectedAssetByItem,
    bool? itemsLoading,
    bool? assetsLoading,
    bool? isProcessing,
    String? errorMessage,
    AssetAssignmentActionStatus? actionStatus,
    String? actionMessage,
  }) {
    return AssetAssignmentState(
      status: status ?? this.status,
      request: request ?? this.request,
      items: items ?? this.items,
      assets: assets ?? this.assets,
      selectedAssetByItem: selectedAssetByItem ?? this.selectedAssetByItem,
      itemsLoading: itemsLoading ?? this.itemsLoading,
      assetsLoading: assetsLoading ?? this.assetsLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage ?? this.errorMessage,
      actionStatus: actionStatus ?? this.actionStatus,
      actionMessage: actionMessage ?? this.actionMessage,
    );
  }
}
