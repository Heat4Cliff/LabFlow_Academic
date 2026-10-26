import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../../shared/presentation/states/labflow_connection_error_state.dart';
import '../../../../shared/presentation/states/labflow_loading_state.dart';
import '../../../asset/data/asset_image_service.dart';
import '../../../asset/data/asset_service.dart';
import '../../../asset/domain/laboratory_asset.dart';

class EditAssetPage extends StatefulWidget {
  const EditAssetPage({required this.assetId, super.key});

  final String assetId;

  @override
  State<EditAssetPage> createState() => _EditAssetPageState();
}

class _EditAssetPageState extends State<EditAssetPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AssetService _assetService = AssetService();
  final AssetImageService _assetImageService = AssetImageService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  late final Future<LaboratoryAsset> _assetFuture;

  XFile? _selectedImage;
  String _imageUrl = '';
  String _condition = 'good';
  String _status = 'available';
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isBusy => _isSaving || _isDeleting;

  @override
  void initState() {
    super.initState();
    _assetFuture = _loadAsset();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<LaboratoryAsset> _loadAsset() async {
    final asset = await _assetService.getAsset(widget.assetId);

    _nameController.text = asset.name;
    _codeController.text = asset.code;
    _categoryController.text = asset.category;
    _stockController.text = asset.stock.toString();
    _locationController.text = asset.location;
    _descriptionController.text = asset.description;
    _condition = asset.condition;
    _status = asset.status;
    _imageUrl = asset.imageUrl.trim();

    return asset;
  }

  Future<void> _pickImage() async {
    if (_isBusy) {
      return;
    }

    try {
      final image = await _assetImageService.pickFromGallery();

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _selectedImage = image;
      });
    } on AssetImageException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        title: 'Foto tidak dapat dipilih',
        type: LabFlowNotificationType.warning,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Terjadi kesalahan saat memilih foto aset.',
        title: 'Pemilihan foto gagal',
        type: LabFlowNotificationType.error,
      );
    }
  }

  void _removeImage() {
    if (_isBusy) {
      return;
    }

    setState(() {
      _selectedImage = null;
      _imageUrl = '';
    });
  }

  Future<void> _save(LaboratoryAsset asset) async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isBusy) {
      return;
    }

    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    setState(() {
      _isSaving = true;
    });

    try {
      var imageUrl = _imageUrl.trim();

      if (_selectedImage != null) {
        imageUrl = await _assetImageService.uploadAssetImage(
          image: _selectedImage!,
          laboratoryId: asset.labId,
        );
      }

      await _assetService.updateAsset(
        assetId: asset.id,
        code: _codeController.text.trim().toUpperCase(),
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        stock: stock,
        status: _status,
        condition: _condition,
        imageUrl: imageUrl,
      );

      if (!mounted) {
        return;
      }

      context.pop('updated');
    } on AssetImageException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        title: 'Upload foto gagal',
        type: LabFlowNotificationType.warning,
      );
    } on AssetException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        title: 'Aset tidak dapat diperbarui',
        type: LabFlowNotificationType.warning,
      );
    } catch (error, stackTrace) {
      debugPrint('Update asset error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Terjadi kesalahan saat memperbarui aset. '
        'Periksa koneksi Anda lalu coba lagi.',
        title: 'Pembaruan gagal',
        type: LabFlowNotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteAsset(LaboratoryAsset asset) async {
    if (_isBusy) {
      return;
    }

    if (asset.isBorrowed) {
      _showMessage(
        'Aset yang sedang dipinjam tidak dapat dihapus.',
        title: 'Aset tidak dapat dihapus',
        type: LabFlowNotificationType.warning,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus aset?'),
          content: Text(
            'Aset "${asset.name}" akan dihapus permanen dari inventaris. '
            'Aset yang sudah memiliki riwayat peminjaman akan otomatis ditolak.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBD3232),
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus Permanen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _assetService.deleteAsset(asset.id);

      if (!mounted) {
        return;
      }

      context.pop('deleted');
    } on AssetException catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.message,
        title: 'Aset tidak dapat dihapus',
        type: LabFlowNotificationType.warning,
      );
    } catch (error, stackTrace) {
      debugPrint('Delete asset error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Terjadi kesalahan saat menghapus aset. '
        'Periksa koneksi dan hak akses lalu coba lagi.',
        title: 'Penghapusan gagal',
        type: LabFlowNotificationType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showMessage(
    String message, {
    required String title,
    required LabFlowNotificationType type,
  }) {
    showLabFlowNotification(
      context: context,
      title: title,
      message: message,
      type: type,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field ini wajib diisi.';
    }

    return null;
  }

  String? _stockValidator(String? value) {
    final stock = int.tryParse(value?.trim() ?? '');

    if (stock == null) {
      return 'Stock harus berupa angka.';
    }

    if (stock < 1) {
      return 'Stock minimal 1.';
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
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Edit Aset',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<LaboratoryAsset>(
        future: _assetFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LabFlowLoadingState(
              title: 'Memuat aset',
              message: 'Mengambil data aset yang dipilih.',
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;

            if (error is AssetException) {
              return _buildUnavailableState(error.message);
            }

            return const LabFlowConnectionErrorState(
              title: 'Aset tidak dapat dimuat',
              message:
                  'Data aset tidak dapat diambil saat ini. '
                  'Periksa koneksi Anda lalu coba lagi.',
            );
          }

          final asset = snapshot.data;

          if (asset == null) {
            return _buildUnavailableState('Data aset tidak ditemukan.');
          }

          return _buildForm(asset);
        },
      ),
    );
  }

  Widget _buildForm(LaboratoryAsset asset) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIdentityCard(asset),
              const SizedBox(height: 18),
              _buildAssetImageField(),
              const SizedBox(height: 18),
              TextFormField(
                controller: _nameController,
                validator: _requiredValidator,
                enabled: !_isBusy,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Nama Aset',
                  'Masukkan nama aset',
                  Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                validator: _requiredValidator,
                enabled: !_isBusy,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: _inputDecoration(
                  'Kode Aset',
                  'Masukkan kode aset',
                  Icons.qr_code_rounded,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                validator: _requiredValidator,
                enabled: !_isBusy,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Kategori',
                  'Masukkan kategori aset',
                  Icons.category_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                validator: _stockValidator,
                enabled: !_isBusy,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Stock',
                  '1',
                  Icons.inventory_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                validator: _requiredValidator,
                enabled: !_isBusy,
                textInputAction: TextInputAction.next,
                decoration: _inputDecoration(
                  'Lokasi Aset',
                  'Masukkan lokasi aset',
                  Icons.location_on_outlined,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isBusy,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: _inputDecoration(
                  'Deskripsi',
                  'Tambahkan deskripsi aset...',
                  Icons.notes_rounded,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatusSection(),
              const SizedBox(height: 24),
              _buildConditionSection(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _isBusy ? null : () => _save(asset),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF777777),
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : () => _deleteAsset(asset),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFBD3232),
                    side: const BorderSide(color: Color(0xFFE1A5A5)),
                    shape: const StadiumBorder(),
                  ),
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline_rounded),
                  label: Text(
                    _isDeleting ? 'Menghapus...' : 'Hapus Aset',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Penghapusan permanen hanya dilakukan jika aset belum '
                'memiliki riwayat peminjaman.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF7A8190),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetImageField() {
    final hasSelectedImage = _selectedImage != null;
    final hasRemoteImage = _imageUrl.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.image_outlined, color: Color(0xFF5F6672)),
              SizedBox(width: 10),
              Text(
                'Foto Aset',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: hasSelectedImage
                  ? Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                    )
                  : hasRemoteImage
                  ? Image.network(
                      _imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isBusy ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    hasSelectedImage || hasRemoteImage
                        ? 'Ganti Foto'
                        : 'Pilih Foto',
                  ),
                ),
              ),
              if (hasSelectedImage || hasRemoteImage) ...[
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Hapus foto dari aset',
                  onPressed: _isBusy ? null : _removeImage,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'JPG, JPEG, PNG, atau WEBP. Maksimal 5 MB.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF1F4EC),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 38,
            color: Color(0xFF7A8190),
          ),
          SizedBox(height: 8),
          Text(
            'Belum ada foto aset',
            style: TextStyle(fontSize: 13, color: Color(0xFF7A8190)),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityCard(LaboratoryAsset asset) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFB9F33D),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Identitas aset',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
                ),
                const SizedBox(height: 4),
                Text(
                  asset.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'QR: ${asset.qrValue}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB8BCB3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    if (_status == 'borrowed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEFF),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF3559A6)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Status Borrowed dikelola oleh workflow peminjaman dan '
                'tidak dapat diubah manual dari halaman Edit Aset.',
                style: TextStyle(
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3559A6),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _status,
      decoration: _inputDecoration(
        'Status Aset',
        'Pilih status aset',
        Icons.toggle_on_outlined,
      ),
      items: const [
        DropdownMenuItem(value: 'available', child: Text('Available')),
        DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
      ],
      onChanged: _isBusy
          ? null
          : (value) {
              if (value == null) {
                return;
              }

              setState(() {
                _status = value;
              });
            },
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kondisi Aset',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'good',
                label: Text('Baik'),
                icon: Icon(Icons.check_circle_outline_rounded),
              ),
              ButtonSegment(
                value: 'minor_damage',
                label: Text('Ringan'),
                icon: Icon(Icons.build_outlined),
              ),
              ButtonSegment(
                value: 'damaged',
                label: Text('Rusak'),
                icon: Icon(Icons.report_problem_outlined),
              ),
            ],
            selected: {_condition},
            onSelectionChanged: _isBusy
                ? null
                : (selection) {
                    setState(() {
                      _condition = selection.first;
                    });
                  },
          ),
        ),
      ],
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

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8DDD0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF111111), width: 1.4),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8DDD0)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFBD3232)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFBD3232), width: 1.4),
      ),
    );
  }
}
