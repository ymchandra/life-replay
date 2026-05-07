import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/shared/widgets/empty_state.dart';
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';
import 'package:life_replay/shared/widgets/mood_indicator.dart';

final _onThisDayProvider = FutureProvider.autoDispose<List<LifeEvent>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  return db.getEventsForDayAcrossYears(now.month, now.day);
});

class OnThisDayScreen extends ConsumerWidget {
  const OnThisDayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final eventsAsync = ref.watch(_onThisDayProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('On This Day  ·  ${DateFormat('MMMM d').format(now)}'),
        centerTitle: false,
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyState(
              icon: Iconsax.calendar,
              title: 'No memories on this day',
              subtitle: 'Add memories and they\'ll appear here on the same date next year.',
            );
          }

          final byYear = <int, List<LifeEvent>>{};
          for (final e in events) {
            byYear.putIfAbsent(e.timestamp.year, () => []).add(e);
          }
          final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PatternCard(events: events),
              const SizedBox(height: 20),
              ...years.asMap().entries.map((entry) {
                final year = entry.value;
                final yearEvents = byYear[year]!;
                final yearsAgo = now.year - year;
                return _YearSection(
                  year: year,
                  yearsAgo: yearsAgo,
                  events: yearEvents,
                  animIndex: entry.key,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final List<LifeEvent> events;

  const _PatternCard({required this.events});

  String _buildInsight(List<LifeEvent> events) {
    if (events.length < 2) return 'You\'ve captured ${events.length} memory on this day.';
    final avgMood = events.map((e) => e.mood).reduce((a, b) => a + b) / events.length;
    final moodLabel = avgMood >= 4 ? 'positive' : avgMood <= 2 ? 'challenging' : 'mixed';
    return 'You have ${events.length} memories on this day across ${events.map((e) => e.timestamp.year).toSet().length} years — typically a $moodLabel time for you.';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassmorphismCard(
      borderColor: cs.secondary.withOpacity(0.3),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _buildInsight(events),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}

class _YearSection extends StatelessWidget {
  final int year;
  final int yearsAgo;
  final List<LifeEvent> events;
  final int animIndex;

  const _YearSection({
    required this.year,
    required this.yearsAgo,
    required this.events,
    required this.animIndex,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = yearsAgo == 0 ? 'This year' : '$yearsAgo year${yearsAgo > 1 ? 's' : ''} ago';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cs.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '$year  ·  $label',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.primary),
                ),
              ),
            ],
          ),
        ),
        ...events.asMap().entries.map((entry) {
          final event = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassmorphismCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MoodIndicator(mood: event.mood, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title, style: Theme.of(context).textTheme.titleSmall),
                        if (event.content.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.content,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(event.timestamp),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: Duration(milliseconds: animIndex * 80 + entry.key * 40))
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.05, end: 0, duration: 300.ms);
        }),
        const SizedBox(height: 4),
      ],
    );
  }
}
