class OnboardingItem {
  const OnboardingItem({
    required this.stepLabel,
    required this.title,
    required this.description,
    required this.assetPath,
  });

  final String stepLabel;
  final String title;
  final String description;
  final String assetPath;
}

const onboardingItems = <OnboardingItem>[
  OnboardingItem(
    stepLabel: '01 / 05 — KENALI LABFLOW',
    title: 'Selamat Datang di\nLabFlow',
    description:
        'Kelola aktivitas laboratorium dengan lebih mudah dalam satu aplikasi.',
    assetPath: 'assets/images/onboarding/onboarding_welcome.png',
  ),
  OnboardingItem(
    stepLabel: '02 / 05 — TEMUKAN PERALATAN',
    title: 'Cari & Scan\nPeralatan',
    description: 'Temukan peralatan laboratorium atau gunakan QR Scanner untuk membuka detail aset dengan cepat.',
    assetPath: 'assets/images/onboarding/onboarding_scan.png',
  ),
  OnboardingItem(
    stepLabel: '03 / 05 — MULAI PRAKTIKUM',
    title: 'Ajukan Peminjaman',
    description: 'Ajukan peminjaman peralatan dan pantau statusnya langsung dari aplikasi.',
    assetPath: 'assets/images/onboarding/onboarding_borrow.png',
  ),
  OnboardingItem(
    stepLabel: '04 / 05 — JAGA BERSAMA',
    title: 'Laporkan Kendala',
    description: 'Laporkan kerusakan alat atau masalah laboratorium agar dapat segera ditangani.',
    assetPath: 'assets/images/onboarding/onboarding_report.png',
  ),
  OnboardingItem(
    stepLabel: '05 / 05 — TETAP TERHUBUNG',
    title: 'Pantau Aktivitas',
    description: 'Lihat status peminjaman, laporan, riwayat, dan notifikasi dalam satu tempat.',
    assetPath: 'assets/images/onboarding/onboarding_activity.png',
  ),
];
