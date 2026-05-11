class LifeEvent {
  final int? id;
  final String title;
  final String content;
  final int mood;
  final DateTime timestamp;
  final String? photoPath;
  final String? videoPath;
  final String? voiceNotePath;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final int? phaseId;

  const LifeEvent({
    this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.timestamp,
    this.photoPath,
    this.videoPath,
    this.voiceNotePath,
    this.latitude,
    this.longitude,
    this.locationName,
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
      'video_path': videoPath,
      'voice_note_path': voiceNotePath,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
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
      videoPath: map['video_path'] as String?,
      voiceNotePath: map['voice_note_path'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['location_name'] as String?,
      phaseId: map['phase_id'] as int?,
    );
  }

  bool get hasText => content.trim().isNotEmpty;
  bool get hasPhoto => (photoPath ?? '').isNotEmpty;
  bool get hasVideo => (videoPath ?? '').isNotEmpty;
  bool get hasVoiceNote => (voiceNotePath ?? '').isNotEmpty;

  LifeEvent copyWith({
    int? id,
    String? title,
    String? content,
    int? mood,
    DateTime? timestamp,
    String? photoPath,
    String? videoPath,
    String? voiceNotePath,
    double? latitude,
    double? longitude,
    String? locationName,
    int? phaseId,
  }) {
    return LifeEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      timestamp: timestamp ?? this.timestamp,
      photoPath: photoPath ?? this.photoPath,
      videoPath: videoPath ?? this.videoPath,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      phaseId: phaseId ?? this.phaseId,
    );
  }
}
