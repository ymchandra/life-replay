import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

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
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      animationDuration: const Duration(milliseconds: 400),
      destinations: const [
        NavigationDestination(
          icon: Icon(Iconsax.clock),
          selectedIcon: Icon(Iconsax.clock2),
          label: 'Timeline',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.calendar),
          selectedIcon: Icon(Iconsax.calendar2),
          label: 'On This Day',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.category),
          selectedIcon: Icon(Iconsax.category2),
          label: 'Phases',
        ),
        NavigationDestination(
          icon: Icon(Icons.movie_outlined),
          selectedIcon: Icon(Icons.movie),
          label: 'Replay',
        ),
        NavigationDestination(
          icon: Icon(Iconsax.chart),
          selectedIcon: Icon(Iconsax.chart2),
          label: 'Analytics',
        ),
      ],
    );
  }
}
