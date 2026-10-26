import 'package:flutter/material.dart';

class LabFlowNoSearchResultsState extends StatelessWidget {
  const LabFlowNoSearchResultsState({
    super.key,
    this.title = 'Belum ketemu, nih.',
    this.message = 'Tidak ada hasil untuk pencarian atau filter ini. Coba kata kunci lain.',
    this.icon = Icons.search_off_rounded,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFEAFBCB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 60, color: const Color(0xFF111111)),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF737A70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
