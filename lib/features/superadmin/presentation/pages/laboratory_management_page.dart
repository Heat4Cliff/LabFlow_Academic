import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../laboratory/data/laboratory_service.dart';
import '../../../laboratory/domain/laboratory.dart';

class LaboratoryManagementPage extends StatefulWidget {
  const LaboratoryManagementPage({super.key});

  @override
  State<LaboratoryManagementPage> createState() =>
      _LaboratoryManagementPageState();
}

class _LaboratoryManagementPageState extends State<LaboratoryManagementPage> {
  final LaboratoryService _laboratoryService = LaboratoryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F9EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F9EF),
        elevation: 0,
        title: const Text(
          'Manajemen Laboratorium',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<Laboratory>>(
        stream: _laboratoryService.watchLaboratories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Gagal memuat laboratorium.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final laboratories = snapshot.data ?? [];

          if (laboratories.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science_outlined, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'Belum ada laboratorium',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tambahkan laboratorium pertama melalui tombol di bawah.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            itemCount: laboratories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final laboratory = laboratories[index];

              return _buildLaboratoryCard(laboratory);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/superadmin/labs/create');

          if (!context.mounted) return;

          if (created == true) {
            _showSuccessMessage('Laboratorium berhasil dibuat.');
          }
        },
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_business_rounded),
        label: const Text(
          'Tambah Lab',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// Card laboratorium.
  ///
  /// Setelah halaman Edit ditutup, kita membaca result:
  ///
  /// `updated` = data berhasil diperbarui.
  /// `deleted` = laboratorium berhasil dihapus.
  Widget _buildLaboratoryCard(Laboratory laboratory) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () async {
        final result = await context.push<String>(
          '/superadmin/labs/${laboratory.id}/edit',
        );

        if (!context.mounted) return;

        if (result == 'updated') {
          _showSuccessMessage('Laboratorium berhasil diperbarui.');
        } else if (result == 'deleted') {
          _showSuccessMessage('Laboratorium berhasil dihapus.');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E6DC)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFB9F33D),
              foregroundColor: Color(0xFF111111),
              child: Icon(Icons.science_outlined),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laboratory.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111111),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    laboratory.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    laboratory.location,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: laboratory.isActive
                          ? const Color(0xFFE5F6EC)
                          : const Color(0xFFFFE8E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      laboratory.isActive ? 'Aktif' : 'Tidak Aktif',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(Icons.chevron_right_rounded, color: Color(0xFF111111)),
          ],
        ),
      ),
    );
  }

  /// Menampilkan feedback keberhasilan dari operasi
  /// Create, Update, maupun Delete.
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
