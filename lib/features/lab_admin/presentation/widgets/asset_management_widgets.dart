import 'package:flutter/material.dart';

import '../../../asset/domain/laboratory_asset.dart';
import '../../../laboratory/domain/laboratory.dart';

class LaboratoryAssetCard extends StatelessWidget {
  const LaboratoryAssetCard({
    required this.asset,
    required this.onTap,
    super.key,
  });

  final LaboratoryAsset asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFDDE2D5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AssetThumbnail(asset: asset),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111111),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusBadge(status: asset.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${asset.code} · ${asset.category}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A8190),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AssetInfoRow(
                    icon: Icons.place_outlined,
                    text: asset.location,
                  ),
                  const SizedBox(height: 6),
                  _AssetInfoRow(
                    icon: Icons.inventory_outlined,
                    text: 'Stock: ${asset.stock}',
                  ),
                  const SizedBox(height: 6),
                  _AssetInfoRow(
                    icon: Icons.health_and_safety_outlined,
                    text: 'Kondisi: ${_conditionLabel(asset.condition)}',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: Color(0xFF7A8190),
                    ),
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

class AssetManagementEmptyState extends StatelessWidget {
  const AssetManagementEmptyState({
    required this.title,
    required this.message,
    required this.icon,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  factory AssetManagementEmptyState.noAssets(Laboratory laboratory) =>
      AssetManagementEmptyState(
        title: 'Belum ada aset',
        message: 'Belum ada inventaris yang terdaftar pada ${laboratory.name}.',
        icon: Icons.inventory_2_outlined,
      );

  factory AssetManagementEmptyState.noMembership() =>
      const AssetManagementEmptyState(
        title: 'Belum ada assignment',
        message: 'Akun Lab Admin ini belum memiliki akses aktif ke laboratorium mana pun. Hubungi Superadmin.',
        icon: Icons.assignment_late_outlined,
      );

  factory AssetManagementEmptyState.noLaboratory() =>
      const AssetManagementEmptyState(
        title: 'Laboratorium tidak aktif',
        message: 'Assignment ditemukan, tetapi laboratorium yang ditugaskan sedang tidak aktif.',
        icon: Icons.science_outlined,
      );

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFEAFBCB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: const Color(0xFF111111)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AssetInfoRow extends StatelessWidget {
  const _AssetInfoRow({required this.icon, required this.text, this.trailing});
  final IconData icon;
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: const Color(0xFF7A8190)),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5D6458)),
        ),
      ),
      ?trailing,
    ],
  );
}

class _AssetThumbnail extends StatelessWidget {
  const _AssetThumbnail({required this.asset});
  final LaboratoryAsset asset;

  @override
  Widget build(BuildContext context) {
    const size = 58.0;
    final imageUrl = asset.imageUrl.trim();
    Widget fallback() => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBCB),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(_assetIcon(asset.category), color: const Color(0xFF111111)),
    );
    if (imageUrl.isEmpty) return fallback();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: 180,
        cacheHeight: 180,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: size,
                height: size,
                color: const Color(0xFFF0F3EA),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'available' => (const Color(0xFFE5F6EC), const Color(0xFF188A55)),
      'borrowed' => (const Color(0xFFE8EEFF), const Color(0xFF3559A6)),
      'maintenance' => (const Color(0xFFFFF0CF), const Color(0xFFA86E00)),
      _ => (const Color(0xFFF0F1EE), const Color(0xFF6B7280)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: colors.$2,
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
  'available' => 'Available',
  'borrowed' => 'Borrowed',
  'maintenance' => 'Maintenance',
  'inactive' => 'Inactive',
  _ => status,
};

String _conditionLabel(String condition) => switch (condition) {
  'good' => 'Baik',
  'minor_damage' => 'Kerusakan Ringan',
  'damaged' => 'Rusak',
  _ => condition,
};

IconData _assetIcon(String category) {
  final value = category.toLowerCase();
  if (value.contains('komputer') ||
      value.contains('laptop') ||
      value.contains('pc')) {
    return Icons.computer_rounded;
  }
  if (value.contains('jaringan') ||
      value.contains('router') ||
      value.contains('network')) {
    return Icons.router_outlined;
  }
  if (value.contains('elektronik')) return Icons.memory_rounded;
  return Icons.inventory_2_outlined;
}
