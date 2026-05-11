import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/models/life_event.dart';

void main() {
  final timestamp = DateTime(2024, 6, 15, 10, 30);

  final event = LifeEvent(
    id: 1,
    title: 'Test Event',
    content: 'Some content',
    mood: 4,
    timestamp: timestamp,
    photoPath: '/photos/img.jpg',
    videoPath: '/videos/clip.mp4',
    voiceNotePath: '/audio/note.m4a',
    latitude: 37.7749,
    longitude: -122.4194,
    phaseId: 2,
    sourceType: 'photo',
    sourceExternalId: 'asset-123',
    sourceHash: 'hash-123',
    sourceConfidence: 0.78,
    importedAt: DateTime(2024, 6, 15, 11, 00),
    syncState: 'synced',
  );

  group('LifeEvent', () {
    test('toMap returns correct map', () {
      final map = event.toMap();
      expect(map['id'], 1);
      expect(map['title'], 'Test Event');
      expect(map['content'], 'Some content');
      expect(map['mood'], 4);
      expect(map['timestamp'], timestamp.millisecondsSinceEpoch);
      expect(map['photo_path'], '/photos/img.jpg');
      expect(map['video_path'], '/videos/clip.mp4');
      expect(map['voice_note_path'], '/audio/note.m4a');
      expect(map['latitude'], 37.7749);
      expect(map['longitude'], -122.4194);
      expect(map['phase_id'], 2);
      expect(map['source_type'], 'photo');
      expect(map['source_external_id'], 'asset-123');
      expect(map['source_hash'], 'hash-123');
      expect(map['source_confidence'], 0.78);
      expect(
        map['imported_at'],
        DateTime(2024, 6, 15, 11, 00).millisecondsSinceEpoch,
      );
      expect(map['sync_state'], 'synced');
    });

    test('toMap omits id when null', () {
      final noId = LifeEvent(
        title: 'No ID',
        content: '',
        mood: 3,
        timestamp: timestamp,
      );
      expect(noId.toMap().containsKey('id'), isFalse);
    });

    test('fromMap reconstructs LifeEvent', () {
      final map = event.toMap();
      final restored = LifeEvent.fromMap(map);
      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.content, event.content);
      expect(restored.mood, event.mood);
      expect(restored.timestamp, event.timestamp);
      expect(restored.photoPath, event.photoPath);
      expect(restored.videoPath, event.videoPath);
      expect(restored.voiceNotePath, event.voiceNotePath);
      expect(restored.latitude, event.latitude);
      expect(restored.longitude, event.longitude);
      expect(restored.phaseId, event.phaseId);
      expect(restored.sourceType, event.sourceType);
      expect(restored.sourceExternalId, event.sourceExternalId);
      expect(restored.sourceHash, event.sourceHash);
      expect(restored.sourceConfidence, event.sourceConfidence);
      expect(restored.importedAt, event.importedAt);
      expect(restored.syncState, event.syncState);
    });

    test('copyWith overrides specified fields', () {
      final copy = event.copyWith(title: 'Updated', mood: 5);
      expect(copy.title, 'Updated');
      expect(copy.mood, 5);
      expect(copy.id, event.id);
      expect(copy.content, event.content);
      expect(copy.timestamp, event.timestamp);
      expect(copy.videoPath, event.videoPath);
      expect(copy.voiceNotePath, event.voiceNotePath);
      expect(copy.sourceType, event.sourceType);
    });

    test('copyWith preserves all fields when nothing overridden', () {
      final copy = event.copyWith();
      expect(copy.title, event.title);
      expect(copy.mood, event.mood);
      expect(copy.photoPath, event.photoPath);
    });

    test('fromMap applies defaults for missing source fields', () {
      final restored = LifeEvent.fromMap({
        'id': 9,
        'title': 'Legacy',
        'content': 'old',
        'mood': 3,
        'timestamp': timestamp.millisecondsSinceEpoch,
      });

      expect(restored.sourceType, 'manual');
      expect(restored.sourceConfidence, 1.0);
      expect(restored.syncState, 'manual');
      expect(restored.importedAt, isNull);
    });

    test('fromMap applies defaults for blank source fields', () {
      final restored = LifeEvent.fromMap({
        'id': 7,
        'title': 'Legacy blank',
        'content': 'old',
        'mood': 2,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'source_type': '   ',
        'sync_state': '',
        'source_confidence': null,
      });

      expect(restored.sourceType, 'manual');
      expect(restored.syncState, 'manual');
      expect(restored.sourceConfidence, 1.0);
    });
  });
}
