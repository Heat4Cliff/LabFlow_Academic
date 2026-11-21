import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/presentation/navigation/labflow_back_fallback.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../asset/data/asset_service.dart';
import '../../../asset/domain/laboratory_asset.dart';
import '../../../laboratory/data/laboratory_service.dart';
import '../../data/asset_qr_print_service.dart';

class AssetDetailPage extends StatefulWidget {
  const AssetDetailPage({
    required this.assetId,
    this.assetService,
    this.laboratoryService,
    this.qrPrintService,
    super.key,
  });

  final String assetId;
  final AssetService? assetService;
  final LaboratoryService? laboratoryService;
  final AssetQrPrintService? qrPrintService;

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailData {
  const _AssetDetailData({
    required this.asset,
    required this.laboratoryName,
  });

  final LaboratoryAsset asset;
  final String laboratoryName;
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  late final AssetService _assetService;
  late final LaboratoryService _laboratoryService;
  late final AssetQrPrintService _qrPrintService;

  late Future<_AssetDetailData> _assetFuture;
  bool _isPrintingQr = false;
  bool _isSharingQr = false;

  bool get _isQrBusy => _isPrintingQr || _isSharingQr;

  @override
  void initState() {
    super.initState();
    _assetService = widget.assetService ?? AssetService();
    _laboratoryService = widget.laboratoryService ?? LaboratoryService();
    _qrPrintService = widget.qrPrintService ?? AssetQrPrintService();
    _assetFuture = _loadAsset();
  }

  Future<_AssetDetailData> _loadAsset() async {
    final asset = await _assetService.getAsset(widget.assetId);
    final laboratoryName = await _resolveLaboratoryName(asset);
    return _AssetDetailData(asset: asset, laboratoryName: laboratoryName);
  }

  Future<String> _resolveLaboratoryName(LaboratoryAsset asset) async {
    final labId = asset.labId.trim();
    if (labId.isEmpty) {
      return asset.location.trim().isNotEmpty
          ? asset.location.trim()
          : 'Laboratorium LabFlow';
    }
    try {
      final lab = await _laboratoryService.getLaboratory(labId);
      if (lab.name.trim().isNotEmpty) {
        return lab.name.trim();
      }
    } catch (_) {
      // Fallback safely when laboratory metadata is temporarily unavailable.
    }
    return asset.location.trim().isNotEmpty ? asset.location.trim() : labId;
  }

  Future<void> _editAsset(LaboratoryAsset asset) async {
    final result = await context.push<String>(
      '/lab-admin/assets/${asset.id}/edit',
    );

    if (!mounted || result == null) {
      return;
    }

    if (result == 'deleted') {
      context.pop('deleted');
      return;
    }

    if (result == 'updated') {
      setState(() {
        _assetFuture = _loadAsset();
      });

      showLabFlowNotification(
        context: context,
        title: 'Aset diperbarui',
        message: 'Perubahan data aset berhasil disimpan.',
        type: LabFlowNotificationType.success,
      );
    }
  }

  Future<void> _copyQrValue(String qrValue) async {
    await Clipboard.setData(ClipboardData(text: qrValue));

    if (!mounted) {
      return;
    }

    showLabFlowNotification(
      context: context,
      title: 'Identitas QR disalin',
      message: 'Nilai QR aset berhasil disalin ke clipboard.',
      type: LabFlowNotificationType.success,
    );
  }

  Future<void> _printQr(LaboratoryAsset asset, String laboratoryName) async {
    if (_isQrBusy) return;
    setState(() => _isPrintingQr = true);

    try {
      final printed = await _qrPrintService.printAssetQrLabel(
        asset: asset,
        laboratoryName: laboratoryName,
      );
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: printed ? 'Siap dicetak' : 'Pencetakan dibatalkan',
        message: printed
            ? 'Label QR PDF siap untuk dicetak.'
            : 'Proses cetak label QR dibatalkan.',
        type: printed
            ? LabFlowNotificationType.success
            : LabFlowNotificationType.info,
      );
    } on AssetQrPrintException catch (error) {
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: 'QR belum valid',
        message: error.message,
        type: LabFlowNotificationType.error,
      );
    } catch (_) {
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: 'Gagal mencetak QR',
        message: 'Terjadi kesalahan saat menyiapkan atau mencetak PDF label QR.',
        type: LabFlowNotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isPrintingQr = false);
      }
    }
  }

  Future<void> _shareQrPdf(
    LaboratoryAsset asset,
    String laboratoryName,
  ) async {
    if (_isQrBusy) return;
    setState(() => _isSharingQr = true);

    try {
      final shared = await _qrPrintService.shareAssetQrLabel(
        asset: asset,
        laboratoryName: laboratoryName,
      );
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: shared ? 'PDF label siap' : 'Pembagian dibatalkan',
        message: shared
            ? 'Dokumen PDF label QR siap disimpan atau dibagikan.'
            : 'Penyimpanan atau pembagian PDF dibatalkan.',
        type: shared
            ? LabFlowNotificationType.success
            : LabFlowNotificationType.info,
      );
    } on AssetQrPrintException catch (error) {
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: 'QR belum valid',
        message: error.message,
        type: LabFlowNotificationType.error,
      );
    } catch (_) {
      if (!mounted) return;
      showLabFlowNotification(
        context: context,
        title: 'Gagal membuat PDF',
        message: 'Terjadi kesalahan saat menyiapkan dokumen PDF label QR.',
        type: LabFlowNotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingQr = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => popOrGo(context, '/lab-admin/assets'),
        ),
        backgroundColor: const Color(0xFFF6F9EF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Detail Aset',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ),
      body: FutureBuilder<_AssetDetailData>(
        future: _assetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LabFlowLoadingState(
              title: 'Memuat detail aset',
              message: 'Mengambil informasi aset yang dipilih.',
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;

            if (error is AssetException) {
              return _buildUnavailableState(error.message);
            }

            return const LabFlowConnectionErrorState(
              title: 'Detail aset tidak dapat dimuat',
              message:
                  'Data aset tidak dapat diambil saat ini. '
                  'Periksa koneksi Anda lalu coba lagi.',
            );
          }

          final data = snapshot.data;

          if (data == null) {
            return _buildUnavailableState('Data aset tidak ditemukan.');
          }

          return _buildContent(data.asset, data.laboratoryName);
        },
      ),
    );
  }

  Widget _buildContent(LaboratoryAsset asset, String laboratoryName) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(asset),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${asset.code} · ${asset.category}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF737A86),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(asset.status),
              ],
            ),
            const SizedBox(height: 22),
            _buildInfoCard(asset),
            const SizedBox(height: 16),
            _buildDescriptionCard(asset),
            const SizedBox(height: 16),
            _buildQrCard(asset, laboratoryName),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _editAsset(asset),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                icon: const Icon(Icons.edit_outlined, size: 20),
                label: const Text(
                  'Edit Aset',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(LaboratoryAsset asset) {
    final imageUrl = asset.imageUrl.trim();

    Widget fallback() {
      return Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBCB),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDDE2D5)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _assetIcon(asset.category),
              size: 64,
              color: const Color(0xFF111111),
            ),
            const SizedBox(height: 10),
            const Text(
              'Belum ada foto aset',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5D6458),
              ),
            ),
          ],
        ),
      );
    }

    if (imageUrl.isEmpty) {
      return fallback();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 220,
        width: double.infinity,
        color: Colors.white,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          cacheWidth: 1000,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          },
          errorBuilder: (_, _, _) => fallback(),
        ),
      ),
    );
  }

  Widget _buildInfoCard(LaboratoryAsset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Stok',
            value: asset.stock.toString(),
          ),
          _divider(),
          _buildInfoRow(
            icon: Icons.place_outlined,
            label: 'Lokasi',
            value: asset.location,
          ),
          _divider(),
          _buildInfoRow(
            icon: Icons.health_and_safety_outlined,
            label: 'Kondisi',
            value: _conditionLabel(asset.condition),
          ),
          _divider(),
          _buildInfoRow(
            icon: Icons.category_outlined,
            label: 'Kategori',
            value: asset.category,
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(LaboratoryAsset asset) {
    final description = asset.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notes_rounded, size: 20, color: Color(0xFF5F6672)),
              SizedBox(width: 10),
              Text(
                'Deskripsi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description.isEmpty ? 'Tidak ada deskripsi.' : description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.55,
              color: Color(0xFF5D6458),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard(LaboratoryAsset asset, String laboratoryName) {
    final qrValue = asset.qrValue.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 22, color: Color(0xFF5F6672)),
              SizedBox(width: 10),
              Text(
                'QR Aset',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pindai QR ini untuk mengidentifikasi aset dengan cepat.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF7A8190),
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: qrValue.isEmpty
                  ? null
                  : () => _showQrDialog(asset, laboratoryName),
              child: Container(
                width: 224,
                height: 224,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE5E8E0)),
                ),
                child: qrValue.isEmpty
                    ? const Center(
                        child: Text(
                          'QR belum tersedia',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7A8190),
                          ),
                        ),
                      )
                    : QrImageView(
                        data: qrValue,
                        version: QrVersions.auto,
                        size: 200,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF111111),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF111111),
                        ),
                        errorStateBuilder: (context, error) {
                          return const Center(
                            child: Text(
                              'QR tidak dapat dibuat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFBD3232),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
          if (qrValue.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Ketuk QR untuk memperbesar',
                style: TextStyle(fontSize: 11, color: Color(0xFF8A9099)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Identitas QR',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF7A8190),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        qrValue.isEmpty ? '-' : qrValue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Salin identitas QR',
                  onPressed: qrValue.isEmpty
                      ? null
                      : () => _copyQrValue(qrValue),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isQrBusy
                  ? null
                  : () => _printQr(asset, laboratoryName),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              icon: _isPrintingQr
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.print_outlined, size: 18),
              label: Text(
                _isPrintingQr ? 'Menyiapkan...' : 'Cetak QR',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _isQrBusy
                  ? null
                  : () => _shareQrPdf(asset, laboratoryName),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111111),
                side: const BorderSide(color: Color(0xFFDDE2D5)),
                shape: const StadiumBorder(),
              ),
              icon: _isSharingQr
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_outlined, size: 18),
              label: Text(
                _isSharingQr ? 'Membuat PDF...' : 'Simpan / Bagikan PDF',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showQrDialog(
    LaboratoryAsset asset,
    String laboratoryName,
  ) async {
    final qrValue = asset.qrValue.trim();

    if (qrValue.isEmpty) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'QR Aset',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111111),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            asset.code,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF7A8190),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: 292,
                  height: 292,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE5E8E0)),
                  ),
                  child: QrImageView(
                    data: qrValue,
                    version: QrVersions.auto,
                    size: 268,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF111111),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  asset.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  qrValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8190),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isQrBusy
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                            _printQr(asset, laboratoryName);
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text(
                      'Cetak QR',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _copyQrValue(qrValue);
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Salin Identitas QR'),
                  ),
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF5F6672)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8190),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111111),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Color(0xFFE5E8E0)),
    );
  }

  Widget _buildStatusBadge(String status) {
    final background = switch (status) {
      'available' => const Color(0xFFE5F6EC),
      'borrowed' => const Color(0xFFE8EEFF),
      'maintenance' => const Color(0xFFFFF0CF),
      'inactive' => const Color(0xFFF0F1EE),
      _ => const Color(0xFFF0F1EE),
    };

    final foreground = switch (status) {
      'available' => const Color(0xFF188A55),
      'borrowed' => const Color(0xFF3559A6),
      'maintenance' => const Color(0xFFA86E00),
      'inactive' => const Color(0xFF6B7280),
      _ => const Color(0xFF6B7280),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildUnavailableState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0CF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: Color(0xFFA86E00),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Aset tidak tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'borrowed':
        return 'Borrowed';
      case 'maintenance':
        return 'Maintenance';
      case 'inactive':
        return 'Inactive';
      default:
        return status;
    }
  }

  String _conditionLabel(String condition) {
    switch (condition) {
      case 'good':
        return 'Baik';
      case 'minor_damage':
        return 'Kerusakan Ringan';
      case 'damaged':
        return 'Rusak';
      default:
        return condition;
    }
  }

  IconData _assetIcon(String category) {
    final value = category.toLowerCase();

    if (value.contains('komputer') ||
        value.contains('laptop') ||
        value.contains('pc')) {
      return Icons.computer_rounded;
    }

    if (value.contains('jaringan') ||
        value.contains('router') ||
        value.contains('network')) {
      return Icons.router_outlined;
    }

    if (value.contains('elektronik') ||
        value.contains('arduino') ||
        value.contains('esp')) {
      return Icons.memory_rounded;
    }

    return Icons.inventory_2_outlined;
  }
}
