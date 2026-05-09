import 'package:flutter_test/flutter_test.dart';
import 'package:life_replay/core/utils/on_device_event_inference.dart';

void main() {
  group('OnDeviceEventInference', () {
    test('uses fallback values when content is empty', () {
      final result = OnDeviceEventInference.infer(
        '   ',
        fallbackTitle: 'Fallback title',
        fallbackMood: 4,
      );

      expect(result.title, 'Fallback title');
      expect(result.mood, 4);
    });

    test('derives title from first sentence', () {
      final result = OnDeviceEventInference.infer(
        'Finished writing the first draft. Then went for a walk.',
      );

      expect(result.title, 'Finished writing the first draft');
    });

    test('caps very long titles', () {
      final result = OnDeviceEventInference.infer(
        'This is a very long memory note that keeps going to make sure the inferred title gets truncated for storage safety',
      );

      expect(result.title.endsWith('...'), isTrue);
      expect(result.title.length, lessThanOrEqualTo(60));
    });

    test('infers higher mood from positive language', () {
      final result = OnDeviceEventInference.infer(
        'Amazing day! I feel grateful, happy, and proud of the progress!',
      );

      expect(result.mood, greaterThanOrEqualTo(4));
    });

    test('infers lower mood from negative language', () {
      final result = OnDeviceEventInference.infer(
        'I feel stressed, overwhelmed, and tired today.',
      );

      expect(result.mood, lessThanOrEqualTo(2));
    });

    test('infers tags from domain keywords and content tokens', () {
      final tags = OnDeviceEventInference.inferTags(
        'Had a project meeting with the client after a long walk in the park.',
      );

      expect(tags, contains('work'));
      expect(tags, contains('health'));
      expect(tags.any((t) => t == 'project' || t == 'meeting' || t == 'client'), isTrue);
    });

    test('normalizes and de-duplicates base tags', () {
      final tags = OnDeviceEventInference.inferTags(
        'Quick journal reflection before sleep.',
        baseTags: const [' Work ', 'work', 'Travel'],
      );

      expect(tags.where((t) => t == 'work').length, 1);
      expect(tags, contains('travel'));
      expect(tags, contains('journal'));
    });

    test('returns base tags when content is empty', () {
      final tags = OnDeviceEventInference.inferTags(
        '   ',
        baseTags: const ['Work', 'focus'],
      );

      expect(tags, equals(['work', 'focus']));
    });
  });
}
