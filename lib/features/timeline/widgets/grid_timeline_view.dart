import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/features/timeline/widgets/event_tile.dart';
import 'package:life_replay/features/timeline/widgets/timeline_header.dart';
import 'package:life_replay/shared/widgets/swipe_to_reveal_card.dart';

/// Grid timeline view (original masonry layout).
class GridTimelineView extends StatelessWidget {
  final Map<String, List<LifeEvent>> groupedEvents;
  final Map<int, List<String>> tagCache;
  final Function(LifeEvent) onEventTap;
  final Function(LifeEvent)? onEventEdit;
  final Function(LifeEvent)? onEventDelete;

  const GridTimelineView({
    super.key,
    required this.groupedEvents,
    required this.tagCache,
    required this.onEventTap,
    this.onEventEdit,
    this.onEventDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sortedDates = groupedEvents.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 96),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, idx) {
                final date = sortedDates[idx];
                final dayEvents = groupedEvents[date]!;
                int globalOffset = sortedDates
                    .take(idx)
                    .fold(0, (acc, d) => acc + (groupedEvents[d]?.length ?? 0));

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
                          final tile = EventTile(
                            event: event,
                            tags: tagCache[event.id] ?? [],
                            animationIndex: globalOffset + i,
                            onTap: () => onEventTap(event),
                          );
                          if (onEventEdit != null && onEventDelete != null) {
                            return SwipeToRevealCard(
                              borderRadius: BorderRadius.circular(16),
                              onEdit: () => onEventEdit!(event),
                              onDelete: () => onEventDelete!(event),
                              child: tile,
                            );
                          }
                          return tile;
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
    );
  }
}

