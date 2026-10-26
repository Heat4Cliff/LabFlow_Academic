import 'package:flutter/material.dart';

import '../../domain/lab_report.dart';

class AdminReportHero extends StatelessWidget {
  const AdminReportHero({required this.report, super.key});
  final LabReport report;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFB9F33D),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.report_problem_outlined,
            color: Color(0xFF111111),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                report.reportNumber,
                style: const TextStyle(fontSize: 11, color: Color(0xFFB8BCB3)),
              ),
              const SizedBox(height: 4),
              Text(
                report.title,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _categoryLabel(report.category),
                style: const TextStyle(fontSize: 12, color: Color(0xFFB8BCB3)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class AdminReportTimeline extends StatelessWidget {
  const AdminReportTimeline({required this.report, super.key});
  final LabReport report;

  @override
  Widget build(BuildContext context) {
    // Pakai timestamp lifecycle tersimpan; updatedAt juga berubah untuk edit operasional.
    final entries = <({String label, DateTime date})>[
      (label: 'Laporan dibuat', date: report.createdAt),
      if (report.acknowledgedAt != null)
        (label: 'Laporan diterima Lab Admin', date: report.acknowledgedAt!),
      if (report.resolvedAt != null)
        (label: 'Masalah dinyatakan selesai', date: report.resolvedAt!),
      if (report.closedAt != null)
        (
          label: report.isRejected ? 'Laporan ditolak' : 'Laporan ditutup',
          date: report.closedAt!,
        ),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE2D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Status',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...entries.asMap().entries.map((entry) {
            final item = entry.value;
            final last = entry.key == entries.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFB9F33D),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 38,
                        color: const Color(0xFFDDE2D5),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: last ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(item.date),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF7A8190),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class ReportDetailSmallCard extends StatelessWidget {
  const ReportDetailSmallCard({
    required this.label,
    required this.value,
    required this.icon,
    super.key,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7A8190)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class ReportDetailInfoCard extends StatelessWidget {
  const ReportDetailInfoCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6B7280)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Color(0xFF7A8190)),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _categoryLabel(String category) => switch (category) {
  'asset_damage' => 'Kerusakan Aset',
  'asset_lost' => 'Aset Hilang',
  'network' => 'Jaringan',
  'computer' => 'Komputer',
  'software' => 'Software',
  'facility' => 'Fasilitas',
  'electricity' => 'Kelistrikan',
  _ => 'Lainnya',
};

String _formatDateTime(DateTime value) {
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
  final day = value.day.toString().padLeft(2, '0');
  final month = months[value.month - 1];
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day $month ${value.year} · $hour:$minute';
}
