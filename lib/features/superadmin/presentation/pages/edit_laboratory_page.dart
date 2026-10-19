import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/dialogs/labflow_confirmation_dialog.dart';
import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';
import '../../data/activity_log_service.dart';

class EditLaboratoryPage extends StatefulWidget {
  const EditLaboratoryPage({required this.laboratoryId, super.key});
  final String laboratoryId;
  @override
  State<EditLaboratoryPage> createState() => _EditLaboratoryPageState();
}

class _EditLaboratoryPageState extends State<EditLaboratoryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LaboratoryService _service = LaboratoryService();
  final ActivityLogService _activityLogService = ActivityLogService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _initialised = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String _status = 'active';

  /// Snapshot kondisi awal.
  ///
  /// Digunakan untuk mendeteksi perubahan data
  /// serta membuat Activity Log yang sesuai.
  String _originalName = '';
  String _originalCode = '';
  String _originalLocation = '';
  String _originalDescription = '';
  String _originalStatus = 'active';
  late final Future<Laboratory> _laboratoryFuture;
  @override
  void initState() {
    super.initState();
    _laboratoryFuture = _service.getLaboratory(widget.laboratoryId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Mengisi form satu kali setelah data
  /// berhasil dimuat dari Firestore.
  void _fillForm(Laboratory laboratory) {
    if (_initialised) {
      return;
    }
    _nameController.text = laboratory.name;
    _codeController.text = laboratory.code;
    _locationController.text = laboratory.location;
    _descriptionController.text = laboratory.description;
    _status = laboratory.status;
    _originalName = laboratory.name;
    _originalCode = laboratory.code;
    _originalLocation = laboratory.location;
    _originalDescription = laboratory.description;
    _originalStatus = laboratory.status;
    _initialised = true;
  }

  /// Memperbarui data laboratorium.
  ///
  /// Activity Log dibuat setelah update Firestore berhasil.
  Future<void> _update() async {
    FocusScope.of(context).unfocus();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || _isSaving || _isDeleting) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      final newName = _nameController.text.trim();
      final newCode = _codeController.text.trim().toUpperCase();
      final newLocation = _locationController.text.trim();
      final newDescription = _descriptionController.text.trim();
      final newStatus = _status;

      /// Mengecek apakah data umum berubah.
      final generalDataChanged =
          _originalName.trim() != newName ||
          _originalCode.trim().toUpperCase() != newCode ||
          _originalLocation.trim() != newLocation ||
          _originalDescription.trim() != newDescription;

      /// Mengecek apakah status berubah.
      final statusChanged = _originalStatus != newStatus;

      /// =====================================================
      /// UPDATE FIRESTORE
      /// =====================================================
      await _service.updateLaboratory(
        laboratoryId: widget.laboratoryId,
        name: newName,
        code: newCode,
        description: newDescription,
        location: newLocation,
        status: newStatus,
      );

      /// =====================================================
      /// ACTIVITY LOG — DATA UMUM
      /// =====================================================
      if (generalDataChanged) {
        await _activityLogService.createActivity(
          type: 'laboratory',
          title: 'Laboratorium diperbarui',
          description: '$newCode — $newName berhasil diperbarui.',
          reference: newCode,
        );
      }

      /// =====================================================
      /// ACTIVITY LOG — STATUS
      /// =====================================================
      if (statusChanged) {
        if (_originalStatus == 'active' && newStatus == 'inactive') {
          await _activityLogService.createActivity(
            type: 'laboratory',
            title: 'Laboratorium dinonaktifkan',
            description: '$newCode — $newName dinonaktifkan.',
            reference: newCode,
          );
        } else if (_originalStatus == 'inactive' && newStatus == 'active') {
          await _activityLogService.createActivity(
            type: 'laboratory',
            title: 'Laboratorium diaktifkan kembali',
            description: '$newCode — $newName diaktifkan kembali.',
            reference: newCode,
          );
        } else {
          await _activityLogService.createActivity(
            type: 'laboratory',
            title: 'Status laboratorium diubah',
            description:
                'Status $newCode — $newName diubah '
                'dari ${_statusLabel(_originalStatus)} '
                'menjadi ${_statusLabel(newStatus)}.',
            reference: newCode,
          );
        }
      }

      /// Memperbarui snapshot lokal setelah
      /// operasi berhasil.
      _originalName = newName;
      _originalCode = newCode;
      _originalLocation = newLocation;
      _originalDescription = newDescription;
      _originalStatus = newStatus;
      if (!mounted) {
        return;
      }

      /// Notifikasi sukses ditampilkan pada halaman
      /// Laboratory Management setelah menerima
      /// result "updated".
      context.pop('updated');
    } on LaboratoryException catch (error) {
      if (!mounted) {
        return;
      }

      /// Error dari business rule/service ditampilkan
      /// sebagai Warning karena biasanya merupakan
      /// kondisi yang dapat diperbaiki pengguna.
      _showMessage(
        error.message,
        type: LabFlowNotificationType.warning,
        title: 'Perubahan tidak dapat disimpan',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage(
        'Gagal memperbarui laboratorium.',
        type: LabFlowNotificationType.error,
        title: 'Terjadi kesalahan',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Menghapus laboratorium.
  ///
  /// Confirmation menggunakan shared
  /// LabFlow Confirmation Dialog.
  ///
  /// LaboratoryService tetap menjadi penjaga utama:
  /// lab yang sudah memiliki riwayat membership
  /// tidak boleh dihapus permanen.
  Future<void> _delete() async {
    if (_isDeleting || _isSaving) {
      return;
    }
    final laboratoryName = _nameController.text.trim();
    final laboratoryCode = _codeController.text.trim().toUpperCase();

    /// =====================================================
    /// SHARED DELETE CONFIRMATION
    /// =====================================================
    final confirmed = await showDeleteConfirmationDialog(
      context: context,
      title: 'Hapus laboratorium ini?',
      description:
          '$laboratoryCode — $laboratoryName akan dihapus permanen '
          'jika belum memiliki riwayat membership. '
          'Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Ya, Hapus Laboratorium',
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _isDeleting = true;
    });
    try {
      /// Simpan identitas sebelum document dihapus.
      ///
      /// Data ini tetap diperlukan untuk Activity Log.
      final deletedName = _originalName.trim();
      final deletedCode = _originalCode.trim().toUpperCase();

      /// =====================================================
      /// DELETE FIRESTORE
      /// =====================================================
      await _service.deleteLaboratory(widget.laboratoryId);

      /// =====================================================
      /// ACTIVITY LOG
      /// =====================================================
      await _activityLogService.createActivity(
        type: 'laboratory',
        title: 'Laboratorium dihapus',
        description: '$deletedCode — $deletedName dihapus dari sistem.',
        reference: deletedCode,
      );
      if (!mounted) {
        return;
      }

      /// Notifikasi sukses akan ditampilkan oleh
      /// halaman Laboratory Management setelah
      /// menerima result "deleted".
      context.pop('deleted');
    } on LaboratoryException catch (error) {
      if (!mounted) {
        return;
      }

      /// Contoh:
      /// Laboratorium mempunyai riwayat membership
      /// sehingga tidak boleh di-hard-delete.
      ///
      /// Ini bukan crash aplikasi sehingga kita gunakan
      /// floating notification bertipe Warning.
      _showMessage(
        error.message,
        type: LabFlowNotificationType.warning,
        title: 'Laboratorium tidak dapat dihapus',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      /// Unexpected error menggunakan tipe Error.
      _showMessage(
        'Gagal menghapus laboratorium.',
        type: LabFlowNotificationType.error,
        title: 'Penghapusan gagal',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  /// Mengubah status internal Firestore
  /// menjadi label ramah pengguna.
  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'inactive':
        return 'Tidak Aktif';
      default:
        return status;
    }
  }

  /// Menampilkan shared floating notification LabFlow.
  ///
  /// Tidak lagi menggunakan SnackBar hitam bawaan Flutter.
  void _showMessage(
    String message, {
    LabFlowNotificationType type = LabFlowNotificationType.error,
    String? title,
  }) {
    showLabFlowNotification(
      context: context,
      message: message,
      type: type,
      title: title,
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        title: const Text(
          'Edit Laboratorium',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<Laboratory>(
        future: _laboratoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LabFlowLoadingState(
              title: 'Memuat laboratorium',
              message: 'Mengambil data laboratorium yang dipilih.',
            );
          }
          if (snapshot.hasError) {
            return const LabFlowConnectionErrorState(
              title: 'Laboratorium tidak dapat dimuat',
              message:
                  'Data laboratorium tidak dapat diambil saat ini. '
                  'Periksa koneksi Anda lalu coba lagi.',
            );
          }
          if (snapshot.data == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Data laboratorium tidak ditemukan.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final laboratory = snapshot.data!;
          _fillForm(laboratory);
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perbarui Laboratorium',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Perbarui informasi dan status operasional laboratorium.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 24),

              /// =================================================
              /// NAMA LABORATORIUM
              /// =================================================
              TextFormField(
                controller: _nameController,
                validator: _required,
                enabled: !_isSaving && !_isDeleting,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Nama Laboratorium',
                  Icons.science_outlined,
                ),
              ),
              const SizedBox(height: 16),

              /// =================================================
              /// KODE LABORATORIUM
              /// =================================================
              TextFormField(
                controller: _codeController,
                validator: _required,
                enabled: !_isSaving && !_isDeleting,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: _inputDecoration(
                  'Kode Laboratorium',
                  Icons.qr_code_rounded,
                ),
              ),
              const SizedBox(height: 16),

              /// =================================================
              /// LOKASI
              /// =================================================
              TextFormField(
                controller: _locationController,
                validator: _required,
                enabled: !_isSaving && !_isDeleting,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Lokasi',
                  Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),

              /// =================================================
              /// DESKRIPSI
              /// =================================================
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                enabled: !_isSaving && !_isDeleting,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration('Deskripsi', Icons.notes_rounded),
              ),
              const SizedBox(height: 24),

              /// =================================================
              /// STATUS
              /// =================================================
              const Text(
                'Status Laboratorium',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: 'active',
                    label: Text('Aktif'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment<String>(
                    value: 'inactive',
                    label: Text('Tidak Aktif'),
                    icon: Icon(Icons.block_outlined),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: _isSaving || _isDeleting
                    ? null
                    : (selection) {
                        setState(() {
                          _status = selection.first;
                        });
                      },
              ),
              const SizedBox(height: 28),

              /// =================================================
              /// UPDATE
              /// =================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving || _isDeleting ? null : _update,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF444444),
                    shape: const StadiumBorder(),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_outlined, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              /// =================================================
              /// DELETE
              /// =================================================
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isDeleting || _isSaving ? null : _delete,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                  label: Text(
                    _isDeleting ? 'Menghapus...' : 'Hapus Laboratorium',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBD3232),
                    side: const BorderSide(color: Color(0xFFBD3232)),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8DDD0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF111111), width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD8DDD0)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBD3232)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFBD3232), width: 1.4),
      ),
    );
  }
}
