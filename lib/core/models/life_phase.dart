class LifePhase {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String phaseType;
  final String description;

  const LifePhase({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.phaseType,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate.millisecondsSinceEpoch,
      'end_date': endDate.millisecondsSinceEpoch,
      'phase_type': phaseType,
      'description': description,
    };
  }

  static LifePhase fromMap(Map<String, dynamic> map) {
    return LifePhase(
      id: map['id'] as int?,
      name: map['name'] as String,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
      phaseType: map['phase_type'] as String,
      description: map['description'] as String,
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
}
