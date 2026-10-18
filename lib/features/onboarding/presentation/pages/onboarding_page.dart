import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/storage/app_preferences.dart';
import '../../domain/onboarding_item.dart';
import '../widgets/onboarding_indicator.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();

  int _currentIndex = 0;

  /// Mengecek apakah pengguna sedang berada
  /// pada halaman onboarding terakhir.
  bool get _isLastPage => _currentIndex == onboardingItems.length - 1;

  /// Berpindah ke halaman onboarding berikutnya.
  ///
  /// Jika sudah berada di halaman terakhir,
  /// onboarding akan diselesaikan dan pengguna
  /// diarahkan menuju halaman login.
  Future<void> _nextPage() async {
    if (_isLastPage) {
      await _finishOnboarding();
      return;
    }

    await _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Kembali ke halaman onboarding sebelumnya.
  Future<void> _previousPage() async {
    if (_currentIndex == 0) return;

    await _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Menyelesaikan onboarding.
  ///
  /// Status disimpan secara lokal sehingga onboarding
  /// tidak perlu ditampilkan lagi pada pembukaan berikutnya.
  Future<void> _finishOnboarding() async {
    await AppPreferences.markOnboardingAsCompleted();

    if (!mounted) return;

    context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            children: [
              _buildHeader(),

              const SizedBox(height: 18),

              /// Area utama onboarding.
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingItems.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(onboardingItems[index]);
                  },
                ),
              ),

              const SizedBox(height: 12),

              /// Indicator halaman onboarding.
              OnboardingIndicator(
                currentIndex: _currentIndex,
                itemCount: onboardingItems.length,
              ),

              const SizedBox(height: 18),

              /// Tombol utama.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _nextPage,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _isLastPage
                            ? 'Mulai Menggunakan LabFlow'
                            : 'Selanjutnya',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              /// Tombol kembali.
              ///
              /// Tinggi tetap dipertahankan agar posisi tombol utama
              /// tidak berubah ketika berpindah halaman.
              SizedBox(
                height: 42,
                child: _currentIndex == 0
                    ? const SizedBox.shrink()
                    : TextButton(
                        onPressed: _previousPage,
                        child: const Text(
                          'Kembali',
                          style: TextStyle(
                            color: Color(0xFF111111),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header LabFlow dan tombol Lewati.
  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'LabFlow.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _finishOnboarding,
          child: const Text(
            'Lewati',
            style: TextStyle(
              color: Color(0xFF111111),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Membangun konten masing-masing halaman onboarding.
  ///
  /// Layout tetap dapat di-scroll apabila digunakan pada layar
  /// yang lebih pendek atau ukuran teks sistem diperbesar.
  Widget _buildPage(OnboardingItem item) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Ilustrasi hasil export dari Figma.
                ///
                /// Asset memiliki rasio 350 × 300 sehingga rasio
                /// dipertahankan agar gambar tidak terpotong.
                AspectRatio(
                  aspectRatio: 350 / 300,
                  child: _buildIllustration(item.assetPath),
                ),

                const SizedBox(height: 18),

                /// Nomor dan nama tahap onboarding.
                Text(
                  item.stepLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 12),

                /// Judul halaman.
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1.08,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),

                const SizedBox(height: 12),

                /// Deskripsi halaman.
                Text(
                  item.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Color(0xFF6B7280),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Menampilkan ilustrasi SVG onboarding.
  ///
  /// BoxFit.contain mempertahankan seluruh isi ilustrasi
  /// tanpa melakukan cropping.
  Widget _buildIllustration(String assetPath) {
    return Image.asset(
      assetPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.contain,
    );
  }
}
