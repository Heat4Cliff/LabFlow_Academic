import 'package:flutter/material.dart';

class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    required this.currentIndex,
    required this.itemCount,
    super.key,
  });

  final int currentIndex;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(itemCount, (index) {
        final isActive = currentIndex == index;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isActive ? 22 : 6,
          height: 6,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF111111) : const Color(0xFFD9DED1),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
