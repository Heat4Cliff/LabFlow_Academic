import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({required this.currentIndex, super.key});

  final int currentIndex;

  static const _items = [
    _StudentNavItem(Icons.home_rounded, 'Beranda', '/student'),
    _StudentNavItem(Icons.grid_view_rounded, 'Aset', '/student/assets'),
    _StudentNavItem(Icons.swap_horiz_rounded, 'Pinjam', '/student/borrowing'),
    _StudentNavItem(
      Icons.report_problem_outlined,
      'Laporan',
      '/student/reports',
    ),
    _StudentNavItem(Icons.person_outline_rounded, 'Profil', '/student/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, 8),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = index == currentIndex;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: selected ? null : () => context.go(item.route),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFB9F33D)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        size: 21,
                        color: selected
                            ? const Color(0xFF111111)
                            : const Color(0xFFD4D8CE),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: selected
                              ? const Color(0xFF111111)
                              : const Color(0xFFD4D8CE),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _StudentNavItem {
  const _StudentNavItem(this.icon, this.label, this.route);

  final IconData icon;
  final String label;
  final String route;
}
