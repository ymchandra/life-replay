import 'package:intl/intl.dart';
import 'package:life_replay/core/models/life_event.dart';

class LifeMemoryHighlight {
  final String title;
  final DateTime timestamp;
  final int mood;
  final String? locationName;

  const LifeMemoryHighlight({
    required this.title,
    required this.timestamp,
    required this.mood,
    this.locationName,
  });
}

class LifeQuestionAnswer {
  final String question;
  final String answer;
  final List<LifeEvent> matchedEvents;
  final List<String> matchedKeywords;
  final DateTime? inferredStart;
  final DateTime? inferredEnd;
  final String? inferredLocation;
  final List<LifeMemoryHighlight> highlights;

  const LifeQuestionAnswer({
    required this.question,
    required this.answer,
    required this.matchedEvents,
    required this.matchedKeywords,
    required this.inferredStart,
    required this.inferredEnd,
    required this.inferredLocation,
    required this.highlights,
  });

  int get photoCount => matchedEvents.where((e) => e.hasPhoto).length;
  int get videoCount => matchedEvents.where((e) => e.hasVideo).length;
  int get voiceCount => matchedEvents.where((e) => e.hasVoiceNote).length;
  int get textCount => matchedEvents.where((e) => e.hasText).length;

  double get averageMood {
    if (matchedEvents.isEmpty) return 0;
    final total = matchedEvents.fold<int>(0, (sum, e) => sum + e.mood);
    return total / matchedEvents.length;
  }
}

class OnDeviceLifeQa {
  static const Set<String> _stopWords = {
    'how',
    'was',
    'were',
    'doing',
    'during',
    'while',
    'what',
    'when',
    'where',
    'who',
    'why',
    'is',
    'am',
    'are',
    'the',
    'and',
    'for',
    'with',
    'from',
    'into',
    'about',
    'that',
    'this',
    'there',
    'their',
    'have',
    'has',
    'had',
    'did',
    'been',
    'you',
    'your',
    'mine',
    'my',
    'our',
    'its',
    'his',
    'her',
    'them',
    'then',
    'than',
    'today',
    'yesterday',
    'tomorrow',
    'me',
    'i',
    'a',
    'an',
    'to',
    'on',
    'in',
    'of',
  };

  static const List<String> _supportedDateFormats = [
    'd MMM yyyy',
    'd MMMM yyyy',
    'd MMM yy',
    'MMM d yyyy',
    'MMMM d yyyy',
    'yyyy-MM-dd',
    'd/M/yyyy',
    'M/d/yyyy',
    'd-MM-yyyy',
    'd.MM.yyyy',
    'ddMMMyyyy',
    'dMMMyyyy',
    'ddMMMMyyyy',
    'dMMMMyyyy',
  ];

  static LifeQuestionAnswer answer(
    String question, {
    required List<LifeEvent> events,
    Map<int, List<String>> tagsByEventId = const {},
    DateTime? now,
  }) {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      return LifeQuestionAnswer(
        question: question,
        answer:
            'Ask me something like “How was I doing during workouts in Feb 2020 in New York?”',
        matchedEvents: const [],
        matchedKeywords: const [],
        inferredStart: null,
        inferredEnd: null,
        inferredLocation: null,
        highlights: const [],
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final dateRange = _extractDateRange(trimmedQuestion, effectiveNow);
    final location = _extractLocation(trimmedQuestion);
    final keywords = _extractKeywords(trimmedQuestion, location: location);

    final scored = <({LifeEvent event, int score, Set<String> keywordHits})>[];

    for (final event in events) {
      final inDateRange = dateRange == null
          ? true
          : !event.timestamp.isBefore(dateRange.start) &&
              !event.timestamp.isAfter(dateRange.end);
      if (!inDateRange) continue;

      final searchable = '${event.title} ${event.content}'.toLowerCase();
      final eventTags = event.id != null
          ? (tagsByEventId[event.id!] ?? const <String>[])
              .map((t) => t.toLowerCase())
              .toList()
          : const <String>[];

      var score = 0;
      final keywordHits = <String>{};

      if (dateRange != null) {
        score += 4;
      }

      if (location != null && location.isNotEmpty) {
        final eventLocation = (event.locationName ?? '').toLowerCase();
        if (eventLocation.isEmpty) {
          continue;
        }
        final hasLocationMatch = eventLocation.contains(location) || location.contains(eventLocation);
        if (!hasLocationMatch) {
          continue;
        }
        score += 4;
      }

      for (final keyword in keywords) {
        if (searchable.contains(keyword) ||
            eventTags.any((tag) => _keywordMatches(keyword, tag))) {
          keywordHits.add(keyword);
          score += 2;
        }
      }

      if (keywords.isEmpty && (dateRange != null || location != null)) {
        score += 1;
      }

      if (score > 0) {
        scored.add((event: event, score: score, keywordHits: keywordHits));
      }
    }

    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.event.timestamp.compareTo(b.event.timestamp);
    });

