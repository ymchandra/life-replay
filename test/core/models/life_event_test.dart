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
    });

    test('copyWith preserves all fields when nothing overridden', () {
      final copy = event.copyWith();
      expect(copy.title, event.title);
      expect(copy.mood, event.mood);
      expect(copy.photoPath, event.photoPath);
    });
  });
}
