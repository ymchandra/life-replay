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
  final String sourceType;
  final String? sourceExternalId;
  final String? sourceHash;
  final double sourceConfidence;
  final DateTime? importedAt;
  final String syncState;

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
    this.sourceType = 'manual',
    this.sourceExternalId,
    this.sourceHash,
    this.sourceConfidence = 1.0,
    this.importedAt,
    this.syncState = 'manual',
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
      'source_type': sourceType,
      'source_external_id': sourceExternalId,
      'source_hash': sourceHash,
      'source_confidence': sourceConfidence,
      'imported_at': importedAt?.millisecondsSinceEpoch,
      'sync_state': syncState,
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
      sourceType: (map['source_type'] as String?)?.trim().isNotEmpty == true
          ? (map['source_type'] as String)
          : 'manual',
      sourceExternalId: map['source_external_id'] as String?,
      sourceHash: map['source_hash'] as String?,
      sourceConfidence: (map['source_confidence'] as num?)?.toDouble() ?? 1.0,
      importedAt: (map['imported_at'] as int?) != null
          ? DateTime.fromMillisecondsSinceEpoch(map['imported_at'] as int)
          : null,
      syncState: (map['sync_state'] as String?)?.trim().isNotEmpty == true
          ? (map['sync_state'] as String)
          : 'manual',
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
    String? sourceType,
    String? sourceExternalId,
    String? sourceHash,
    double? sourceConfidence,
    DateTime? importedAt,
    String? syncState,
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
      sourceType: sourceType ?? this.sourceType,
      sourceExternalId: sourceExternalId ?? this.sourceExternalId,
      sourceHash: sourceHash ?? this.sourceHash,
      sourceConfidence: sourceConfidence ?? this.sourceConfidence,
      importedAt: importedAt ?? this.importedAt,
      syncState: syncState ?? this.syncState,
    );
  }
}
