import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_replay/features/analytics/screens/analytics_screen.dart';
import 'package:life_replay/features/event_editor/screens/event_editor_screen.dart';
import 'package:life_replay/features/memory_replay/screens/memory_replay_screen.dart';
import 'package:life_replay/features/on_this_day/screens/on_this_day_screen.dart';
import 'package:life_replay/features/phases/screens/phases_screen.dart';
import 'package:life_replay/features/timeline/screens/timeline_screen.dart';
import 'package:life_replay/shared/widgets/app_bottom_nav.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TimelineScreen()),
          GoRoute(path: '/on-this-day', builder: (_, __) => const OnThisDayScreen()),
          GoRoute(path: '/phases', builder: (_, __) => const PhasesScreen()),
          GoRoute(path: '/memory-replay', builder: (_, __) => const MemoryReplayScreen()),
          GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
        ],
      ),
      GoRoute(
        path: '/event/new',
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const EventEditorScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.vertical,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/event/:id',
        pageBuilder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: EventEditorScreen(eventId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.vertical,
                child: child,
              );
            },
          );
        },
      ),
    ],
  );
});

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static int _locationToIndex(String location) {
    if (location.startsWith('/on-this-day')) return 1;
    if (location.startsWith('/phases')) return 2;
    if (location.startsWith('/memory-replay')) return 3;
    if (location.startsWith('/analytics')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: primaryAnimation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: child,
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
            case 1:
              context.go('/on-this-day');
            case 2:
              context.go('/phases');
            case 3:
              context.go('/memory-replay');
            case 4:
              context.go('/analytics');
          }
        },
      ),
    );
  }
}
