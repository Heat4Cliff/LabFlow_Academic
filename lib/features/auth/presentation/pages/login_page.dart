import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/validators/auth_validator.dart';
import '../../data/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Melakukan proses Login LabFlow.
  ///
  /// Tahapan Login:
  /// 1. Validasi format email dan password.
  /// 2. Firebase Authentication memverifikasi kredensial.
  /// 3. Profil pengguna dibaca dari Cloud Firestore.
  /// 4. Status akun diperiksa.
  /// 5. User diarahkan berdasarkan role.
  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final profile = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      switch (profile.role) {
        case 'superadmin':
          context.go('/superadmin');
          break;

        case 'lab_admin':
          await _authService.signOut();

          if (!mounted) return;

          _showMessage('Dashboard Lab Admin belum tersedia.');
          break;

        case 'student':
          await _authService.signOut();

          if (!mounted) return;

          _showMessage('Dashboard Student belum tersedia.');
          break;

        default:
          await _authService.signOut();

          if (!mounted) return;

          _showMessage('Role akun tidak dikenali.');
      }
    } on AuthServiceException catch (error) {
      if (!mounted) return;

      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;

      _showMessage('Terjadi kesalahan saat proses login.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Membuka WhatsApp Admin Lab bagi mahasiswa
  /// yang belum memiliki akun LabFlow.
  Future<void> _contactAdmin() async {
    final adminNumber = AppConfig.adminWhatsAppNumber.trim();

    if (adminNumber.isEmpty) {
      if (!mounted) return;

      _showMessage('Nomor WhatsApp Admin Lab belum dikonfigurasi.');

      return;
    }

    const message =
        'Halo Admin Lab, saya ingin meminta bantuan terkait akun LabFlow. '
        'Saat ini saya belum memiliki akun untuk mengakses aplikasi.';

    final uri = Uri.https('wa.me', '/$adminNumber', {'text': message});

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      _showMessage('WhatsApp tidak dapat dibuka pada perangkat ini.');
    }
  }

  /// Menampilkan pesan informasi atau error.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),

                    const SizedBox(height: 20),

                    _buildIllustration(),

                    const SizedBox(height: 20),

                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 36,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Masuk untuk mengakses layanan\nlaboratorium.',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildEmailField(),

                          const SizedBox(height: 16),

                          _buildPasswordField(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    _buildLoginButton(),

                    const SizedBox(height: 18),

                    _buildContactAdmin(),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'LabFlow Academic Project',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Header Login LabFlow.
  Widget _buildHeader() {
    return const SizedBox(
      height: 31,
      child: Row(
        children: [
          Text(
            'LabFlow.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          Spacer(),
          Icon(Icons.science_outlined, size: 26, color: Color(0xFF111111)),
        ],
      ),
    );
  }

  /// Ilustrasi laboratorium dari desain Figma.
  Widget _buildIllustration() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 350 / 224,
        child: Image.asset(
          'assets/images/auth/login_illustration.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Field Email.
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      autocorrect: false,
      enableSuggestions: false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: AuthValidator.validateEmail,
      decoration: _inputDecoration(
        label: 'Email',
        hint: 'mahasiswa@example.com',
        suffixIcon: const Icon(Icons.email_outlined, color: Color(0xFF111111)),
      ),
    );
  }

  /// Field Password.
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: AuthValidator.validatePassword,
      onFieldSubmitted: (_) {
        _login();
      },
      decoration: _inputDecoration(
        label: 'Password',
        hint: '••••••••',
        suffixIcon: IconButton(
          tooltip: _obscurePassword
              ? 'Tampilkan password'
              : 'Sembunyikan password',
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF111111),
          ),
        ),
      ),
    );
  }

  /// Style reusable untuk Email dan Password.
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required Widget suffixIcon,
  }) {
    const normalBorderColor = Color(0xFFD8DDD0);

    const darkColor = Color(0xFF111111);

    const errorColor = Color(0xFFBD3232);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      labelStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
      hintStyle: const TextStyle(fontSize: 15, color: darkColor),
      errorStyle: const TextStyle(fontSize: 12, color: errorColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: normalBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: errorColor, width: 1.4),
      ),
    );
  }

  /// Tombol Login.
  ///
  /// Ketika request Firebase berjalan, tombol
  /// dinonaktifkan dan menampilkan loading indicator.
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: FilledButton(
        onPressed: _isLoading ? null : _login,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF111111),
          disabledForegroundColor: Colors.white,
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
                  Icon(Icons.arrow_forward_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Masuk',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  /// Bantuan bagi mahasiswa yang belum memiliki akun.
  Widget _buildContactAdmin() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          const Text(
            'Belum memiliki akun?',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          TextButton(
            onPressed: _contactAdmin,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Hubungi Admin Lab',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
