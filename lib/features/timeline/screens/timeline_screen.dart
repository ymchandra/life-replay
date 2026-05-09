import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/features/timeline/widgets/event_tile.dart';
import 'package:life_replay/features/timeline/widgets/timeline_header.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';
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

  void _openEventEditor() {
    context.push('/event/new');
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final zoom = ref.watch(timelineZoomProvider);
    final db = ref.read(databaseProvider);

    return AppScaffold(
      title: 'Life Replay',
      actions: [
        IconButton(
          icon: const Icon(Iconsax.search_normal),
          onPressed: () {},
        ),
      ],
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
                    icon: Iconsax.clock,
                    title: 'No memories yet',
                    subtitle: 'Tap + to capture your first memory',
                  );
                }

                _loadTagsForEvents(events, db);
                final grouped = app_date_utils.groupEventsByDate(events);
                final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                return RefreshIndicator(
                  onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(bottom: 96),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) {
                              final date = sortedDates[idx];
                              final dayEvents = grouped[date]!;
                              int globalOffset = sortedDates
                                  .take(idx)
                                  .fold(0, (acc, d) => acc + (grouped[d]?.length ?? 0));

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TimelineHeader(date: date, eventCount: dayEvents.length),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                    child: MasonryGridView.count(
                                      crossAxisCount: 2,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: dayEvents.length,
                                      itemBuilder: (context, i) {
                                        final event = dayEvents[i];
                                        return EventTile(
                                          event: event,
                                          tags: _tagCache[event.id] ?? [],
                                          animationIndex: globalOffset + i,
                                          onTap: () {
                                            if (event.id != null) {
                                              context.push('/event/${event.id}');
                                            }
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                            childCount: sortedDates.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'timeline_add_event_fab',
        onPressed: _openEventEditor,
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
        showSelectedIcon: false,
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
