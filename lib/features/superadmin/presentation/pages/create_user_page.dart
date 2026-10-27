import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/validators/auth_validator.dart';
import '../../../../shared/presentation/notifications/labflow_notification.dart';
import '../../data/activity_log_service.dart';
import '../../data/user_management_service.dart';
import '../cubit/user_management_action_cubit.dart';

class CreateUserPage extends StatelessWidget {
  const CreateUserPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => UserManagementActionCubit(
      UserManagementService(),
      ActivityLogService(),
    ),
    child: const _CreateUserView(),
  );
}

class _CreateUserView extends StatefulWidget {
  const _CreateUserView();

  @override
  State<_CreateUserView> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<_CreateUserView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _nidnController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _selectedRole = 'student';
  String _selectedStatus = 'active';

  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool get _isLoading => context.read<UserManagementActionCubit>().state;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nimController.dispose();
    _programController.dispose();
    _semesterController.dispose();
    _nipController.dispose();
    _nidnController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  /// Membuat akun baru melalui Firebase Authentication
  /// dan menyimpan profil pengguna ke Cloud Firestore.
  ///
  /// Jika operasi utama berhasil, Activity Log akan
  /// dicatat sebagai jejak audit Superadmin.
  Future<void> _createUser() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    try {
      /// Merapikan data sebelum dikirim ke Firebase.
      final fullName = _nameController.text.trim();

      final email = _emailController.text.trim();

      /// Membuat Firebase Authentication account
      /// sekaligus profile pada collection users.
      await context.read<UserManagementActionCubit>().createUser(
        fullName: fullName,
        email: email,
        password: _passwordController.text,
        role: _selectedRole,
        status: _selectedStatus,
        phoneNumber: _phoneController.text,
        nim: _nimController.text,
        studyProgram: _programController.text,
        semester: int.tryParse(_semesterController.text),
        nip: _nipController.text,
        nidn: _nidnController.text,
      );

      if (!mounted) {
        return;
      }

      /// Memberi tahu halaman Manajemen Pengguna
      /// bahwa proses create berhasil.
      ///
      /// Floating success notification akan ditampilkan
      /// oleh UserManagementPage.
      context.pop(true);
    } on UserManagementException catch (error) {
      if (!mounted) {
        return;
      }

      /// Error yang berasal dari aturan bisnis seperti
      /// email sudah digunakan atau operasi ditolak
      /// ditampilkan sebagai Warning.
      _showMessage(
        error.message,
        type: LabFlowNotificationType.warning,
        title: 'Pengguna tidak dapat dibuat',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      /// Unexpected error menggunakan notification Error.
      _showMessage(
        'Terjadi kesalahan saat membuat pengguna.',
        type: LabFlowNotificationType.error,
        title: 'Pembuatan akun gagal',
      );
    }
  }

  /// Shared floating notification LabFlow.
  ///
  /// Menggantikan SnackBar hitam bawaan Flutter.
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

  /// Validasi nama lengkap.
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

