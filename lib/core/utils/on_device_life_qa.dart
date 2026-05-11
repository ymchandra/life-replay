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
  final Map<String, int> sourceCounts;

  const LifeQuestionAnswer({
    required this.question,
    required this.answer,
    required this.matchedEvents,
    required this.matchedKeywords,
    required this.inferredStart,
    required this.inferredEnd,
    required this.inferredLocation,
    required this.highlights,
    required this.sourceCounts,
  });

  int get photoCount => matchedEvents.where((e) => e.hasPhoto).length;
  int get videoCount => matchedEvents.where((e) => e.hasVideo).length;
  int get voiceCount => matchedEvents.where((e) => e.hasVoiceNote).length;
  int get textCount => matchedEvents.where((e) => e.hasText).length;

  double get averageMood {
    if (matchedEvents.isEmpty) return 0;
    final total = matchedEvents.fold<double>(0, (sum, e) => sum + e.mood);
    return total / matchedEvents.length;
  }

  String get provenanceSummary {
    if (sourceCounts.isEmpty) return 'Based on on-device memories.';
    final ordered = sourceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = ordered.take(3).map((e) => '${e.value} ${e.key}').join(', ');
    return 'Based on ${matchedEvents.length} memories from $top.';
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
  ];

  static LifeQuestionAnswer answer(
    String question, {
    required List<LifeEvent> events,
    Map<int, List<String>> tagsByEventId = const {},
    Map<int, List<String>> sourceTypesByEventId = const {},
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
        sourceCounts: const {},
      );
    }

    final effectiveNow = now ?? DateTime.now();
    final dateRange = _extractDateRange(trimmedQuestion, effectiveNow);
    final location = _extractLocation(trimmedQuestion);
    final keywords = _extractKeywords(trimmedQuestion, location: location);
    final mediaIntents = _extractMediaIntents(trimmedQuestion);
    final sourceIntents = _extractSourceTypeHints(trimmedQuestion);

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
      final eventSourceTypes = event.id != null
          ? (sourceTypesByEventId[event.id!] ?? <String>[event.sourceType])
          : <String>[event.sourceType];

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

      final matchesMediaIntent = _matchesMediaIntent(event, mediaIntents);
      if (mediaIntents.isNotEmpty && !matchesMediaIntent) {
        continue;
      }
      if (mediaIntents.isNotEmpty && matchesMediaIntent) {
        score += 3;
      }

      final matchesSourceIntent = _matchesSourceIntent(eventSourceTypes, sourceIntents);
      if (sourceIntents.isNotEmpty && !matchesSourceIntent) {
        continue;
      }
      if (sourceIntents.isNotEmpty && matchesSourceIntent) {
        score += 3;
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
        sourceCounts: const {},
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

    final sourceCounts = _buildSourceCounts(
      matchedEvents,
      sourceTypesByEventId: sourceTypesByEventId,
    );

    final summary = _buildAnswerSummary(
      matchedEvents: matchedEvents,
      matchedKeywords: matchedKeywords.toList(),
      inferredLocation: location,
      inferredStart: dateRange?.start,
      inferredEnd: dateRange?.end,
      sourceCounts: sourceCounts,
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
      sourceCounts: sourceCounts,
    );
  }

  static String _buildAnswerSummary({
    required List<LifeEvent> matchedEvents,
    required List<String> matchedKeywords,
    required String? inferredLocation,
    required DateTime? inferredStart,
    required DateTime? inferredEnd,
    required Map<String, int> sourceCounts,
  }) {
    final avgMood =
        matchedEvents.fold<double>(0, (sum, e) => sum + e.mood) / matchedEvents.length;
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
    final sourceFragment = sourceCounts.isEmpty
        ? 'Data source: on-device memories.'
        : 'Data source: ${sourceCounts.entries.map((e) => '${e.value} ${_titleCase(e.key)}').join(', ')}.';

    return 'I found ${matchedEvents.length} matching memories$dateFragment$locationFragment$keywordFragment. '
        'Your average mood was ${avgMood.toStringAsFixed(1)}/5 ($moodLabel). '
        'Media snapshot: $texts ${_pluralize(texts, 'text note')}, '
        '$photos ${_pluralize(photos, 'photo')}, '
        '$videos ${_pluralize(videos, 'video')}, and '
        '$voices ${_pluralize(voices, 'voice note')}. '
        '$sourceFragment';
  }

  static Map<String, int> _buildSourceCounts(
    List<LifeEvent> events, {
    required Map<int, List<String>> sourceTypesByEventId,
  }) {
    final counts = <String, int>{};
    for (final event in events) {
      final sources = event.id != null
          ? (sourceTypesByEventId[event.id!] ?? <String>[event.sourceType])
          : <String>[event.sourceType];
      final unique = sources.map((s) => s.trim().toLowerCase()).toSet();
      for (final source in unique) {
        if (source.isEmpty) continue;
        counts[source] = (counts[source] ?? 0) + 1;
      }
    }
    return counts;
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
      final today = DateTime(now.year, now.month, now.day);
      final startOfThisWeek = today.subtract(Duration(days: today.weekday - DateTime.monday));
      final start = startOfThisWeek.subtract(const Duration(days: 7));
      final end = startOfThisWeek.subtract(const Duration(milliseconds: 1));
      return (start: start, end: end);
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
      final startDate = _tryParseDate(between.group(1) ?? '', referenceNow: now);
      final endDate = _tryParseDate(between.group(2) ?? '', referenceNow: now);
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
    final parsedOnDate = _tryParseDate(onDateMatch?.group(1) ?? '', referenceNow: now);
    if (parsedOnDate != null) {
      final start = DateTime(parsedOnDate.year, parsedOnDate.month, parsedOnDate.day);
      final end = DateTime(parsedOnDate.year, parsedOnDate.month, parsedOnDate.day, 23, 59, 59, 999);
      return (start: start, end: end);
    }

    final anyDate = RegExp(
      r'(\d{1,2}\s*[A-Za-z]{3,9}\s*\d{2,4}|\d{4}-\d{1,2}-\d{1,2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
    ).firstMatch(text);
    final parsedAnyDate = _tryParseDate(anyDate?.group(1) ?? '', referenceNow: now);
    if (parsedAnyDate != null) {
      final start = DateTime(parsedAnyDate.year, parsedAnyDate.month, parsedAnyDate.day);
      final end = DateTime(parsedAnyDate.year, parsedAnyDate.month, parsedAnyDate.day, 23, 59, 59, 999);
      return (start: start, end: end);
    }

    return null;
  }

  static DateTime? _tryParseDate(String input, {DateTime? referenceNow}) {
    if (input.trim().isEmpty) return null;

    var candidate = input.trim();
    candidate = candidate
        .replaceAll(',', ' ')
        .replaceAllMapped(RegExp(r'(\d)([A-Za-z])'), (m) => '${m.group(1)} ${m.group(2)}')
        .replaceAllMapped(RegExp(r'([A-Za-z])(\d)'), (m) => '${m.group(1)} ${m.group(2)}')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final pattern in _supportedDateFormats) {
      try {
        final parsed = DateFormat(pattern).parseStrict(candidate);
        var year = parsed.year;
        if (year < 100) {
          final currentYear = (referenceNow ?? DateTime.now()).year;
          final currentCentury = (currentYear ~/ 100) * 100;
          year = currentCentury + year;
          if (year > currentYear + 50) {
            year -= 100;
          }
        }
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

  static Set<String> _extractMediaIntents(String text) {
    final lower = _normalize(text);
    final intents = <String>{};
    if (RegExp(r'\bphoto|picture|image|gallery\b').hasMatch(lower)) intents.add('photo');
    if (RegExp(r'\bvideo|clip|reel\b').hasMatch(lower)) intents.add('video');
    if (RegExp(r'\bvoice|audio|recording\b').hasMatch(lower)) intents.add('voice');
    if (RegExp(r'\btext|note|journal|write|written\b').hasMatch(lower)) intents.add('text');
    return intents;
  }

  static Set<String> _extractSourceTypeHints(String text) {
    final lower = _normalize(text);
    final hints = <String>{};
    if (RegExp(r'\bphoto|picture|gallery\b').hasMatch(lower)) hints.add('photo');
    if (RegExp(r'\bvideo|clip|reel\b').hasMatch(lower)) hints.add('video');
    if (RegExp(r'\bnote|journal|text\b').hasMatch(lower)) hints.add('note');
    if (RegExp(r'\bcontact|people|person\b').hasMatch(lower)) hints.add('contact');
    if (RegExp(r'\bcall|phone\b').hasMatch(lower)) hints.add('call');
    return hints;
  }

  static bool _matchesMediaIntent(LifeEvent event, Set<String> intents) {
    if (intents.isEmpty) return true;
    for (final intent in intents) {
      if (intent == 'photo' && event.hasPhoto) return true;
      if (intent == 'video' && event.hasVideo) return true;
      if (intent == 'voice' && event.hasVoiceNote) return true;
      if (intent == 'text' && event.hasText) return true;
    }
    return false;
  }

  static bool _matchesSourceIntent(List<String> sourceTypes, Set<String> intents) {
    if (intents.isEmpty) return true;
    final normalized = sourceTypes.map((s) => s.toLowerCase()).toSet();
    for (final hint in intents) {
      if (normalized.contains(hint)) return true;
    }
    return false;
  }

  static bool _keywordMatches(String keyword, String candidate) {
    final normalizedKeyword = keyword.toLowerCase();
    final normalizedCandidate = candidate.toLowerCase();
    if (normalizedKeyword == normalizedCandidate) return true;
    if (normalizedKeyword.contains(normalizedCandidate) ||
        normalizedCandidate.contains(normalizedKeyword)) {
      return true;
    }
    final singularKeyword = _toSingular(normalizedKeyword);
    final singularCandidate = _toSingular(normalizedCandidate);
    return singularKeyword == singularCandidate;
  }

  static String _toSingular(String value) {
    if (value.length <= 3) return value;
    if (value.endsWith('ies') && value.length > 4) {
      return '${value.substring(0, value.length - 3)}y';
    }
    if (value.endsWith('ses') && value.length > 4) {
      return value.substring(0, value.length - 2);
    }
    if (value.endsWith('s') && !value.endsWith('ss')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }

  static String _normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static String _pluralize(int count, String singular) {
    return count == 1 ? singular : '${singular}s';
  }

  static String _titleCase(String text) {
    final words = text
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .map((w) {
      final clean = w.trim();
      if (clean.length == 1) return clean.toUpperCase();
      return '${clean[0].toUpperCase()}${clean.substring(1)}';
    });
    return words.join(' ');
  }
}
