import 'package:life_replay/core/models/life_event.dart';

class PhaseDetector {
  // Lowered from 3 → 2 so chapters appear earlier for new users
  static const int _activeWeekThreshold = 2;
  static const int _quietGapWeeks = 2;

  static const Map<String, List<String>> _phaseKeywords = {
    'work': ['work', 'project', 'meeting', 'deadline', 'client', 'office', 'job', 'task', 'sprint'],
    'travel': ['travel', 'trip', 'flight', 'hotel', 'city', 'country', 'airport', 'vacation', 'journey'],
    'social': ['party', 'friend', 'family', 'dinner', 'event', 'gathering', 'celebration', 'birthday'],
    'creative': ['create', 'art', 'music', 'write', 'design', 'build', 'learn', 'study', 'read'],
    'recovery': ['rest', 'relax', 'sleep', 'health', 'sick', 'quiet', 'slow', 'home', 'recovery'],
  };

  // Tag-to-readable-label map for smarter chapter names
  static const Map<String, String> _tagLabels = {
    'work': 'Work',
    'health': 'Health',
    'travel': 'Travel',
    'social': 'Social',
    'journal': 'Reflection',
    'learning': 'Learning',
    'finance': 'Finance',
    'recovery': 'Recovery',
    'creative': 'Creative',
    'family': 'Family',
    'friend': 'Friends',
  };

  static Map<DateTime, List<LifeEvent>> _groupByWeek(List<LifeEvent> events) {
    final grouped = <DateTime, List<LifeEvent>>{};
    for (final event in events) {
      final weekStart = _weekStart(event.timestamp);
      grouped.putIfAbsent(weekStart, () => []).add(event);
    }
    return grouped;
  }

  static DateTime _weekStart(DateTime date) {
    final dayOfWeek = date.weekday;
    return DateTime(date.year, date.month, date.day - (dayOfWeek - 1));
  }

  static String _detectPhaseType(
    List<LifeEvent> events,
    Map<int, List<String>> tagsByEventId,
  ) {
    // Score from keywords in title/content
    final allText = events
        .map((e) => '${e.title.toLowerCase()} ${e.content.toLowerCase()}')
        .join(' ');

    final scores = <String, int>{};
    for (final entry in _phaseKeywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        score += keyword.allMatches(allText).length;
      }
      scores[entry.key] = score;
    }

    // Boost scores using tags (more reliable than keyword scanning)
    for (final event in events) {
      final tags = tagsByEventId[event.id] ?? [];
      for (final tag in tags) {
        if (scores.containsKey(tag)) scores[tag] = scores[tag]! + 3;
        if (tag == 'health') scores['recovery'] = (scores['recovery'] ?? 0) + 2;
        if (tag == 'learning') scores['creative'] = (scores['creative'] ?? 0) + 2;
      }
    }

