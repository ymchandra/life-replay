import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/theme/app_theme.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;
import 'package:life_replay/shared/widgets/mood_indicator.dart';
import 'package:life_replay/shared/widgets/tag_chip.dart';

/// Adaptive tile for the masonry timeline grid.
/// Height adapts naturally to content — image, text length, tags.
class EventTile extends StatelessWidget {
  final LifeEvent event;
  final List<String> tags;
  final int animationIndex;
  final VoidCallback? onTap;

  const EventTile({
    super.key,
    required this.event,
    required this.tags,
    this.animationIndex = 0,
    this.onTap,
  });

  // Tiles with long content, a photo, or many tags get a wide slot (2 cols).
  bool get _isWide {
    final contentLong = event.content.length > 140;
    final hasPhoto = event.photoPath != null && event.photoPath!.isNotEmpty;
    final tagHeavy = tags.length >= 3;
    return hasPhoto || (contentLong && tagHeavy);
  }

  // Accent hue derived from mood so each tile has a subtle personality.
  Color _accent(ColorScheme cs) {
    return AppTheme.moodColor(event.mood, fallback: cs.primary);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final accent = _accent(cs);
    final hasPhoto = event.photoPath != null && event.photoPath!.isNotEmpty;
    final hasContent = event.content.isNotEmpty;
    final previewLineCount = _isWide ? 4 : 2;

    return Hero(
      tag: 'event_tile_${event.id}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
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
                // Photo (only if available)
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.file(
                      File(event.photoPath!),
                      width: double.infinity,
                      height: _isWide ? 180 : 120,
                      fit: BoxFit.cover,
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Accent top bar
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

                      if (hasContent) ...[
                        const SizedBox(height: 6),
                        Text(
                          event.content,
                          style: context.appText.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                          maxLines: previewLineCount,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: tags
                              .take(_isWide ? 5 : 3)
                              .map((t) => TagChip(label: t, compact: true))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 8),

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
    ).animate(
      delay: Duration(milliseconds: animationIndex * 35),
    ).fadeIn(duration: 320.ms).slideY(begin: 0.04, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }
}

