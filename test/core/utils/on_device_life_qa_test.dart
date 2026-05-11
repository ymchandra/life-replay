import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/utils/on_device_life_qa.dart';

LifeEvent _event({
  required int id,
  required String title,
  required String content,
  required int mood,
  required DateTime timestamp,
  String? location,
  String? photo,
  String? video,
  String? voice,
}) {
  return LifeEvent(
    id: id,
    title: title,
    content: content,
    mood: mood,
    timestamp: timestamp,
    locationName: location,
    photoPath: photo,
    videoPath: video,
    voiceNotePath: voice,
  );
}

void main() {
  group('OnDeviceLifeQa.answer', () {
    test('matches date + location + activity query and summarizes media/mood', () {
      final events = [
        _event(
          id: 1,
          title: 'Workout in Central Park',
          content: 'Strong run and gym circuit in New York.',
          mood: 5,
          timestamp: DateTime(2020, 2, 12, 8, 30),
          location: 'New York',
          photo: '/tmp/workout.jpg',
        ),
        _event(
          id: 2,
          title: 'Project planning',
          content: 'Sprint planning with the team.',
          mood: 3,
          timestamp: DateTime(2020, 2, 12, 13, 00),
          location: 'Boston',
        ),
      ];

      final result = OnDeviceLifeQa.answer(
        'how I was doing during a workout on 12Feb 2020 while I was in New York?',
        events: events,
        tagsByEventId: const {
          1: ['health', 'workout'],
          2: ['work'],
        },
      );

      expect(result.matchedEvents.length, 1);
      expect(result.matchedEvents.first.id, 1);
      expect(result.inferredLocation, 'new york');
      expect(result.inferredStart, DateTime(2020, 2, 12));
      expect(result.photoCount, 1);
      expect(result.averageMood, 5);
      final answer = result.answer.toLowerCase();
      expect(answer, contains('i found 1 matching memories'));
      expect(answer, contains('on feb 12, 2020'));
      expect(answer, contains('in new york'));
      expect(answer, contains('average mood was 5.0/5'));
      expect(answer, contains('media snapshot: 1 text note, 1 photo, 0 videos, and 0 voice notes'));
    });

    test('supports explicit date ranges', () {
      final events = [
        _event(
          id: 1,
          title: 'Trip day 1',
          content: 'Flight and check-in.',
          mood: 4,
          timestamp: DateTime(2021, 3, 1),
        ),
        _event(
          id: 2,
          title: 'Trip day 2',
          content: 'City walk and museum.',
          mood: 5,
          timestamp: DateTime(2021, 3, 2),
        ),
        _event(
          id: 3,
          title: 'Trip day 3',
          content: 'Beach day and sunset walk.',
          mood: 4,
          timestamp: DateTime(2021, 3, 3),
        ),
        _event(
          id: 4,
          title: 'After trip',
          content: 'Back to work.',
          mood: 3,
          timestamp: DateTime(2021, 3, 10),
        ),
      ];

      final result = OnDeviceLifeQa.answer(
        'What happened between Mar 1 2021 and Mar 3 2021?',
        events: events,
      );

      expect(result.matchedEvents.length, 3);
      expect(result.matchedEvents.any((e) => e.timestamp == DateTime(2021, 3, 10)), isFalse);
      expect(result.inferredStart, DateTime(2021, 3, 1));
      expect(result.inferredEnd, DateTime(2021, 3, 3, 23, 59, 59, 999));
    });

    test('returns a no-match answer when filters are too restrictive', () {
      final events = [
        _event(
          id: 1,
          title: 'Morning walk',
          content: 'Nice weather and quiet streets.',
          mood: 4,
          timestamp: DateTime(2023, 6, 1),
          location: 'London',
        ),
      ];

      final result = OnDeviceLifeQa.answer(
        'How was my ski session in Tokyo on Jan 1 2019?',
        events: events,
      );

      expect(result.matchedEvents, isEmpty);
      expect(result.answer.toLowerCase(), contains('couldn’t find matching memories'));
    });

    test('uses event tags as matching signal', () {
      final events = [
        _event(
          id: 99,
          title: 'Morning session',
          content: 'Felt steady and focused.',
          mood: 4,
          timestamp: DateTime(2022, 7, 4),
        ),
      ];

      final result = OnDeviceLifeQa.answer(
        'How were my workouts on Jul 4 2022?',
        events: events,
        tagsByEventId: const {
          99: ['health', 'workout'],
        },
      );

      expect(result.matchedEvents.length, 1);
      expect(result.matchedKeywords, contains('workouts'));
    });
  });
}
