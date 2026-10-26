import 'package:flutter/material.dart';

import '../../domain/student_models.dart';

const studentPaper = Color(0xFFF6F9EF);
const studentInk = Color(0xFF111111);
const studentLime = Color(0xFFB9F33D);
const studentSoftLime = Color(0xFFEAFBCB);
const studentBorder = Color(0xFFDDE2D5);
const studentMuted = Color(0xFF737A70);

class StudentPageTitle extends StatelessWidget {
  const StudentPageTitle({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 26,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: studentInk,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: studentMuted,
            ),
          ),
        ],
      ],
    );
  }
}

class StudentLoading extends StatelessWidget {
  const StudentLoading({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: studentInk),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: studentMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentErrorState extends StatelessWidget {
  const StudentErrorState({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42, color: studentMuted),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.4, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: studentInk,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentAssetCard extends StatelessWidget {
  const StudentAssetCard({
    required this.asset,
    required this.labName,
    required this.onTap,
    super.key,
  });

  final StudentAsset asset;
  final String labName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = asset.imageUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: studentBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.45,
                child: Container(
                  color: studentSoftLime,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const _AssetPlaceholder(),
                        )
                      : const _AssetPlaceholder(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 12, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      labName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: studentMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: asset.isAvailable
                                ? studentSoftLime
                                : const Color(0xFFF0F1ED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            asset.isAvailable ? 'Tersedia' : 'Tidak tersedia',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Stok ${asset.stock}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: studentMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetPlaceholder extends StatelessWidget {
  const _AssetPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.memory_rounded, size: 42, color: studentInk),
    );
  }
}

String studentStatusLabel(String value) {
  switch (value) {
    case 'pending':
      return 'Menunggu';
    case 'approved':
      return 'Disetujui';
    case 'waiting_pickup':
      return 'Menunggu Diambil';
    case 'active':
      return 'Aktif';
    case 'returned':
      return 'Dikembalikan';
    case 'rejected':
      return 'Ditolak';
    case 'cancelled':
      return 'Dibatalkan';
    case 'open':
      return 'Menunggu';
    case 'acknowledged':
      return 'Diterima';
    case 'in_progress':
      return 'Diproses';
    case 'resolved':
      return 'Selesai';
    case 'closed':
      return 'Ditutup';
    default:
      return value;
  }
}

String studentCategoryLabel(String value) {
  switch (value) {
    case 'asset_damage':
      return 'Kerusakan Aset';
    case 'asset_lost':
      return 'Aset Hilang';
    case 'network':
      return 'Jaringan';
    case 'computer':
      return 'Komputer';
    case 'software':
      return 'Software';
    case 'facility':
      return 'Fasilitas';
    case 'electricity':
      return 'Kelistrikan';
    case 'other':
      return 'Lainnya';
    default:
      return value;
  }
}

String studentFormatDate(DateTime value) {
  if (value.millisecondsSinceEpoch == 0) return '-';

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  return '${value.day} ${months[value.month - 1]} ${value.year}';
}