  /// Memastikan konfirmasi password sama
  /// dengan password utama.
  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi.';
    }

    if (value != _passwordController.text) {
      return 'Konfirmasi password tidak sama.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserManagementActionCubit, bool>(
      builder: (context, _) => _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        title: const Text(
          'Tambah Pengguna',
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
                  'Buat Akun LabFlow',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Akun akan dibuat pada Firebase Authentication dan profilnya disimpan di Cloud Firestore.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 24),

                /// =================================================
                /// NAMA LENGKAP
                /// =================================================
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  decoration: _inputDecoration(
                    label: 'Nama Lengkap',
                    hint: 'Contoh: Mohammad Alwan',
                    icon: Icons.person_outline_rounded,
                  ),
                ),

                const SizedBox(height: 16),

                /// =================================================
                /// EMAIL
                /// =================================================
                TextFormField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.none,
                  autocorrect: false,
                  validator: AuthValidator.validateEmail,
                  decoration: _inputDecoration(
                    label: 'Email',
                    hint: 'mahasiswa@example.com',
                    icon: Icons.email_outlined,
                  ),
                ),

                const SizedBox(height: 16),

                /// =================================================
                /// PASSWORD
                /// =================================================
                TextFormField(
                  controller: _passwordController,
                  enabled: !_isLoading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: AuthValidator.validatePassword,
                  decoration: _passwordDecoration(
                    label: 'Password',
                    obscure: _obscurePassword,
                    onToggle: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 16),

                /// =================================================
                /// KONFIRMASI PASSWORD
                /// =================================================
                TextFormField(
                  controller: _confirmPasswordController,
                  enabled: !_isLoading,
                  obscureText: _obscureConfirmation,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  validator: _validateConfirmation,
                  decoration: _passwordDecoration(
                    label: 'Konfirmasi Password',
                    obscure: _obscureConfirmation,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmation = !_obscureConfirmation;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 24),

                /// =================================================
                /// ROLE
                /// =================================================
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: _inputDecoration(
                    label: '',
                    hint: '',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(
                      value: 'lab_admin',
                      child: Text('Lab Admin'),
                    ),
                  ],
                  onChanged: _isLoading
                      ? null
                      : (value) {
                          if (value == null) {
                            return;
                          }

                          setState(() {
                            _selectedRole = value;
                          });
                        },
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration(
                    label: 'Nomor HP',
                    hint: 'Opsional',
                    icon: Icons.phone_outlined,
                  ),
                ),
                if (_selectedRole == 'student') ...[
                  TextFormField(
                    controller: _nimController,
                    maxLength: 30,
                    decoration: _inputDecoration(
                      label: 'NIM',
                      hint: 'Opsional',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  TextFormField(
                    controller: _programController,
                    maxLength: 100,
                    decoration: _inputDecoration(
                      label: 'Program Studi',
                      hint: 'Opsional',
                      icon: Icons.school_outlined,
                    ),
                  ),
                  TextFormField(
                    controller: _semesterController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) return null;
                      final semester = int.tryParse(raw);
                      return semester == null || semester < 1 || semester > 14
                          ? 'Semester harus 1–14.'
                          : null;
                    },
                    decoration: _inputDecoration(
                      label: 'Semester (1–14)',
                      hint: 'Opsional',
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                ],
                if (_selectedRole == 'lab_admin') ...[
                  TextFormField(
                    controller: _nipController,
                    maxLength: 30,
                    decoration: _inputDecoration(
                      label: 'NIP',
                      hint: 'Opsional',
                      icon: Icons.badge_outlined,
                    ),
                  ),
                  TextFormField(
                    controller: _nidnController,
                    maxLength: 30,
                    decoration: _inputDecoration(
                      label: 'NIDN',
                      hint: 'Opsional',
                      icon: Icons.school_outlined,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                /// =================================================
                /// STATUS AKUN
                /// =================================================
                const Text(
                  'Status Akun',
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
                      value: 'suspended',
                      label: Text('Suspended'),
                      icon: Icon(Icons.block_outlined),
                    ),
                  ],
                  selected: {_selectedStatus},
                  onSelectionChanged: _isLoading
                      ? null
                      : (selection) {
                          setState(() {
                            _selectedStatus = selection.first;
                          });
                        },
                ),

                const SizedBox(height: 28),

                /// =================================================
                /// SUBMIT
                /// =================================================
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _createUser,
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
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1_rounded),
                              SizedBox(width: 10),
                              Text(
                                'Buat Akun',
                                style: TextStyle(fontWeight: FontWeight.w700),
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

  /// Style dasar seluruh input pada form.
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label.isEmpty ? null : label,
      hintText: hint.isEmpty ? null : hint,
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

  /// Decoration khusus password.
  ///
  /// Menggunakan style input dasar tetapi menambahkan
  /// tombol show / hide password.
  InputDecoration _passwordDecoration({
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return _inputDecoration(
      label: label,
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
    ).copyWith(
      suffixIcon: IconButton(
        tooltip: obscure ? 'Tampilkan password' : 'Sembunyikan password',
        onPressed: onToggle,
        icon: Icon(
          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
    );
  }
}
