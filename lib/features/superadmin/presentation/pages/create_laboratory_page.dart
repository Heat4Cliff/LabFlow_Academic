import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../laboratory/data/laboratory_service.dart';

class CreateLaboratoryPage extends StatefulWidget {
  const CreateLaboratoryPage({super.key});

  @override
  State<CreateLaboratoryPage> createState() => _CreateLaboratoryPageState();
}

class _CreateLaboratoryPageState extends State<CreateLaboratoryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _codeController = TextEditingController();

  final TextEditingController _descriptionController = TextEditingController();

  final TextEditingController _locationController = TextEditingController();

  final LaboratoryService _laboratoryService = LaboratoryService();

  String _status = 'active';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _laboratoryService.createLaboratory(
        name: _nameController.text,
        code: _codeController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        status: _status,
      );

      if (!mounted) return;

      context.pop(true);
    } on LaboratoryException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Terjadi kesalahan saat membuat laboratorium.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _requiredValidator(String? value) {
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
          'Tambah Laboratorium',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Laboratorium',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Data akan disimpan langsung ke Cloud Firestore.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),

                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Nama Laboratorium',
                    'Laboratorium Komputer 1',
                    Icons.science_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _codeController,
                  validator: _requiredValidator,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Kode Laboratorium',
                    'LAB-KOM-01',
                    Icons.qr_code_rounded,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _locationController,
                  validator: _requiredValidator,
                  textInputAction: TextInputAction.next,
                  decoration: _inputDecoration(
                    'Lokasi',
                    'Gedung FMIKOM',
                    Icons.location_on_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: _inputDecoration(
                    'Deskripsi',
                    'Laboratorium untuk kegiatan praktikum...',
                    Icons.notes_rounded,
                  ),
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
                  height: 54,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF111111),
                      shape: const StadiumBorder(),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Laboratorium',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
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
    );
  }
}
