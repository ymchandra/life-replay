import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/features/timeline/widgets/grid_timeline_view.dart';
import 'package:life_replay/features/timeline/widgets/linear_timeline_view.dart';
import 'package:life_replay/shared/widgets/app_scaffold.dart';
import 'package:life_replay/shared/widgets/empty_state.dart';

enum TimelineViewMode { linear, grid }

final timelineViewModeProvider = StateProvider<TimelineViewMode>((ref) => TimelineViewMode.linear);

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

  void _navigateToEvent(dynamic event) {
    if (event.id != null) {
      context.push('/event/${event.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsProvider);
    final zoom = ref.watch(timelineZoomProvider);
    final viewMode = ref.watch(timelineViewModeProvider);
    final db = ref.read(databaseProvider);
    final cs = context.appColors;

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
          // Controls row: zoom selector + view mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
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
                ),
                const SizedBox(width: 12),
                // View mode toggle
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => ref.read(timelineViewModeProvider.notifier).state = TimelineViewMode.linear,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: viewMode == TimelineViewMode.linear ? cs.primary : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                            ),
                            child: Icon(
                              Iconsax.menu,
                              size: 18,
                              color: viewMode == TimelineViewMode.linear ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => ref.read(timelineViewModeProvider.notifier).state = TimelineViewMode.grid,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: viewMode == TimelineViewMode.grid ? cs.primary : Colors.transparent,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                            ),
                            child: Icon(
                              Iconsax.grid_2,
                              size: 18,
                              color: viewMode == TimelineViewMode.grid ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

                return RefreshIndicator(
                  onRefresh: () => ref.read(eventsProvider.notifier).loadEvents(),
                  child: viewMode == TimelineViewMode.linear
                      ? LinearTimelineView(
                          groupedEvents: grouped,
                          tagCache: _tagCache,
                          onEventTap: _navigateToEvent,
                        )
                      : GridTimelineView(
                          groupedEvents: grouped,
                          tagCache: _tagCache,
                          onEventTap: _navigateToEvent,
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
