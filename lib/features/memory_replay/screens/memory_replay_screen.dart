import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/shared/widgets/app_hero_image.dart';
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';
import 'package:life_replay/shared/widgets/mood_indicator.dart';

final _replayEventsProvider = StateProvider<List<LifeEvent>>((ref) => []);
final _replayPageProvider = StateProvider<int>((ref) => 0);
final _isReplayingProvider = StateProvider<bool>((ref) => false);

class MemoryReplayScreen extends ConsumerStatefulWidget {
  const MemoryReplayScreen({super.key});

  @override
  ConsumerState<MemoryReplayScreen> createState() => _MemoryReplayScreenState();
}

class _MemoryReplayScreenState extends ConsumerState<MemoryReplayScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadAndReplay() async {
    final db = ref.read(databaseProvider);
    final events = await db.getEventsByDateRange(_startDate, _endDate);
    if (events.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No memories found in this period')),
        );
      }
      return;
    }
    events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    ref.read(_replayEventsProvider.notifier).state = events;
    ref.read(_replayPageProvider.notifier).state = 0;
    ref.read(_isReplayingProvider.notifier).state = true;
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReplaying = ref.watch(_isReplayingProvider);
    final replayEvents = ref.watch(_replayEventsProvider);
    final currentPage = ref.watch(_replayPageProvider);

    if (isReplaying && replayEvents.isNotEmpty) {
      return _ReplayView(
        events: replayEvents,
        currentPage: currentPage,
        pageController: _pageController,
        onClose: () {
          ref.read(_isReplayingProvider.notifier).state = false;
          ref.read(_replayEventsProvider.notifier).state = [];
          ref.read(_replayPageProvider.notifier).state = 0;
        },
        onPageChanged: (page) {
          ref.read(_replayPageProvider.notifier).state = page;
        },
      );
    }

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Memory Replay'), centerTitle: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeroImage(
              assetPath: 'assets/images/hero_replay.png',
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'Reconstruct a period of your life',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a time range to replay your memories like a movie, one event at a time.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            GlassmorphismCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Iconsax.calendar, size: 20, color: cs.primary),
                ),
                title: Text(
                  '${DateFormat('MMM d, yyyy').format(_startDate)} → ${DateFormat('MMM d, yyyy').format(_endDate)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text(
                  '${_endDate.difference(_startDate).inDays} days',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                trailing: const Icon(Iconsax.edit, size: 18),
                onTap: _pickDateRange,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loadAndReplay,
                icon: const Icon(Iconsax.play),
                label: const Text('Start Replay'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                'Your memories will be replayed\nin chronological order',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ReplayView extends StatelessWidget {
  final List<LifeEvent> events;
  final int currentPage;
  final PageController pageController;
  final VoidCallback onClose;
  final ValueChanged<int> onPageChanged;

  const _ReplayView({
    required this.events,
    required this.currentPage,
    required this.pageController,
    required this.onClose,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, color: Colors.white70),
                    onPressed: onClose,
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: events.isEmpty ? 0 : (currentPage + 1) / events.length,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${currentPage + 1} / ${events.length}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _EventPage(event: events[index]);
                },
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(
                    icon: Iconsax.arrow_left,
                    enabled: currentPage > 0,
                    onTap: currentPage > 0
                        ? () => pageController.previousPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                  Text(
                    DateFormat('MMMM d, yyyy').format(events[currentPage].timestamp),
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  _NavButton(
                    icon: Iconsax.arrow_right,
                    enabled: currentPage < events.length - 1,
                    onTap: currentPage < events.length - 1
                        ? () => pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _NavButton({
    required this.icon,
    required this.enabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.3,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _EventPage extends StatelessWidget {
  final LifeEvent event;

  const _EventPage({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          MoodIndicator(mood: event.mood, size: 48)
              .animate()
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 24),
          Text(
            event.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.12, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
          if (event.content.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              event.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    height: 1.7,
                  ),
              textAlign: TextAlign.center,
            ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
          ],
          const SizedBox(height: 32),
          Text(
            DateFormat('EEEE, MMMM d, yyyy  ·  h:mm a').format(event.timestamp),
            style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 0.4),
          ).animate(delay: 320.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