    if (scores.values.every((v) => v == 0)) return 'general';
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Derive top tags from events in this phase (for naming + display).
  static List<String> _topTagsForPhase(
    List<LifeEvent> events,
    Map<int, List<String>> tagsByEventId,
  ) {
    final tagCount = <String, int>{};
    for (final event in events) {
      for (final tag in tagsByEventId[event.id] ?? []) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    final sorted = tagCount.keys.toList()
      ..sort((a, b) => tagCount[b]!.compareTo(tagCount[a]!));
    return sorted.take(4).toList();
  }

  static String _smartPhaseName(
    String phaseType,
    List<String> topTags,
    DateTime start,
    int index,
  ) {
    final month = _monthName(start.month);
    final year = start.year;

    // Find the best readable tag label
    String? label1, label2;
    for (final tag in topTags) {
      final readable = _tagLabels[tag];
      if (readable == null) continue;
      if (label1 == null) {
        label1 = readable;
      } else if (label2 == null && readable != label1) {
        label2 = readable;
        break;
      }
    }

    if (label1 != null && label2 != null) {
      return '$label1 & $label2 · $month $year';
    } else if (label1 != null) {
      return '$label1 Chapter · $month $year';
    }

    // Fallback to type-based name (still nicer than old generic)
    switch (phaseType) {
      case 'work':     return 'Work Sprint · $month $year';
      case 'travel':   return 'Travel & Adventure · $month $year';
      case 'social':   return 'Social Season · $month $year';
      case 'creative': return 'Creative Period · $month $year';
      case 'recovery': return 'Rest & Recovery · $month $year';
      default:         return 'Life Chapter · $month $year';
    }
  }

  static String _monthName(int month) {
    const names = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return names[month - 1];
  }

  static String _richDescription(
    List<LifeEvent> events,
    double avgMood,
    List<String> topTags,
    DateTime start,
    DateTime end,
  ) {
    if (events.isEmpty) return 'No events recorded.';

    // Mood arc: compare first half vs second half
    final mid = events.length ~/ 2;
    final firstHalfMood = mid > 0
        ? events.take(mid).map((e) => e.mood).reduce((a, b) => a + b) / mid
        : avgMood;
    final secondHalfMood = mid < events.length
        ? events.skip(mid).map((e) => e.mood).reduce((a, b) => a + b) /
              (events.length - mid)
        : avgMood;

    String arc;
    if (secondHalfMood - firstHalfMood >= 1.0) {
      arc = 'mood improved as it went on';
    } else if (firstHalfMood - secondHalfMood >= 1.0) {
      arc = 'started strong, energy dipped toward the end';
    } else if (avgMood >= 4.0) {
      arc = 'an overall positive and energising period';
    } else if (avgMood <= 2.0) {
      arc = 'a challenging but important period';
    } else {
      arc = 'a steady, balanced period';
    }

    final tagSummary = topTags.take(3).map((t) => _tagLabels[t] ?? t).join(', ');
    final tagPart = tagSummary.isNotEmpty ? ' Themes: $tagSummary.' : '';

    return '${events.length} memories · $arc.$tagPart';
  }

  static double _averageMood(List<LifeEvent> events) {
    if (events.isEmpty) return 3.0;
    return events.map((e) => e.mood).reduce((a, b) => a + b) / events.length;
  }

  static List<Map<String, dynamic>> detectPhases(
    List<LifeEvent> events, {
    Map<int, List<String>> tagsByEventId = const {},
  }) {
    if (events.isEmpty) return [];

    final byWeek = _groupByWeek(events);
    final sortedWeeks = byWeek.keys.toList()..sort();

    final List<List<DateTime>> activeRuns = [];
    List<DateTime> currentRun = [];

    for (int i = 0; i < sortedWeeks.length; i++) {
      final week = sortedWeeks[i];
      final count = byWeek[week]!.length;

      if (count >= _activeWeekThreshold) {
        currentRun.add(week);
      } else {
        if (currentRun.isNotEmpty) {
          final gapAfterRun = i < sortedWeeks.length - 1
              ? sortedWeeks[i + 1].difference(currentRun.last).inDays ~/ 7
              : _quietGapWeeks + 1;
          if (gapAfterRun > _quietGapWeeks) {
            activeRuns.add(List.from(currentRun));
            currentRun = [];
          }
        }
      }
    }
    if (currentRun.isNotEmpty) activeRuns.add(currentRun);

    final results = <Map<String, dynamic>>[];

    for (final run in activeRuns) {
      final start = run.first;
      final end = run.last.add(const Duration(days: 6));

      final phaseEvents = events
          .where((e) => !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final phaseType = _detectPhaseType(phaseEvents, tagsByEventId);
      final topTags = _topTagsForPhase(phaseEvents, tagsByEventId);
      final avgMood = _averageMood(phaseEvents);
      final name = _smartPhaseName(phaseType, topTags, start, results.length);
      final description = _richDescription(phaseEvents, avgMood, topTags, start, end);

      results.add({
        'name': name,
        'start_date': start.millisecondsSinceEpoch,
        'end_date': end.millisecondsSinceEpoch,
        'phase_type': phaseType,
        'description': description,
        'avg_mood': avgMood,
        'event_count': phaseEvents.length,
        'top_tags': topTags.join(','),
      });
    }

    // Return newest first
    return results.reversed.toList();
  }
}
