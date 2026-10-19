import 'package:flutter/material.dart';

/// State standar LabFlow ketika pencarian atau filter
/// tidak menghasilkan data.
///
/// Widget ini berbeda dengan Empty State.
/// Empty State digunakan ketika sumber data memang kosong,
/// sedangkan widget ini digunakan ketika data tersedia
/// tetapi tidak cocok dengan pencarian atau filter aktif.
class LabFlowNoSearchResultsState extends StatelessWidget {
  const LabFlowNoSearchResultsState({
    super.key,
    this.title = 'Tidak ada hasil',
    this.message = 'Coba ubah kata pencarian atau filter yang digunakan.',
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFEAFBCB),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 38, color: const Color(0xFF111111)),
            ),
            const SizedBox(height: 22),
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
}
