import 'package:flutter/material.dart';

import '../widgets/profile_navigation_widgets.dart';

class ApplicationGuidePage extends StatelessWidget {
  const ApplicationGuidePage({
    required this.role,
    required this.returnPath,
    super.key,
  });

  final String role;
  final String returnPath;

  @override
  Widget build(BuildContext context) {
    final sections = switch (role) {
      'student' => _studentSections,
      'lab_admin' => _labAdminSections,
      _ => _superadminSections,
    };
    return ProfileSubpageScaffold(
      title: 'Panduan Aplikasi',
      returnPath: returnPath,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          const Text(
            'Cara menggunakan LabFlow',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buka bagian yang ingin Anda pelajari.',
            style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0xFFDDE2D5)),
              ),
              child: ExpansionTile(
                leading: Icon(section.icon, color: const Color(0xFF111111)),
                title: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                children: [
                  for (final step in section.steps)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 7,
                            color: Color(0xFF7FAF27),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              step,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _GuideSection {
  const _GuideSection(this.title, this.icon, this.steps);
  final String title;
  final IconData icon;
  final List<String> steps;
}

const _studentSections = <_GuideSection>[
  _GuideSection('Mulai Menggunakan LabFlow', Icons.home_outlined, [
    'Masuk menggunakan akun yang diberikan Admin Lab.',
    'Home merangkum peminjaman dan aktivitas terbaru. Buka Inventaris untuk melihat aset laboratorium.',
  ]),
  _GuideSection('Scan QR', Icons.qr_code_scanner_rounded, [
    'Pilih Scan QR dari Home atau Inventaris, lalu berikan izin kamera.',
    'Arahkan kamera ke QR aset. Jika kamera tidak tersedia, ketik kode aset atau nilai QR secara manual.',
    'Periksa detail aset sebelum mengajukan peminjaman.',
  ]),
  _GuideSection('Peminjaman', Icons.inventory_2_outlined, [
    'Pilih aset tersedia, isi jumlah, tanggal, dan tujuan, lalu ajukan permintaan.',
    'Status pending berarti menunggu keputusan Lab Admin. Setelah disetujui, tunggu penugasan aset dan instruksi pickup.',
    'Setelah pickup diverifikasi, peminjaman menjadi aktif. Serahkan kembali aset kepada Lab Admin untuk proses return dan pemeriksaan.',
  ]),
  _GuideSection('Laporan', Icons.description_outlined, [
    'Buka Laporan untuk membuat laporan masalah aset atau layanan laboratorium.',
    'Pantau status pada detail laporan dan gunakan chat di detail untuk berkomunikasi dengan Lab Admin.',
  ]),
  _GuideSection('Notifikasi', Icons.notifications_outlined, [
    'Buka ikon lonceng untuk melihat pusat notifikasi. Badge menunjukkan notifikasi yang belum dibaca.',
    'Ketuk notifikasi untuk membuka detail terkait.',
  ]),
  _GuideSection('Profil', Icons.person_outline_rounded, [
    'Gunakan Edit Profil untuk mengubah nama lengkap. Email dan hak akses dikelola administrator.',
    'Pilih Keluar jika selesai menggunakan perangkat.',
  ]),
];

const _labAdminSections = <_GuideSection>[
  _GuideSection('Dashboard & Inventaris', Icons.dashboard_outlined, [
    'Dashboard menampilkan ringkasan laboratorium aktif dan pekerjaan yang perlu ditangani.',
    'Buka Inventaris untuk melihat, menambah, atau mengedit aset sesuai membership laboratorium.',
  ]),
  _GuideSection('Peminjaman', Icons.assignment_outlined, [
    'Periksa request yang masuk, lalu setujui atau tolak beserta alasannya.',
    'Untuk request disetujui, lakukan assignment aset, verifikasi pickup, penerimaan return, dan pemeriksaan kondisi akhir.',
  ]),
  _GuideSection('Laporan & Maintenance', Icons.build_outlined, [
    'Buka detail laporan untuk meninjau masalah dan membalas chat Student.',
    'Gunakan Maintenance untuk mencatat dan memantau penanganan aset yang membutuhkan perawatan.',
  ]),
  _GuideSection('Profil', Icons.person_outline_rounded, [
    'Lihat laboratorium yang Anda kelola, ubah nama melalui Edit Profil, atau Keluar dari akun.',
  ]),
];

const _superadminSections = <_GuideSection>[
  _GuideSection('Pengelolaan', Icons.admin_panel_settings_outlined, [
    'Dashboard merangkum data administratif LabFlow.',
    'Kelola akun, laboratorium, dan membership dari menu yang tersedia sesuai kebutuhan.',
  ]),
  _GuideSection('Aktivitas & Profil', Icons.history_rounded, [
    'Gunakan Log Aktivitas untuk meninjau perubahan administratif.',
    'Edit Profil hanya mengubah nama lengkap akun sendiri. Pilih Keluar setelah selesai.',
  ]),
];
