abstract final class AuthValidator {
  /// Memvalidasi alamat email.
  static String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email wajib diisi.';
    }

    // Pola dasar alamat email:
    // nama@domain.ext
    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Masukkan alamat email yang valid.';
    }

    return null;
  }

  /// Memvalidasi format password LabFlow.
  ///
  /// Password harus:
  /// - minimal 8 karakter
  /// - memiliki minimal satu angka
  /// - memiliki minimal satu simbol
  static String? validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'Password wajib diisi.';
    }

    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password harus mengandung angka.';
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=]').hasMatch(password)) {
      return 'Password harus mengandung simbol.';
    }

    return null;
  }
}
