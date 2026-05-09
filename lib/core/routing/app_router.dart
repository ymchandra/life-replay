import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:life_replay/features/event_editor/screens/event_editor_screen.dart';
import 'package:life_replay/features/insights/screens/insights_screen.dart';
import 'package:life_replay/features/memory_replay/screens/memory_replay_screen.dart';
import 'package:life_replay/features/timeline/screens/timeline_screen.dart';
import 'package:life_replay/shared/widgets/app_bottom_nav.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const TimelineScreen()),
          GoRoute(path: '/memory-replay', builder: (_, __) => const MemoryReplayScreen()),
          GoRoute(path: '/insights', builder: (_, __) => const InsightsScreen()),
        ],
      ),
      GoRoute(
        path: '/event/new',
        pageBuilder: (_, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: EventEditorScreen(initialContent: state.extra as String?),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.vertical,
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: '/event/:id',
        pageBuilder: (_, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: EventEditorScreen(eventId: id),
            transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                SharedAxisTransition(
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  transitionType: SharedAxisTransitionType.vertical,
                  child: child,
                ),
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
    if (location.startsWith('/memory-replay')) return 1;
    if (location.startsWith('/insights')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _locationToIndex(location);

    return AppScaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, primaryAnimation, secondaryAnimation) =>
            FadeThroughTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            ),
        child: KeyedSubtree(key: ValueKey(currentIndex), child: child),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/');
            case 1: context.go('/memory-replay');
            case 2: context.go('/insights');
          }
        },
      ),
    );
  }
}