    final matchedEvents = scored.map((s) => s.event).toList();
    final matchedKeywords = <String>{};
    for (final s in scored) {
      matchedKeywords.addAll(s.keywordHits);
    }

    if (matchedEvents.isEmpty) {
      return LifeQuestionAnswer(
        question: question,
        answer:
            'I couldn’t find matching memories for that question. Try adding a clearer date, location, or activity keyword.',
        matchedEvents: const [],
        matchedKeywords: keywords,
        inferredStart: dateRange?.start,
        inferredEnd: dateRange?.end,
        inferredLocation: location,
        highlights: const [],
      );
    }

    final highlights = matchedEvents
        .take(5)
        .map(
          (event) => LifeMemoryHighlight(
            title: event.title,
            timestamp: event.timestamp,
            mood: event.mood,
            locationName: event.locationName,
          ),
        )
        .toList();

    final summary = _buildAnswerSummary(
      matchedEvents: matchedEvents,
      matchedKeywords: matchedKeywords.toList(),
      inferredLocation: location,
      inferredStart: dateRange?.start,
      inferredEnd: dateRange?.end,
    );

    return LifeQuestionAnswer(
      question: question,
      answer: summary,
      matchedEvents: matchedEvents,
      matchedKeywords: matchedKeywords.toList(),
      inferredStart: dateRange?.start,
      inferredEnd: dateRange?.end,
      inferredLocation: location,
      highlights: highlights,
    );
  }

  static String _buildAnswerSummary({
    required List<LifeEvent> matchedEvents,
    required List<String> matchedKeywords,
    required String? inferredLocation,
    required DateTime? inferredStart,
    required DateTime? inferredEnd,
  }) {
    final avgMood = matchedEvents.fold<int>(0, (sum, e) => sum + e.mood) / matchedEvents.length;
    final moodLabel = _moodLabel(avgMood);
    final photos = matchedEvents.where((e) => e.hasPhoto).length;
    final videos = matchedEvents.where((e) => e.hasVideo).length;
    final voices = matchedEvents.where((e) => e.hasVoiceNote).length;
    final texts = matchedEvents.where((e) => e.hasText).length;

    final dateFragment = inferredStart == null
        ? ''
        : inferredEnd != null &&
                inferredStart.year == inferredEnd.year &&
                inferredStart.month == inferredEnd.month &&
                inferredStart.day == inferredEnd.day
            ? ' on ${DateFormat('MMM d, yyyy').format(inferredStart)}'
            : ' from ${DateFormat('MMM d, yyyy').format(inferredStart)} to ${DateFormat('MMM d, yyyy').format(inferredEnd ?? inferredStart)}';

    final locationFragment = inferredLocation == null ? '' : ' in ${_titleCase(inferredLocation)}';
    final keywordFragment = matchedKeywords.isEmpty
        ? ''
        : ' around ${matchedKeywords.take(3).join(', ')}';

    return 'I found ${matchedEvents.length} matching memories$dateFragment$locationFragment$keywordFragment. '
        'Your average mood was ${avgMood.toStringAsFixed(1)}/5 ($moodLabel). '
        'Media snapshot: $texts text notes, $photos photos, $videos videos, and $voices voice notes.';
  }

  static String _moodLabel(double mood) {
    if (mood >= 4.5) return 'very positive';
    if (mood >= 3.5) return 'mostly positive';
    if (mood >= 2.5) return 'balanced';
    if (mood >= 1.5) return 'challenging';
    return 'very difficult';
  }

  static ({DateTime start, DateTime end})? _extractDateRange(String text, DateTime now) {
    final lower = _normalize(text);

    if (lower.contains('last week')) {
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final start = end.subtract(const Duration(days: 6));
      return (start: DateTime(start.year, start.month, start.day), end: end);
    }
    if (lower.contains('last month')) {
      final firstOfCurrent = DateTime(now.year, now.month, 1);
      final end = firstOfCurrent.subtract(const Duration(milliseconds: 1));
      final start = DateTime(end.year, end.month, 1);
      return (start: start, end: end);
    }
    if (lower.contains('last year')) {
      final year = now.year - 1;
      return (
        start: DateTime(year, 1, 1),
        end: DateTime(year, 12, 31, 23, 59, 59, 999),
      );
    }

    final between = RegExp(
      r'(?:between|from)\s+([^?.,;]+?)\s+(?:and|to)\s+([^?.,;]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (between != null) {
      final startDate = _tryParseDate(between.group(1) ?? '');
      final endDate = _tryParseDate(between.group(2) ?? '');
      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);
        return start.isBefore(end) || start.isAtSameMomentAs(end)
            ? (start: start, end: end)
            : (start: end, end: DateTime(start.year, start.month, start.day, 23, 59, 59, 999));
      }
    }

    final onDateMatch = RegExp(
      r'(?:on|during)\s+([^?.,;]+)',
      caseSensitive: false,
    ).firstMatch(text);
    final parsedOnDate = _tryParseDate(onDateMatch?.group(1) ?? '');
    if (parsedOnDate != null) {
      final start = DateTime(parsedOnDate.year, parsedOnDate.month, parsedOnDate.day);
      final end = DateTime(parsedOnDate.year, parsedOnDate.month, parsedOnDate.day, 23, 59, 59, 999);
      return (start: start, end: end);
    }

    final anyDate = RegExp(
      r'(\d{1,2}\s*[A-Za-z]{3,9}\s*\d{2,4}|\d{4}-\d{1,2}-\d{1,2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    ).firstMatch(text);
    final parsedAnyDate = _tryParseDate(anyDate?.group(1) ?? '');
    if (parsedAnyDate != null) {
      final start = DateTime(parsedAnyDate.year, parsedAnyDate.month, parsedAnyDate.day);
      final end = DateTime(parsedAnyDate.year, parsedAnyDate.month, parsedAnyDate.day, 23, 59, 59, 999);
      return (start: start, end: end);
    }

    return null;
  }

  static DateTime? _tryParseDate(String input) {
    if (input.trim().isEmpty) return null;

    var candidate = input.trim();
    candidate = candidate
        .replaceAll(',', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(RegExp(r'(\d)([A-Za-z])'), (m) => '${m.group(1)} ${m.group(2)}')
        .replaceAllMapped(RegExp(r'([A-Za-z])(\d)'), (m) => '${m.group(1)} ${m.group(2)}')
        .trim();

    for (final pattern in _supportedDateFormats) {
      try {
        final parsed = DateFormat(pattern).parseStrict(candidate);
        final year = parsed.year < 100 ? 2000 + parsed.year : parsed.year;
        return DateTime(year, parsed.month, parsed.day);
      } catch (_) {}
    }

    try {
      final parsed = DateTime.parse(candidate);
      return DateTime(parsed.year, parsed.month, parsed.day);
    } catch (_) {
      return null;
    }
  }

  static String? _extractLocation(String text) {
    final match = RegExp(r'\bin\s+([^?.,;]+)', caseSensitive: false).firstMatch(text);
    if (match == null) return null;

    final raw = match.group(1)?.trim() ?? '';
    if (raw.isEmpty) return null;

    final truncated = raw
        .split(RegExp(r'\b(?:on|during|from|between|while|when|for|with|and)\b', caseSensitive: false))
        .first
        .trim()
        .toLowerCase();

    return truncated.isEmpty ? null : truncated;
  }

  static List<String> _extractKeywords(String text, {String? location}) {
    final lower = _normalize(text);
    final tokens = RegExp(r"[a-z0-9']+").allMatches(lower).map((m) => m.group(0) ?? '');

    final locationTokens = <String>{
      if (location != null)
        ...RegExp(r"[a-z0-9']+")
            .allMatches(location)
            .map((m) => m.group(0) ?? '')
            .where((t) => t.isNotEmpty),
    };

    final keywords = <String>[];
    for (final token in tokens) {
      if (token.length < 3) continue;
      if (_stopWords.contains(token)) continue;
      if (locationTokens.contains(token)) continue;
      if (RegExp(r'^\d+$').hasMatch(token)) continue;
      if (!keywords.contains(token)) {
        keywords.add(token);
      }
    }
    return keywords;
  }

  static bool _keywordMatches(String keyword, String candidate) {
    final normalizedKeyword = keyword.toLowerCase();
    final normalizedCandidate = candidate.toLowerCase();
    if (normalizedKeyword == normalizedCandidate) return true;
    if (normalizedKeyword.contains(normalizedCandidate) ||
        normalizedCandidate.contains(normalizedKeyword)) {
      return true;
    }
    final singularKeyword = normalizedKeyword.endsWith('s')
        ? normalizedKeyword.substring(0, normalizedKeyword.length - 1)
        : normalizedKeyword;
    final singularCandidate = normalizedCandidate.endsWith('s')
        ? normalizedCandidate.substring(0, normalizedCandidate.length - 1)
        : normalizedCandidate;
    return singularKeyword == singularCandidate;
  }

  static String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _titleCase(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}');
    return words.join(' ');
  }
}
