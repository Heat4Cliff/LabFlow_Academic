import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../../laboratory/data/laboratory_service.dart';
import '../../data/activity_log_service.dart';

class CreateLaboratoryPage extends StatefulWidget {
  const CreateLaboratoryPage({
    super.key,
  });

  @override
  State<CreateLaboratoryPage> createState() =>
      _CreateLaboratoryPageState();
}

class _CreateLaboratoryPageState
    extends State<CreateLaboratoryPage> {
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _codeController =
      TextEditingController();

  final TextEditingController _descriptionController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final LaboratoryService _laboratoryService =
      LaboratoryService();

  final ActivityLogService _activityLogService =
      ActivityLogService();

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

  /// Membuat laboratorium baru.
  ///
  /// Success notification ditampilkan oleh
  /// LaboratoryManagementPage setelah menerima result true.
  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final isValid =
        _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final name =
          _nameController.text.trim();

      final code =
          _codeController.text
              .trim()
              .toUpperCase();

      final description =
          _descriptionController.text.trim();

      final location =
          _locationController.text.trim();

      /// =====================================================
      /// CREATE LABORATORY
      /// =====================================================

      await _laboratoryService.createLaboratory(
        name: name,
        code: code,
        description: description,
        location: location,
        status: _status,
      );

      /// =====================================================
      /// ACTIVITY LOG
      /// =====================================================

      await _activityLogService.createActivity(
        type: 'laboratory',
        title: 'Laboratorium dibuat',
        description:
            '$code — $name berhasil dibuat dengan status '
            '${_statusLabel(_status)}.',
        reference: code,
      );

      if (!mounted) {
        return;
      }

      /// Halaman sebelumnya akan menampilkan
      /// floating success notification.
      context.pop(true);
    } on LaboratoryException catch (error) {
      if (!mounted) {
        return;
      }

      /// Duplicate code dan business rule lain
      /// lebih tepat ditampilkan sebagai warning.
      _showMessage(
        error.message,
        type: LabFlowNotificationType.warning,
        title: 'Laboratorium tidak dapat dibuat',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Terjadi kesalahan saat membuat laboratorium.',
        type: LabFlowNotificationType.error,
        title: 'Pembuatan gagal',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shared floating notification LabFlow.
  void _showMessage(
    String message, {
    LabFlowNotificationType type =
        LabFlowNotificationType.error,
    String? title,
  }) {
    showLabFlowNotification(
      context: context,
      message: message,
      type: type,
      title: title,
    );
  }

  String _statusLabel(
    String status,
  ) {
    switch (status) {
      case 'active':
        return 'Aktif';

      case 'inactive':
        return 'Tidak Aktif';

      default:
        return status;
    }
  }

  String? _requiredValidator(
    String? value,
  ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Field ini wajib diisi.';
    }

    return null;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(
        0xFFF6F9EF,
      ),

      appBar: AppBar(
        backgroundColor:
            const Color(
          0xFFF6F9EF,
        ),
        elevation: 0,
        title: const Text(
          'Tambah Laboratorium',
          style: TextStyle(
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Laboratorium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        Color(
                      0xFF111111,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Data akan disimpan langsung ke Cloud Firestore.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color:
                        Color(
                      0xFF6B7280,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                /// =================================================
                /// NAMA
                /// =================================================

                TextFormField(
                  controller:
                      _nameController,
                  validator:
                      _requiredValidator,
                  enabled:
                      !_isLoading,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      _inputDecoration(
                    'Nama Laboratorium',
                    'Laboratorium Komputer 1',
                    Icons
                        .science_outlined,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                /// =================================================
                /// KODE
                /// =================================================

                TextFormField(
                  controller:
                      _codeController,
                  validator:
                      _requiredValidator,
                  enabled:
                      !_isLoading,
                  textCapitalization:
                      TextCapitalization
                          .characters,
                  textInputAction:
                      TextInputAction.next,
                  autocorrect: false,
                  decoration:
                      _inputDecoration(
                    'Kode Laboratorium',
                    'LAB-KOM-01',
                    Icons
                        .qr_code_rounded,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                /// =================================================
                /// LOKASI
                /// =================================================

                TextFormField(
                  controller:
                      _locationController,
                  validator:
                      _requiredValidator,
                  enabled:
                      !_isLoading,
                  textInputAction:
                      TextInputAction.next,
                  decoration:
                      _inputDecoration(
                    'Lokasi',
                    'Gedung FMIKOM',
                    Icons
                        .location_on_outlined,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                /// =================================================
                /// DESKRIPSI
                /// =================================================

                TextFormField(
                  controller:
                      _descriptionController,
                  maxLines: 4,
                  enabled:
                      !_isLoading,
                  textInputAction:
                      TextInputAction.newline,
                  decoration:
                      _inputDecoration(
                    'Deskripsi',
                    'Laboratorium untuk kegiatan praktikum...',
                    Icons
                        .notes_rounded,
                  ),
                ),

                const SizedBox(
                  height: 24,
                ),

                /// =================================================
                /// STATUS
                /// =================================================

                const Text(
                  'Status Laboratorium',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                      0xFF6B7280,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'active',
                      label:
                          Text('Aktif'),
                      icon: Icon(
                        Icons
                            .check_circle_outline,
                      ),
                    ),

                    ButtonSegment<String>(
                      value:
                          'inactive',
                      label:
                          Text(
                        'Tidak Aktif',
                      ),
                      icon: Icon(
                        Icons
                            .block_outlined,
                      ),
                    ),
                  ],

                  selected: {
                    _status,
                  },

                  onSelectionChanged:
                      _isLoading
                          ? null
                          : (selection) {
                              setState(() {
                                _status =
                                    selection
                                        .first;
                              });
                            },
                ),

                const SizedBox(
                  height: 28,
                ),

                /// =================================================
                /// SIMPAN
                /// =================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 54,
                  child:
                      FilledButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _save,

                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF111111,
                      ),
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          const Color(
                        0xFF777777,
                      ),
                      shape:
                          const StadiumBorder(),
                    ),

                    child:
                        _isLoading
                            ? const SizedBox(
                                width:
                                    22,
                                height:
                                    22,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color:
                                      Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                children: [
                                  Icon(
                                    Icons
                                        .add_business_outlined,
                                    size:
                                        20,
                                  ),
                                  SizedBox(
                                    width:
                                        10,
                                  ),
                                  Text(
                                    'Simpan Laboratorium',
                                    style:
                                        TextStyle(
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                                ],
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

  InputDecoration _inputDecoration(
    String label,
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      labelText:
          label,

      hintText:
          hint,

      prefixIcon:
          Icon(
        icon,
      ),

      filled:
          true,

      fillColor:
          Colors.white,

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFD8DDD0,
          ),
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFF111111,
          ),
          width:
              1.4,
        ),
      ),

      disabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFD8DDD0,
          ),
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFBD3232,
          ),
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(
            0xFFBD3232,
          ),
          width:
              1.4,
        ),
      ),
    );
  }
}