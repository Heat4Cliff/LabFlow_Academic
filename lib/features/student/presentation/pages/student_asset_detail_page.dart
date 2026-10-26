import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/student_service.dart';
import '../../domain/student_models.dart';
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
    setState(() {
      _future = next;
    });
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
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 34),
        children: [
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Detail Aset',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1.35,
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
          const SizedBox(height: 18),
          Text(
            asset.name,
            style: const TextStyle(
              fontSize: 26,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            asset.code,
            style: const TextStyle(
              fontSize: 12,
              color: studentMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _section(
            children: [
              _row('Laboratorium', data.laboratory?.name ?? '-'),
              _row('Lokasi', asset.location),
              _row('Kategori', asset.category),
              _row('Stok', '${asset.stock} unit'),
              _row(
                'Ketersediaan',
                asset.isAvailable ? 'Tersedia' : 'Tidak tersedia',
              ),
              _row('Kondisi', _condition(asset.condition)),
            ],
          ),
          if (asset.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            _section(
              children: [
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 7),
                Text(
                  asset.description,
                  style: const TextStyle(height: 1.45, color: studentMuted),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: asset.isAvailable
                  ? () => context.push(
                      '/student/borrowing/request?assetId=${asset.id}',
                    )
                  : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: Text(
                asset.isAvailable ? 'Ajukan Peminjaman' : 'Aset Tidak Tersedia',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: studentInk,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFB8BCB3),
                disabledForegroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: studentSoftLime,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 19),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Pengajuan baru berstatus Menunggu. Stok baru berubah saat Lab Admin menugaskan aset.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: studentBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: studentMuted),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
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
