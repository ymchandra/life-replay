import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';

Map<String, List<LifeEvent>> groupEventsByDate(List<LifeEvent> events) {
  final grouped = <String, List<LifeEvent>>{};
  for (final event in events) {
    final key = DateFormat('yyyy-MM-dd').format(event.timestamp);
    grouped.putIfAbsent(key, () => []).add(event);
  }
  return grouped;
}

Map<String, List<LifeEvent>> groupEventsByWeek(List<LifeEvent> events) {
  final grouped = <String, List<LifeEvent>>{};
  for (final event in events) {
    final weekStart = _weekStart(event.timestamp);
    final key = DateFormat('yyyy-MM-dd').format(weekStart);
    grouped.putIfAbsent(key, () => []).add(event);
  }
  return grouped;
}

Map<String, List<LifeEvent>> groupEventsByMonth(List<LifeEvent> events) {
  final grouped = <String, List<LifeEvent>>{};
  for (final event in events) {
    final key = DateFormat('yyyy-MM').format(event.timestamp);
    grouped.putIfAbsent(key, () => []).add(event);
  }
  return grouped;
}

Map<String, List<LifeEvent>> groupEventsByYear(List<LifeEvent> events) {
  final grouped = <String, List<LifeEvent>>{};
  for (final event in events) {
    final key = DateFormat('yyyy').format(event.timestamp);
    grouped.putIfAbsent(key, () => []).add(event);
  }
  return grouped;
}

DateTime _weekStart(DateTime date) {
  final dayOfWeek = date.weekday;
  return DateTime(date.year, date.month, date.day - (dayOfWeek - 1));
}

String formatDateHeader(String dateKey, String zoom) {
  try {
    switch (zoom) {
      case 'day':
        final date = DateTime.parse(dateKey);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final d = DateTime(date.year, date.month, date.day);
        if (d == today) return 'Today';
        if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
        return DateFormat('EEEE, MMMM d, yyyy').format(date);
      case 'week':
        final weekStart = DateTime.parse(dateKey);
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(weekStart)} – ${DateFormat('MMM d, yyyy').format(weekEnd)}';
      case 'month':
        return DateFormat('MMMM yyyy').format(DateTime.parse('$dateKey-01'));
      case 'year':
        return dateKey;
      default:
        return dateKey;
    }
  } catch (_) {
    return dateKey;
  }
}

String moodEmoji(int mood) {
  switch (mood) {
    case 1:
      return '😞';
    case 2:
      return '😐';
    case 3:
      return '🙂';
    case 4:
      return '😊';
    case 5:
      return '🤩';
    default:
      return '🙂';
  }
}

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays > 365) {
    final years = diff.inDays ~/ 365;
    return '$years year${years > 1 ? 's' : ''} ago';
  } else if (diff.inDays > 30) {
    final months = diff.inDays ~/ 30;
    return '$months month${months > 1 ? 's' : ''} ago';
  } else if (diff.inDays > 0) {
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  } else if (diff.inHours > 0) {
    return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
  } else {
    return 'Just now';
  }
}
