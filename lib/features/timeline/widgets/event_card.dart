import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/shared/widgets/glassmorphism_card.dart';
import 'package:life_replay/shared/widgets/mood_indicator.dart';
import 'package:life_replay/shared/widgets/tag_chip.dart';

class EventCard extends StatelessWidget {
  final LifeEvent event;
  final List<String> tags;
  final int animationIndex;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.tags,
    this.animationIndex = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 16, 4),
      child: Hero(
        tag: 'event_card_${event.id}',
        child: Material(
          type: MaterialType.transparency,
          child: GlassmorphismCard(
            padding: const EdgeInsets.all(14),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      MoodIndicator(mood: event.mood, size: 18),
                    ],
                  ),
                  if (event.content.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.content,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags
                          .take(4)
                          .map((t) => TagChip(label: t, compact: true))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('h:mm a').format(event.timestamp)}  ·  ${app_date_utils.timeAgo(event.timestamp)}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: Duration(milliseconds: animationIndex * 30)).fadeIn(duration: 300.ms);
  }
}
