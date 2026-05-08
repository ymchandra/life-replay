import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/features/quick_capture/widgets/quick_capture_sheet.dart';
import 'package:life_replay/features/timeline/widgets/event_card.dart';
import 'package:life_replay/features/timeline/widgets/timeline_header.dart';
import 'package:life_replay/shared/widgets/empty_state.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final Map<int, List<String>> _tagCache = {};

  Future<void> _loadTagsForEvents(List<dynamic> events, DatabaseHelper db) async {
    for (final event in events) {
      if (event.id != null && !_tagCache.containsKey(event.id)) {
        final tags = await db.getTagsForEvent(event.id!);
        if (mounted) {
          setState(() {
            _tagCache[event.id!] = tags;
          });
        }
      }
    }
  }

  void _openQuickCapture() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickCaptureSheet(
        onSaved: () {
          ref.read(eventsProvider.notifier).loadEvents();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final zoom = ref.watch(timelineZoomProvider);
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Replay'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.search_normal),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _ZoomSelector(zoom: zoom),
          Expanded(
            child: eventsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (events) {
                if (events.isEmpty) {
                  return const EmptyState(
                    imagePath: 'assets/images/hero_timeline.png',
                    title: 'No memories yet',
                    subtitle: 'Tap + to capture your first memory',
                  );
                }

                _loadTagsForEvents(events, db);
                final grouped = app_date_utils.groupEventsByDate(events);
                final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: sortedDates.length,
                    itemBuilder: (context, idx) {
                      final date = sortedDates[idx];
                      final dayEvents = grouped[date]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TimelineHeader(date: date, eventCount: dayEvents.length),
                          ...dayEvents.asMap().entries.map((entry) {
                            final event = entry.value;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _TimelineConnector(
                                  isFirst: entry.key == 0 && idx == 0,
                                  isLast: entry.key == dayEvents.length - 1 &&
                                      idx == sortedDates.length - 1,
                                ),
                                Expanded(
                                  child: EventCard(
                                    event: event,
                                    tags: _tagCache[event.id] ?? [],
                                    animationIndex: idx * 3 + entry.key,
                                    onTap: () {
                                      if (event.id != null) {
                                        context.push('/event/${event.id}');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'timeline_add_event_fab',
        onPressed: _openQuickCapture,
        child: const Icon(Iconsax.add),
      ),
    );
  }
}

class _ZoomSelector extends ConsumerWidget {
  final TimelineZoom zoom;

  const _ZoomSelector({required this.zoom});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SegmentedButton<TimelineZoom>(
        segments: const [
          ButtonSegment(value: TimelineZoom.day, label: Text('Day'), icon: Icon(Iconsax.sun_1, size: 14)),
          ButtonSegment(value: TimelineZoom.week, label: Text('Week'), icon: Icon(Iconsax.calendar_1, size: 14)),
          ButtonSegment(value: TimelineZoom.month, label: Text('Month'), icon: Icon(Iconsax.calendar_2, size: 14)),
          ButtonSegment(value: TimelineZoom.year, label: Text('Year'), icon: Icon(Iconsax.calendar2, size: 14)),
        ],
        selected: {zoom},
        onSelectionChanged: (val) {
          ref.read(timelineZoomProvider.notifier).state = val.first;
        },
        style: const ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  final bool isFirst;
  final bool isLast;

  const _TimelineConnector({required this.isFirst, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withOpacity(0.25);
    return SizedBox(
      width: 32,
      child: Column(
        children: [
          if (!isFirst)
            Container(width: 1, height: 8, color: color)
          else
            const SizedBox(height: 8),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
          if (!isLast)
            Container(width: 1, height: 80, color: color)
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}
