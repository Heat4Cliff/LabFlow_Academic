import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/student_qr_asset_service.dart';
import '../student_navigation.dart';
import '../widgets/student_ui.dart';

enum _CameraViewState { checking, ready, denied, permanentlyDenied, error }

class StudentQrScannerPage extends StatefulWidget {
  const StudentQrScannerPage({super.key});

  @override
  State<StudentQrScannerPage> createState() => _StudentQrScannerPageState();
}

class _StudentQrScannerPageState extends State<StudentQrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final StudentQrAssetResolver _resolver = StudentQrAssetResolver(
    FirestoreStudentAssetLookup(),
  );
  final TextEditingController _manualController = TextEditingController();

  _CameraViewState _cameraState = _CameraViewState.checking;
  String _message = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestCamera());
  }

  @override
  void dispose() {
    _manualController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestCamera() async {
    if (!mounted) return;
    setState(() => _cameraState = _CameraViewState.checking);
    try {
      final permission = await Permission.camera.request();
      if (!mounted) return;
      if (permission.isPermanentlyDenied) {
        setState(() => _cameraState = _CameraViewState.permanentlyDenied);
      } else if (!permission.isGranted) {
        setState(() => _cameraState = _CameraViewState.denied);
      } else {
        setState(() => _cameraState = _CameraViewState.ready);
        WidgetsBinding.instance.addPostFrameCallback((_) => _startCamera());
      }
    } catch (_) {
      if (mounted) setState(() => _cameraState = _CameraViewState.error);
    }
  }

  Future<void> _startCamera() async {
    if (!mounted || _cameraState != _CameraViewState.ready) return;
    try {
      await _controller.start();
    } on MobileScannerException catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraState =
            error.errorCode == MobileScannerErrorCode.permissionDenied
            ? _CameraViewState.denied
            : _CameraViewState.error;
      });
    } catch (_) {
      if (mounted) setState(() => _cameraState = _CameraViewState.error);
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;
    await _resolve(value, manual: false);
  }

  Future<void> _resolve(String value, {required bool manual}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = '';
    });
    try {
      if (_cameraState == _CameraViewState.ready) {
        await _controller.stop();
      }
      final result = await _resolver.resolve(value, manual: manual);
      if (!mounted) return;
      switch (result.status) {
        case StudentQrResolutionStatus.found:
          await context.push<void>(
            '/student/assets/${Uri.encodeComponent(result.assetId!)}',
          );
          if (!mounted) return;
        case StudentQrResolutionStatus.invalid:
          setState(() => _message = 'QR tidak dikenali sebagai aset LabFlow.');
        case StudentQrResolutionStatus.notFound:
          setState(
            () => _message = 'Aset tidak ditemukan di data yang tersedia. Jika sedang offline, hubungkan internet atau muat aset ini ke cache terlebih dahulu.',
          );
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(
        () => _message = error.code == 'permission-denied'
            ? 'Akses baca aset ditolak.'
            : error.code == 'unavailable'
            ? 'Aset ini belum tersedia di cache. Hubungkan internet lalu buka detail aset sekali sebelum memindainya offline.'
            : 'Gagal mencari aset. Periksa koneksi dan coba lagi.',
      );
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Gagal mencari aset. Coba lagi.');
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _startCamera();
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: context.canPop(),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && !context.canPop()) context.go('/student');
    },
    child: Scaffold(
      backgroundColor: studentPaper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            StudentBackHeader(
              title: 'Scan QR Aset',
              onBack: () => studentPopOrGo(context, '/student'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Arahkan kamera ke QR pada label aset.',
              style: TextStyle(fontSize: 14, color: studentMuted),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.08,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ColoredBox(
                  color: studentInk,
                  child: _cameraState == _CameraViewState.ready
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: _controller,
                              onDetect: _onDetect,
                              errorBuilder: (context, error) => _cameraIssue(
                                error.errorCode ==
                                        MobileScannerErrorCode.permissionDenied
                                    ? 'Izin kamera ditolak.'
                                    : 'Kamera tidak dapat dibuka.',
                              ),
                            ),
                            IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 220,
                                  height: 220,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: studentLime,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: IconButton.filled(
                                tooltip: 'Nyalakan atau matikan flash',
                                onPressed: _controller.toggleTorch,
                                icon: const Icon(Icons.flash_on_rounded),
                              ),
                            ),
                          ],
                        )
                      : _cameraIssue(_cameraMessage),
                ),
              ),
            ),
            if (_cameraState == _CameraViewState.denied ||
                _cameraState == _CameraViewState.permanentlyDenied ||
                _cameraState == _CameraViewState.error) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _requestCamera,
                    child: const Text('Coba Lagi'),
                  ),
                  if (_cameraState == _CameraViewState.permanentlyDenied)
                    OutlinedButton(
                      onPressed: openAppSettings,
                      child: const Text('Buka Pengaturan'),
                    ),
                ],
              ),
            ],
            if (_message.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_message, style: const TextStyle(color: studentPinkText)),
            ],
            const SizedBox(height: 24),
            const Text(
              'Input Kode Manual',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Masukkan kode aset atau nilai QR jika kamera tidak tersedia.',
              style: TextStyle(fontSize: 12, color: studentMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _manualController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) =>
                  _resolve(_manualController.text, manual: true),
              decoration: InputDecoration(
                hintText: 'Contoh: IOT-ESP-001',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _resolve(_manualController.text, manual: true),
              style: FilledButton.styleFrom(
                backgroundColor: studentInk,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Cari Aset'),
            ),
          ],
        ),
      ),
    ),
  );

  String get _cameraMessage => switch (_cameraState) {
    _CameraViewState.checking => 'Memeriksa izin kamera…',
    _CameraViewState.ready => '',
    _CameraViewState.denied =>
      'Izin kamera ditolak. Coba lagi atau input kode.',
    _CameraViewState.permanentlyDenied =>
      'Izin kamera diblokir. Buka Pengaturan atau input kode.',
    _CameraViewState.error => 'Kamera tidak tersedia. Gunakan input kode.',
  };

  Widget _cameraIssue(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    ),
  );
}
