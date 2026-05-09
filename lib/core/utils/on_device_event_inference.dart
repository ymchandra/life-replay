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

  static String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
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
