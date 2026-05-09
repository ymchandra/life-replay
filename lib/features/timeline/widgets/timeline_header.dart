import 'package:flutter/material.dart';
import 'package:life_replay/core/theme/context_theme.dart';
import 'package:life_replay/core/utils/date_utils.dart' as app_date_utils;

class TimelineHeader extends StatelessWidget {
  final String date;
  final int eventCount;

  const TimelineHeader({super.key, required this.date, required this.eventCount});

  @override
  Widget build(BuildContext context) {
    final cs = context.appColors;
    final label = app_date_utils.formatDateHeader(date, 'day');
    final isToday = label == 'Today';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isToday ? cs.primary : cs.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
                style: context.appText.labelMedium?.copyWith(
                    color: isToday ? cs.onPrimary : cs.onSurfaceVariant,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$eventCount event${eventCount > 1 ? 's' : ''}',
            style: context.appText.labelSmall,
          ),
        ],
      ),
    );
  }
}
