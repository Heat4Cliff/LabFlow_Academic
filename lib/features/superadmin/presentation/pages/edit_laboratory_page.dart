import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';

class EditLaboratoryPage extends StatefulWidget {
  const EditLaboratoryPage({required this.laboratoryId, super.key});

  final String laboratoryId;

  @override
  State<EditLaboratoryPage> createState() => _EditLaboratoryPageState();
}

class _EditLaboratoryPageState extends State<EditLaboratoryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final LaboratoryService _service = LaboratoryService();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _codeController = TextEditingController();

  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  bool _initialised = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  String _status = 'active';

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

  /// Mengisi form hanya satu kali setelah data
  /// laboratorium berhasil diambil dari Firestore.
  void _fillForm(Laboratory laboratory) {
    if (_initialised) return;

    _nameController.text = laboratory.name;
    _codeController.text = laboratory.code;
    _locationController.text = laboratory.location;
    _descriptionController.text = laboratory.description;

    _status = laboratory.status;

    _initialised = true;
  }

  /// Memperbarui data laboratorium.
  ///
  /// Jika berhasil, result `updated` dikirim
  /// kembali ke halaman Manajemen Laboratorium.
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
      await _service.updateLaboratory(
        laboratoryId: widget.laboratoryId,
        name: _nameController.text,
        code: _codeController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        status: _status,
      );

      if (!mounted) return;

      /// Memberi tahu halaman sebelumnya
      /// bahwa update berhasil.
      context.pop('updated');
    } on LaboratoryException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Gagal memperbarui laboratorium.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Menghapus laboratorium setelah mendapat
  /// konfirmasi dari Superadmin.
  ///
  /// Service tetap melakukan pemeriksaan relasi
  /// membership sebelum hard-delete dilakukan.
  Future<void> _delete() async {
    if (_isDeleting || _isSaving) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Laboratorium?'),
          content: const Text(
            'Data akan dihapus permanen jika laboratorium belum memiliki '
            'riwayat membership.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFBD3232),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _service.deleteLaboratory(widget.laboratoryId);

      if (!mounted) return;

      /// Memberi tahu halaman sebelumnya
      /// bahwa delete berhasil.
      context.pop('deleted');
    } on LaboratoryException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Gagal menghapus laboratorium.');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Laboratorium tidak dapat dimuat.'),
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                validator: _required,
                decoration: _inputDecoration(
                  'Nama Laboratorium',
                  Icons.science_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _codeController,
                validator: _required,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration(
                  'Kode Laboratorium',
                  Icons.qr_code_rounded,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _locationController,
                validator: _required,
                decoration: _inputDecoration(
                  'Lokasi',
                  Icons.location_on_outlined,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Deskripsi', Icons.notes_rounded),
              ),

              const SizedBox(height: 24),

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
                  ButtonSegment(
                    value: 'active',
                    label: Text('Aktif'),
                    icon: Icon(Icons.check_circle_outline),
                  ),
                  ButtonSegment(
                    value: 'inactive',
                    label: Text('Tidak Aktif'),
                    icon: Icon(Icons.block_outlined),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (selection) {
                  setState(() {
                    _status = selection.first;
                  });
                },
              ),

              const SizedBox(height: 28),

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
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),

              const SizedBox(height: 12),

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
