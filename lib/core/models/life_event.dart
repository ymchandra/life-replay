class LifeEvent {
  final int? id;
  final String title;
  final String content;
  final int mood;
  final DateTime timestamp;
  final String? photoPath;
  final double? latitude;
  final double? longitude;
  final int? phaseId;

  const LifeEvent({
    this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    this.photoPath,
    this.latitude,
    this.longitude,
    this.phaseId,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'content': content,
      'mood': mood,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'phase_id': phaseId,
    };
  }

  static LifeEvent fromMap(Map<String, dynamic> map) {
    return LifeEvent(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String,
      mood: map['mood'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      photoPath: map['photo_path'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      phaseId: map['phase_id'] as int?,
    );
  }

  LifeEvent copyWith({
    int? id,
    String? title,
    String? content,
    int? mood,
    DateTime? timestamp,
    String? photoPath,
    double? latitude,
    double? longitude,
    int? phaseId,
  }) {
    return LifeEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
      photoPath: photoPath ?? this.photoPath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phaseId: phaseId ?? this.phaseId,
    );
  }
}
