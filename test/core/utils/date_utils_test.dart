import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/utils/date_utils.dart';

LifeEvent _event(DateTime timestamp, {String title = 'T', String content = ''}) {
  return LifeEvent(title: title, content: content, mood: 3, timestamp: timestamp);
}

void main() {
  group('moodEmoji', () {
    test('returns correct emoji for moods 1-5', () {
      expect(moodEmoji(1), '😞');
      expect(moodEmoji(2), '😐');
      expect(moodEmoji(3), '🙂');
      expect(moodEmoji(4), '😊');
      expect(moodEmoji(5), '🤩');
    });

    test('returns default emoji for out-of-range mood', () {
      expect(moodEmoji(0), '🙂');
      expect(moodEmoji(6), '🙂');
    });
  });

  group('groupEventsByDate', () {
    test('groups events on the same date together', () {
      final day1 = DateTime(2024, 6, 10, 8);
      final day1b = DateTime(2024, 6, 10, 20);
      final day2 = DateTime(2024, 6, 11, 9);
      final events = [_event(day1), _event(day1b), _event(day2)];
      final grouped = groupEventsByDate(events);
      expect(grouped.keys.length, 2);
      expect(grouped['2024-06-10']!.length, 2);
      expect(grouped['2024-06-11']!.length, 1);
    });

    test('returns empty map for empty list', () {
      expect(groupEventsByDate([]), isEmpty);
    });
  });

  group('groupEventsByWeek', () {
    test('groups events in the same week together', () {
      // Monday and Friday of the same week
      final mon = DateTime(2024, 6, 10); // Monday
      final fri = DateTime(2024, 6, 14); // Friday
      final nextMon = DateTime(2024, 6, 17); // Next Monday
      final events = [_event(mon), _event(fri), _event(nextMon)];
      final grouped = groupEventsByWeek(events);
      expect(grouped.keys.length, 2);
      expect(grouped['2024-06-10']!.length, 2);
      expect(grouped['2024-06-17']!.length, 1);
    });
  });

  group('groupEventsByMonth', () {
    test('groups events in the same month together', () {
      final june1 = DateTime(2024, 6, 1);
      final june30 = DateTime(2024, 6, 30);
      final july1 = DateTime(2024, 7, 1);
      final events = [_event(june1), _event(june30), _event(july1)];
      final grouped = groupEventsByMonth(events);
      expect(grouped['2024-06']!.length, 2);
      expect(grouped['2024-07']!.length, 1);
    });
  });

  group('groupEventsByYear', () {
    test('groups events in the same year together', () {
      final y2024 = DateTime(2024, 3, 1);
      final y2025 = DateTime(2025, 1, 1);
      final events = [_event(y2024), _event(y2024), _event(y2025)];
      final grouped = groupEventsByYear(events);
      expect(grouped['2024']!.length, 2);
      expect(grouped['2025']!.length, 1);
    });
  });

  group('timeAgo', () {
    test('returns "Just now" for recent timestamps', () {
      expect(timeAgo(DateTime.now().subtract(const Duration(minutes: 5))), 'Just now');
    });

    test('returns hours ago', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(hours: 3)));
      expect(result, '3 hours ago');
    });

    test('returns singular hour', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(hours: 1)));
      expect(result, '1 hour ago');
    });

    test('returns days ago', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 5)));
      expect(result, '5 days ago');
    });

    test('returns singular day', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 1)));
      expect(result, '1 day ago');
    });

    test('returns months ago', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 60)));
      expect(result, '2 months ago');
    });

    test('returns years ago', () {
      final result = timeAgo(DateTime.now().subtract(const Duration(days: 730)));
      expect(result, '2 years ago');
    });
  });
}
