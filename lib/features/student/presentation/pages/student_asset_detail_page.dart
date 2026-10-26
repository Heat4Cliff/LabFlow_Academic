import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
import '../student_navigation.dart';
import '../widgets/student_ui.dart';

class StudentAssetDetailPage extends StatefulWidget {
  const StudentAssetDetailPage({required this.assetId, super.key});

  final String assetId;

  @override
  State<StudentAssetDetailPage> createState() => _StudentAssetDetailPageState();
}

class _StudentAssetDetailPageState extends State<StudentAssetDetailPage> {
  final StudentService _service = StudentService();
  late Future<_AssetDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_AssetDetailData> _load() async {
    final asset = await _service.loadAsset(widget.assetId);
    final laboratories = await _service.loadActiveLaboratories();
    StudentLaboratory? laboratory;
    for (final candidate in laboratories) {
      if (candidate.id == asset.labId) {
        laboratory = candidate;
        break;
      }
    }
    return _AssetDetailData(asset: asset, laboratory: laboratory);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: studentPaper,
      body: SafeArea(
        child: FutureBuilder<_AssetDetailData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const StudentLoading(message: 'Memuat detail aset.');
            }
            if (snapshot.hasError || snapshot.data == null) {
              return StudentErrorState(
                message: 'Detail aset tidak dapat dimuat.',
                onRetry: _refresh,
              );
            }
            return _content(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _content(_AssetDetailData data) {
    final asset = data.asset;
    final imageUrl = asset.imageUrl;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
        children: [
          StudentBackHeader(
            title: 'Detail Aset',
            onBack: () => context.pop(),
            trailing: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, size: 19),
            ),
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.16,
            child: Container(
              decoration: BoxDecoration(
                color: studentSoftLime,
                borderRadius: BorderRadius.circular(24),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _DetailPlaceholder(),
                    )
                  : const _DetailPlaceholder(),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: StudentStatusPill(
              status: asset.isAvailable ? 'available' : asset.status,
              small: true,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            asset.name,
            style: const TextStyle(
              fontSize: 25,
              height: 1.05,
              fontWeight: FontWeight.w900,
              color: studentInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${asset.code} · ${data.laboratory?.name ?? 'Laboratorium'}',
            style: const TextStyle(fontSize: 12, color: studentMuted),
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(child: _meta('Kategori', asset.category)),
              const SizedBox(width: 16),
              Expanded(child: _meta('Kondisi', _condition(asset.condition))),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            asset.isAvailable
                ? 'Siap untuk praktikum.'
                : 'Status aset saat ini.',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: studentInk,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            asset.description.isNotEmpty
                ? asset.description
                : 'Informasi aset laboratorium tersedia pada halaman ini.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: studentMuted,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: studentMuted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Pengambilan setelah persetujuan Lab Admin. Stok ${asset.stock} unit.',
                  style: const TextStyle(fontSize: 10, color: studentMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: asset.isAvailable
                  ? () => context.push(
                      '$studentBorrowRequestFormPath?assetId=${Uri.encodeComponent(asset.id)}',
                    )
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: studentInk,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB8BCB3),
                shape: const StadiumBorder(),
              ),
              child: Text(
                asset.isAvailable ? 'Ajukan Peminjaman' : 'Aset Tidak Tersedia',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: studentMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: studentInk,
          ),
        ),
      ],
    );
  }

  String _condition(String value) {
    switch (value) {
      case 'good':
        return 'Baik';
      case 'minor_damage':
        return 'Kerusakan Ringan';
      case 'damaged':
        return 'Rusak';
      default:
        return value;
    }
  }
}

class _AssetDetailData {
  const _AssetDetailData({required this.asset, required this.laboratory});
  final StudentAsset asset;
  final StudentLaboratory? laboratory;
}

class _DetailPlaceholder extends StatelessWidget {
  const _DetailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.memory_rounded, size: 58, color: studentInk),
    );
  }
}
