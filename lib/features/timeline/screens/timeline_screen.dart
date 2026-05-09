import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/providers/database_provider.dart';
import 'package:life_replay/core/providers/events_provider.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/features/timeline/widgets/grid_timeline_view.dart';
import 'package:life_replay/features/timeline/widgets/linear_timeline_view.dart';
import 'package:life_replay/features/timeline/widgets/on_this_day_banner.dart';
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
    final viewMode = ref.watch(timelineViewModeProvider);
    final db = ref.read(databaseProvider);

    return AppScaffold(
      title: 'Life Replay',
      actions: [
        IconButton(
          tooltip: viewMode == TimelineViewMode.linear
              ? 'Switch to grid view'
              : 'Switch to timeline view',
          icon: Icon(
            viewMode == TimelineViewMode.linear ? Iconsax.grid_2 : Iconsax.menu,
          ),
          onPressed: () {
            ref.read(timelineViewModeProvider.notifier).state =
                viewMode == TimelineViewMode.linear
                    ? TimelineViewMode.grid
                    : TimelineViewMode.linear;
          },
        ),
      ],
      body: eventsAsync.when(
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

          return Column(
            children: [
              const OnThisDayBanner(),
              Expanded(
                child: RefreshIndicator(
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
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'timeline_add_event_fab',
        onPressed: _openEventEditor,
        child: const Icon(Iconsax.add),
      ),
    );
  }
}
