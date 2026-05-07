import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/models/life_phase.dart';

void main() {
  final start = DateTime(2024, 1, 1);
  final end = DateTime(2024, 3, 31);

  final phase = LifePhase(
    id: 1,
    name: 'Work Sprint',
    startDate: start,
    endDate: end,
    phaseType: 'work',
    description: 'A busy work period',
  );

  group('LifePhase', () {
    test('toMap returns correct map', () {
      final map = phase.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Work Sprint');
      expect(map['start_date'], start.millisecondsSinceEpoch);
      expect(map['end_date'], end.millisecondsSinceEpoch);
      expect(map['phase_type'], 'work');
      expect(map['description'], 'A busy work period');
    });

    test('toMap omits id when null', () {
      final noId = LifePhase(
        name: 'No ID',
        startDate: start,
        endDate: end,
        phaseType: 'general',
        description: '',
      );
      expect(noId.toMap().containsKey('id'), isFalse);
    });

    test('fromMap reconstructs LifePhase', () {
      final map = phase.toMap();
      final restored = LifePhase.fromMap(map);
      expect(restored.id, phase.id);
      expect(restored.name, phase.name);
      expect(restored.startDate, phase.startDate);
      expect(restored.endDate, phase.endDate);
      expect(restored.phaseType, phase.phaseType);
      expect(restored.description, phase.description);
    });

    test('duration returns difference between end and start', () {
      expect(phase.duration, end.difference(start));
    });

    test('emoji returns correct emoji for known phase types', () {
      final types = {
        'work': '💼',
        'travel': '✈️',
        'social': '👥',
        'creative': '🎨',
        'recovery': '🌿',
      };
      for (final entry in types.entries) {
        final p = LifePhase(
          name: '',
          startDate: start,
          endDate: end,
          phaseType: entry.key,
          description: '',
        );
        expect(p.emoji, entry.value, reason: 'emoji for ${entry.key}');
      }
    });

    test('emoji returns default for unknown phase type', () {
      final p = LifePhase(
        name: '',
        startDate: start,
        endDate: end,
        phaseType: 'unknown',
        description: '',
      );
      expect(p.emoji, '📖');
    });
  });
}
