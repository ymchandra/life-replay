class LifePhase {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String phaseType;
  final String description;
  final double avgMood;
  final int eventCount;
  final List<String> topTags;

  const LifePhase({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.phaseType,
    required this.description,
    this.avgMood = 3.0,
    this.eventCount = 0,
    this.topTags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'phase_type': phaseType,
      'description': description,
      'avg_mood': avgMood,
      'event_count': eventCount,
      'top_tags': topTags.join(','),
    };
  }

  static LifePhase fromMap(Map<String, dynamic> map) {
    final rawTags = (map['top_tags'] as String?) ?? '';
    return LifePhase(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      phaseType: map['phase_type'] as String,
      description: map['description'] as String,
      avgMood: (map['avg_mood'] as num?)?.toDouble() ?? 3.0,
      eventCount: (map['event_count'] as int?) ?? 0,
      topTags: rawTags.isEmpty ? [] : rawTags.split(','),
    );
  }

  Duration get duration => endDate.difference(startDate);

  String get emoji {
    switch (phaseType) {
      case 'work':
        return '💼';
      case 'travel':
        return '✈️';
      case 'social':
        return '👥';
      case 'creative':
        return '🎨';
      case 'recovery':
        return '🌿';
      default:
        return '📖';
    }
  }

  String get moodEmoji {
    if (avgMood >= 4.5) return '🤩';
    if (avgMood >= 3.5) return '😊';
    if (avgMood >= 2.5) return '🙂';
    if (avgMood >= 1.5) return '😐';
    return '😞';
  }
}
