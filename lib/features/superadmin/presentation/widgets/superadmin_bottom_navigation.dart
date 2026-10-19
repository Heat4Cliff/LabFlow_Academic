import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuperadminBottomNavigation extends StatelessWidget {
  const SuperadminBottomNavigation({required this.currentIndex, super.key});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            _buildItem(
              context: context,
              index: 0,
              label: 'Dashboard',
              icon: Icons.dashboard_outlined,
            ),
            _buildItem(
              context: context,
              index: 1,
              label: 'Laboratories',
              icon: Icons.science_outlined,
            ),
            _buildItem(
              context: context,
              index: 2,
              label: 'Users',
              icon: Icons.people_outline_rounded,
            ),
            _buildItem(
              context: context,
              index: 3,
              label: 'Activity',
              icon: Icons.history_rounded,
            ),
            _buildItem(
              context: context,
              index: 4,
              label: 'Profile',
              icon: Icons.person_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          _navigate(context, index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB9F33D) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 23,
                color: isSelected ? const Color(0xFF111111) : Colors.white,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF111111) : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) {
      return;
    }

    switch (index) {
      case 0:
        context.go('/superadmin');
        break;

      case 1:
        context.go('/superadmin/labs');
        break;

      case 2:
        context.go('/superadmin/users');
        break;

      case 3:
        context.go('/superadmin/activity');
        break;

      case 4:
        context.go('/superadmin/profile');
        break;
    }
  }
}
