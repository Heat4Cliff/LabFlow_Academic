import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/user_profile.dart';
import '../../data/user_management_service.dart';

class EditUserPage extends StatefulWidget {
  const EditUserPage({required this.userId, super.key});

  final String userId;

  @override
  State<EditUserPage> createState() => _EditUserPageState();
}

class _EditUserPageState extends State<EditUserPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final UserManagementService _service = UserManagementService();

  final TextEditingController _nameController = TextEditingController();

  bool _initialised = false;
  bool _isSaving = false;
  bool _isChangingStatus = false;

  String _role = 'student';
  String _status = 'active';

  late final Future<UserProfile> _userFuture;

  @override
  void initState() {
    super.initState();

    _userFuture = _service.getUser(widget.userId);
  }

  @override
  void dispose() {
    _nameController.dispose();

    super.dispose();
  }

  void _fillForm(UserProfile profile) {
    if (_initialised) return;

    _nameController.text = profile.fullName;

    _role = profile.role;
    _status = profile.status;

    _initialised = true;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || _isSaving || _isChangingStatus) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.updateUser(
        userId: widget.userId,
        fullName: _nameController.text,
        role: _role,
        status: _status,
      );

      if (!mounted) return;

      context.pop('updated');
    } on UserManagementException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Gagal memperbarui pengguna.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _toggleStatus() async {
    if (_isSaving || _isChangingStatus) {
      return;
    }

    final suspending = _status == 'active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(suspending ? 'Nonaktifkan Akun?' : 'Aktifkan Akun?'),
          content: Text(
            suspending
                ? 'Pengguna tidak akan dapat masuk ke LabFlow sampai akun diaktifkan kembali.'
                : 'Pengguna akan kembali dapat masuk ke LabFlow.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(suspending ? 'Nonaktifkan' : 'Aktifkan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isChangingStatus = true;
    });

    try {
      if (suspending) {
        await _service.suspendUser(widget.userId);
      } else {
        await _service.activateUser(widget.userId);
      }

      if (!mounted) return;

      context.pop(suspending ? 'suspended' : 'activated');
    } on UserManagementException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Gagal mengubah status pengguna.');
    } finally {
      if (mounted) {
        setState(() {
          _isChangingStatus = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Nama lengkap wajib diisi.';
    }

    if (name.length < 3) {
      return 'Nama lengkap terlalu pendek.';
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
          'Edit Pengguna',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: FutureBuilder<UserProfile>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || snapshot.data == null) {
            return const Center(
              child: Text('Data pengguna tidak dapat dimuat.'),
            );
          }

          final profile = snapshot.data!;

          _fillForm(profile);

          return _buildForm(profile);
        },
      ),
    );
  }

  Widget _buildForm(UserProfile profile) {
    final isSuperadmin = profile.role == 'superadmin';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perbarui Pengguna',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                enabled: !isSuperadmin,
                validator: _validateName,
                decoration: _inputDecoration(
                  'Nama Lengkap',
                  Icons.person_outline,
                ),
              ),

              const SizedBox(height: 16),

              /// Email hanya dibaca.
              TextFormField(
                initialValue: profile.email,
                readOnly: true,
                enabled: false,
                decoration: _inputDecoration('Email', Icons.email_outlined),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: isSuperadmin ? 'superadmin' : _role,
                decoration: _inputDecoration(
                  'Role',
                  Icons.admin_panel_settings_outlined,
                ),
                items: isSuperadmin
                    ? const [
                        DropdownMenuItem(
                          value: 'superadmin',
                          child: Text('Superadmin'),
                        ),
                      ]
                    : const [
                        DropdownMenuItem(
                          value: 'student',
                          child: Text('Student'),
                        ),
                        DropdownMenuItem(
                          value: 'lab_admin',
                          child: Text('Lab Admin'),
                        ),
                      ],
                onChanged: isSuperadmin
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _role = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD8DDD0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Akun',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _status == 'active' ? 'Aktif' : 'Suspended',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (!isSuperadmin) ...[
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isSaving || _isChangingStatus ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF111111),
                      foregroundColor: Colors.white,
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
                    onPressed: _isSaving || _isChangingStatus
                        ? null
                        : _toggleStatus,
                    icon: Icon(
                      _status == 'active'
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      _isChangingStatus
                          ? 'Memproses...'
                          : _status == 'active'
                          ? 'Nonaktifkan Akun'
                          : 'Aktifkan Akun',
                    ),
                  ),
                ),
              ],

              if (isSuperadmin) ...[
                const SizedBox(height: 24),
                const Text(
                  'Akun Superadmin utama dilindungi dan tidak dapat diubah melalui User Management.',
                  style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                ),
              ],
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
    );
  }
}
