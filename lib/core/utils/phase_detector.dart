import 'package:life_replay/core/models/life_event.dart';

class PhaseDetector {
  static const int _activeWeekThreshold = 3;
  static const int _quietGapWeeks = 2;

  static const Map<String, List<String>> _phaseKeywords = {
    'work': ['work', 'project', 'meeting', 'deadline', 'client', 'office', 'job', 'task', 'sprint'],
    'travel': ['travel', 'trip', 'flight', 'hotel', 'city', 'country', 'airport', 'vacation', 'journey'],
    'social': ['party', 'friend', 'family', 'dinner', 'event', 'gathering', 'celebration', 'birthday'],
    'creative': ['create', 'art', 'music', 'write', 'design', 'build', 'learn', 'study', 'read'],
    'recovery': ['rest', 'relax', 'sleep', 'health', 'sick', 'quiet', 'slow', 'home', 'recovery'],
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

  static String _detectPhaseType(List<LifeEvent> events) {
    final allText = events
        .map((e) => '${e.title.toLowerCase()} ${e.content.toLowerCase()}')
        .join(' ');

    final scores = <String, int>{};
    for (final entry in _phaseKeywords.entries) {
      var score = 0;
      for (final keyword in entry.value) {
        final count = keyword.allMatches(allText).length;
        score += count;
      }
      scores[entry.key] = score;
    }

    if (scores.values.every((v) => v == 0)) return 'general';

    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  static String _phaseNameFromType(String phaseType, int index) {
    switch (phaseType) {
      case 'work':
        return 'Work Intensity Phase ${index + 1}';
      case 'travel':
        return 'Travel Phase ${index + 1}';
      case 'social':
        return 'Social Phase ${index + 1}';
      case 'creative':
        return 'Creative Phase ${index + 1}';
      case 'recovery':
        return 'Recovery Period ${index + 1}';
      default:
        return 'Life Chapter ${index + 1}';
    }
  }

  static List<Map<String, dynamic>> detectPhases(List<LifeEvent> events) {
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
    if (currentRun.isNotEmpty) {
      activeRuns.add(currentRun);
    }

    final results = <Map<String, dynamic>>[];
    final phaseCountByType = <String, int>{};

    for (final run in activeRuns) {
      final start = run.first;
      final end = run.last.add(const Duration(days: 6));

      final phaseEvents = events.where((e) {
        return !e.timestamp.isBefore(start) && !e.timestamp.isAfter(end);
      }).toList();

      final phaseType = _detectPhaseType(phaseEvents);
      phaseCountByType[phaseType] = (phaseCountByType[phaseType] ?? 0);
      final index = phaseCountByType[phaseType]!;
      phaseCountByType[phaseType] = index + 1;

      results.add({
        'name': _phaseNameFromType(phaseType, index),
        'start_date': start.millisecondsSinceEpoch,
        'end_date': end.millisecondsSinceEpoch,
        'phase_type': phaseType,
        'description': '${phaseEvents.length} events recorded during this phase.',
        'event_count': phaseEvents.length,
      });
    }

    return results;
  }
}
