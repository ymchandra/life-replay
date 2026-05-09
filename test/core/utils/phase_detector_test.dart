import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/utils/phase_detector.dart';

LifeEvent _event(DateTime timestamp, {String title = '', String content = ''}) {
  return LifeEvent(title: title, content: content, mood: 3, timestamp: timestamp);
}

/// Creates [count] events spread within the week starting at [weekStart].
List<LifeEvent> _weekEvents(
  DateTime weekStart,
  int count, {
  String title = '',
  String content = '',
}) {
  return List.generate(
    count,
    (i) => _event(weekStart.add(Duration(days: i % 7)), title: title, content: content),
  );
}

void main() {
  group('PhaseDetector.detectPhases', () {
    test('returns empty list for no events', () {
      expect(PhaseDetector.detectPhases([]), isEmpty);
    });

    test('returns empty list when no week has enough events', () {
      // Only 1 event per week (threshold is 2)
      final week = DateTime(2024, 1, 1); // Monday
      final events = _weekEvents(week, 1);
      expect(PhaseDetector.detectPhases(events), isEmpty);
    });

    test('detects a single active phase', () {
      final week = DateTime(2024, 1, 1); // Monday
      // 2 events in the same week meets the lowered threshold
      final events = _weekEvents(week, 2);
      final phases = PhaseDetector.detectPhases(events);
      expect(phases.length, 1);
      expect(phases.first['event_count'], 2);
    });

    test('detects work phase type from keywords', () {
      final week = DateTime(2024, 1, 1);
      final events = _weekEvents(
        week,
        5,
        title: 'project meeting',
        content: 'office task sprint',
      );
      final phases = PhaseDetector.detectPhases(events);
      expect(phases.length, 1);
      expect(phases.first['phase_type'], 'work');
    });

    test('detects travel phase type from keywords', () {
      final week = DateTime(2024, 1, 1);
      final events = _weekEvents(
        week,
        5,
        title: 'flight to city',
        content: 'hotel trip vacation',
      );
      final phases = PhaseDetector.detectPhases(events);
      expect(phases.length, 1);
      expect(phases.first['phase_type'], 'travel');
    });

    test('phase with no keywords defaults to general', () {
      final week = DateTime(2024, 1, 1);
      final events = _weekEvents(week, 4, title: 'entry', content: 'today');
      final phases = PhaseDetector.detectPhases(events);
      expect(phases.length, 1);
      expect(phases.first['phase_type'], 'general');
    });

    test('phase map contains expected keys', () {
      final week = DateTime(2024, 1, 1);
      final events = _weekEvents(week, 3);
      final phase = PhaseDetector.detectPhases(events).first;
      expect(phase.containsKey('name'), isTrue);
      expect(phase.containsKey('start_date'), isTrue);
      expect(phase.containsKey('end_date'), isTrue);
      expect(phase.containsKey('phase_type'), isTrue);
      expect(phase.containsKey('description'), isTrue);
      expect(phase.containsKey('event_count'), isTrue);
      expect(phase.containsKey('avg_mood'), isTrue);
      expect(phase.containsKey('top_tags'), isTrue);
    });
  });
}
