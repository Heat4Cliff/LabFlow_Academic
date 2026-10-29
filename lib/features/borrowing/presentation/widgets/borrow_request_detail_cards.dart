import 'package:flutter/material.dart';

import '../../domain/borrow_request.dart';
import '../cubit/admin_borrow_request_detail_state.dart';

class BorrowRequestIdentityCard extends StatelessWidget {
  const BorrowRequestIdentityCard({required this.request, super.key});
  final BorrowRequest request;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Color(0xFFEAFBCB),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_outline_rounded),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Peminjam',
                style: TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
              ),
              const SizedBox(height: 4),
              Text(
                request.studentNameLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                request.requestNumber,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class BorrowRequestItemsCard extends StatelessWidget {
  const BorrowRequestItemsCard({required this.state, super.key});
  final AdminBorrowRequestDetailState state;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aset yang Diminta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        if (state.itemsLoading)
          const Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Memuat detail item...'),
            ],
          )
        else if (state.itemsError.isNotEmpty)
          Text(
            state.itemsError,
            style: const TextStyle(color: Color(0xFFBD3232)),
          )
        else if (state.items.isEmpty)
          const Text(
            'Detail item belum tersedia.',
            style: TextStyle(color: Color(0xFF7A8190)),
          )
        else
          for (var index = 0; index < state.items.length; index++) ...[
            if (index > 0) const Divider(height: 22, color: Color(0xFFE2E6DC)),
            _BorrowRequestItemRow(item: state.items[index]),
          ],
      ],
    ),
  );
}

class _BorrowRequestItemRow extends StatelessWidget {
  const _BorrowRequestItemRow({required this.item});
  final BorrowRequestItem item;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBCB),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.inventory_2_outlined),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.itemName,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 3),
            Text(
              item.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
            ),
          ],
        ),
      ),
    ],
  );
}

class BorrowRequestDateCard extends StatelessWidget {
  const BorrowRequestDateCard({
    required this.label,
    required this.date,
    required this.icon,
    super.key,
  });
  final String label;
  final DateTime date;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5F6672)),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF7A8190)),
        ),
        const SizedBox(height: 3),
        Text(
          _formatDate(date),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class BorrowRequestTextCard extends StatelessWidget {
  const BorrowRequestTextCard({
    required this.title,
    required this.text,
    required this.icon,
    super.key,
  });
  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFDDE2D5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5F6672)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A8190)),
              ),
              const SizedBox(height: 5),
              Text(
                text,
                style: const TextStyle(
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  if (date.millisecondsSinceEpoch == 0) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
