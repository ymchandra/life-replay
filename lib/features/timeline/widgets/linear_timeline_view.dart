import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/shared/widgets/mood_indicator.dart';
import 'package:life_replay/shared/widgets/tag_chip.dart';

/// Linear timeline view that shows events in chronological order with connecting lines.
class LinearTimelineView extends StatelessWidget {
  final Map<String, List<LifeEvent>> groupedEvents;
  final Map<int, List<String>> tagCache;
  final Function(LifeEvent) onEventTap;

  const LinearTimelineView({
    super.key,
    required this.groupedEvents,
    required this.tagCache,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final sortedDates = groupedEvents.keys.toList()..sort((a, b) => b.compareTo(a));

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 96, top: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, dateIdx) {
                final date = sortedDates[dateIdx];
                final dayEvents = groupedEvents[date]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: app_date_utils.formatDateHeader(date, 'day') == 'Today'
                                  ? cs.primary
                                  : cs.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              app_date_utils.formatDateHeader(date, 'day'),
                              style: context.appText.labelMedium?.copyWith(
                                color: app_date_utils.formatDateHeader(date, 'day') == 'Today'
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant,
                                fontWeight:
                                    app_date_utils.formatDateHeader(date, 'day') == 'Today'
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                            style: context.appText.labelSmall,
                          ),
                        ],
                      ),
                    ),

                    // Timeline events with connectors
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: List.generate(dayEvents.length, (eventIdx) {
                          final event = dayEvents[eventIdx];
                          final isLast = eventIdx == dayEvents.length - 1;
                          final isFirst = eventIdx == 0;

                          return _TimelineEventNode(
                            event: event,
                            tags: tagCache[event.id] ?? [],
                            isFirst: isFirst,
                            isLast: isLast,
                            animationIndex: dateIdx * 3 + eventIdx,
                            onTap: () => onEventTap(event),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
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

/// Timeline node with connector line and event card.
class _TimelineEventNode extends StatelessWidget {
  final LifeEvent event;
  final List<String> tags;
  final bool isFirst;
  final bool isLast;
  final int animationIndex;
  final VoidCallback onTap;

  const _TimelineEventNode({
    required this.event,
    required this.tags,
    required this.isFirst,
    required this.isLast,
    required this.animationIndex,
    required this.onTap,
  });

  Color _accentColor(ColorScheme cs) {
    switch (event.mood) {
      case 1:
        return const Color(0xFFF85149);
      case 2:
        return const Color(0xFFF0883E);
      case 3:
        return cs.primary;
      case 4:
        return const Color(0xFF3FB950);
      case 5:
        return const Color(0xFF58A6FF);
      default:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final accent = _accentColor(cs);
    final hasPhoto = event.photoPath != null && event.photoPath!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timeline rail: top connector + dot + bottom connector
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  // Top connector (all nodes except the first)
                  if (!isFirst)
                    Container(
                      width: 2,
                      height: 16,
                      color: accent.withOpacity(0.3),
                    ),
                  // Dot
                  Container(
                    width: 12,
                    height: 12,
                    margin: EdgeInsets.only(top: isFirst ? 16 : 0),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  // Bottom connector stretches to fill remaining card height
                  if (!isLast)
                    Expanded(
                      child: Center(
                        child: Container(width: 2, color: accent.withOpacity(0.3)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Event card — fills the remaining width
            Expanded(
              child: _TimelineEventCard(
                event: event,
                tags: tags,
                accent: accent,
                hasPhoto: hasPhoto,
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: animationIndex * 35))
        .fadeIn(duration: 320.ms)
        .slideX(begin: -0.08, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }
}

/// Event card for timeline display.
class _TimelineEventCard extends StatelessWidget {
  final LifeEvent event;
  final List<String> tags;
  final Color accent;
  final bool hasPhoto;
  final VoidCallback onTap;

  const _TimelineEventCard({
    required this.event,
    required this.tags,
    required this.accent,
    required this.hasPhoto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final hasContent = event.content.isNotEmpty;

    return Hero(
      tag: 'event_tile_${event.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accent.withOpacity(0.18),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo (if available)
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                    child: Image.file(
                      File(event.photoPath!),
                      width: double.infinity,
                      height: 140,
                      fit: BoxFit.cover,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with mood
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.title,
                              style: context.appText.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          MoodIndicator(mood: event.mood, size: 16),
                        ],
                      ),

                      // Content preview
                      if (hasContent) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.content,
                          style: context.appText.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Tags
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: tags
                              .take(4)
                              .map((t) => TagChip(label: t, compact: true))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 8),

                      // Time info
                      Row(
                        children: [
                          Icon(Iconsax.clock, size: 10, color: cs.onSurfaceVariant.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('h:mm a').format(event.timestamp)}  ·  ${app_date_utils.timeAgo(event.timestamp)}',
                            style: context.appText.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant.withOpacity(0.7),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

