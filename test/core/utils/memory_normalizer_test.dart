import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/ingestion/memory_normalizer.dart';
import 'package:life_replay/core/ingestion/passive_ingestion.dart';

void main() {
  group('MemoryNormalizer', () {
    test('normalizes rich photo signal with synced state', () {
      final candidate = MemoryNormalizer.normalize(
        RawMemorySignal(
          sourceType: MemorySourceType.photo,
          externalId: 'img-1',
          dedupHash: 'hash-1',
          capturedAt: DateTime(2025, 1, 2, 7, 30),
          textHint: 'Morning run by the river',
          photoPath: '/photos/river.jpg',
          latitude: 12.3,
          longitude: 45.6,
          locationName: 'Riverside',
          metadata: const {'filename': 'river.jpg'},
        ),
      );

      expect(candidate.event.sourceType, 'photo');
      expect(candidate.event.sourceExternalId, 'img-1');
      expect(candidate.event.sourceHash, 'hash-1');
      expect(candidate.event.syncState, 'synced');
      expect(candidate.needsReview, isFalse);
      expect(candidate.tags, contains('photo'));
      expect(candidate.tags, contains('auto'));
    });

    test('marks low-context signal as pending review', () {
      final candidate = MemoryNormalizer.normalize(
        RawMemorySignal(
          sourceType: MemorySourceType.note,
          externalId: 'note-1',
          dedupHash: 'hash-note',
          capturedAt: DateTime(2024, 11, 12),
        ),
      );

      expect(candidate.needsReview, isTrue);
      expect(candidate.event.syncState, 'pending_review');
      expect(candidate.tags, contains('review'));
      expect(candidate.event.sourceConfidence, lessThan(0.5));
    });
  });
}
