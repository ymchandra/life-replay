import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.outlineVariant.withOpacity(0.45))),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SalomonBottomBar(
        currentIndex: currentIndex,
        onTap: onTap,
        duration: const Duration(milliseconds: 280),
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        curve: Curves.easeOutCubic,
        backgroundColor: cs.surface,
        itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        unselectedItemColor: cs.onSurfaceVariant,
        selectedItemColor: cs.onSecondary,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Iconsax.clock, size: 20),
            activeIcon: const Icon(Iconsax.clock, size: 22),
            title: const Text('Journey', style: TextStyle(fontWeight: FontWeight.w700)),
            selectedColor: cs.secondary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Iconsax.play, size: 20),
            activeIcon: const Icon(Iconsax.play_cricle, size: 22),
            title: const Text('Replay', style: TextStyle(fontWeight: FontWeight.w700)),
            selectedColor: cs.secondary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Iconsax.chart, size: 20),
            activeIcon: const Icon(Iconsax.chart, size: 22),
            title: const Text('Insights', style: TextStyle(fontWeight: FontWeight.w700)),
            selectedColor: cs.secondary,
          ),
        ],
      ),
    );
  }
}
