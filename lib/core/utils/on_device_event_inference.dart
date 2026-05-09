class EventInferenceResult {
  final String title;
  final int mood;

  const EventInferenceResult({
    required this.title,
    required this.mood,
  });
}

class OnDeviceEventInference {
  static const int _maxTitleLength = 57;
  static const int _defaultMaxTags = 6;

  static const List<String> _positiveWords = [
    'happy',
    'great',
    'good',
    'amazing',
    'excited',
    'grateful',
    'love',
    'joy',
    'peaceful',
    'calm',
    'proud',
    'win',
    'progress',
    'fun',
  ];

  static const List<String> _negativeWords = [
    'sad',
    'bad',
    'angry',
    'anxious',
    'stress',
    'stressed',
    'tired',
    'lonely',
    'overwhelmed',
    'upset',
    'hurt',
    'frustrated',
    'exhausted',
    'sick',
  ];

  static const Map<String, List<String>> _tagKeywords = {
    'work': ['work', 'office', 'meeting', 'sprint', 'deadline', 'client', 'project'],
    'health': ['health', 'walk', 'run', 'gym', 'yoga', 'sleep', 'exercise'],
    'travel': ['travel', 'trip', 'flight', 'hotel', 'airport', 'vacation'],
    'social': ['friend', 'family', 'party', 'dinner', 'hangout', 'celebration'],
    'journal': ['journal', 'reflect', 'reflection', 'note', 'writing'],
    'learning': ['learn', 'study', 'course', 'read', 'book', 'practice'],
    'finance': ['finance', 'budget', 'money', 'expense', 'saving', 'invest'],
    'recovery': ['rest', 'recover', 'recovery', 'calm', 'quiet', 'reset'],
  };

  static const Set<String> _stopWords = {
    'the', 'and', 'for', 'with', 'that', 'this', 'from', 'have', 'just', 'into', 'your',
    'were', 'been', 'after', 'before', 'about', 'today', 'then', 'than', 'when', 'while',
    'what', 'where', 'which', 'there', 'their', 'they', 'them', 'feel', 'felt', 'very',
    'really', 'would', 'could', 'should', 'write', 'wrote', 'memory', 'note', 'some',
  };

  static EventInferenceResult infer(
    String text, {
    String? fallbackTitle,
    int fallbackMood = 3,
  }) {
    final normalized = _normalize(text);
    if (normalized.isEmpty) {
      return EventInferenceResult(
        title: fallbackTitle?.trim().isNotEmpty == true ? fallbackTitle!.trim() : 'Memory',
        mood: _clampMood(fallbackMood),
      );
    }

    return EventInferenceResult(
      title: _inferTitle(normalized),
      mood: _inferMood(normalized, fallbackMood),
    );
  }

  static List<String> inferTags(
    String text, {
    List<String> baseTags = const [],
    int maxTags = _defaultMaxTags,
  }) {
    final normalized = _normalize(text);
    final tags = <String>{..._normalizeTags(baseTags)};
    if (maxTags <= 0) return const [];
    if (normalized.isEmpty) return tags.take(maxTags).toList();

    final lower = normalized.toLowerCase();

    // Prefer stable domain tags when matching known activity keywords.
    for (final entry in _tagKeywords.entries) {
      final hasMatch = entry.value.any((keyword) => lower.contains(keyword));
      if (hasMatch) tags.add(entry.key);
    }

    final tokenMatches = RegExp(r"[a-z0-9']+").allMatches(lower);
    final counts = <String, int>{};
    for (final match in tokenMatches) {
      final token = match.group(0) ?? '';
      if (token.length < 4) continue;
      if (_stopWords.contains(token)) continue;
      final isNumeric = RegExp(r'^\d+$').hasMatch(token);
      if (isNumeric) continue;
      counts[token] = (counts[token] ?? 0) + 1;
    }

    final rankedTokens = counts.keys.toList()
      ..sort((a, b) {
        final byCount = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
        if (byCount != 0) return byCount;
        return a.compareTo(b);
      });

    for (final token in rankedTokens) {
      if (tags.length >= maxTags) break;
      tags.add(token);
    }

    return tags.take(maxTags).toList();
  }

  static String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static List<String> _normalizeTags(List<String> tags) {
    final normalized = <String>[];
    for (final tag in tags) {
      final clean = tag.trim().toLowerCase();
      if (clean.isEmpty) continue;
      if (normalized.contains(clean)) continue;
      normalized.add(clean);
    }
    return normalized;
  }

  static String _inferTitle(String normalized) {
    final firstChunk = normalized.split(RegExp(r'[\n\.!?]')).first.trim();
    final candidate = firstChunk.isEmpty ? normalized : firstChunk;
    if (candidate.length <= _maxTitleLength) return candidate;
    return '${candidate.substring(0, _maxTitleLength)}...';
  }

  static int _inferMood(String normalized, int fallbackMood) {
    final lower = normalized.toLowerCase();
    var score = 0;

    for (final word in _positiveWords) {
      if (lower.contains(word)) score += 1;
    }
    for (final word in _negativeWords) {
      if (lower.contains(word)) score -= 1;
    }

    final exclamationCount = '!'.allMatches(normalized).length;
    if (exclamationCount >= 2) score += 1;

    if (lower.contains(':)') || lower.contains('😊') || lower.contains('🙂')) {
      score += 2;
    }
    if (lower.contains(':(') || lower.contains('😞') || lower.contains('😢')) {
      score -= 2;
    }

    if (score <= -3) return 1;
    if (score <= -1) return 2;
    if (score <= 1) return _clampMood(fallbackMood);
    if (score <= 3) return 4;
    return 5;
  }

  static int _clampMood(int mood) {
    if (mood < 1) return 1;
    if (mood > 5) return 5;
    return mood;
  }
}
