import 'package:intl/intl.dart';
import 'package:life_replay/core/ingestion/passive_ingestion.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/utils/on_device_event_inference.dart';

class NormalizedMemoryCandidate {
  final LifeEvent event;
  final List<String> tags;
  final bool needsReview;

  const NormalizedMemoryCandidate({
    required this.event,
    required this.tags,
    required this.needsReview,
  });
}

class MemoryNormalizer {
  // Confidence below this threshold is treated as low-context and marked for review.
  static const double _reviewThreshold = 0.45;

  static NormalizedMemoryCandidate normalize(RawMemorySignal signal) {
    final metadataHint = signal.metadata.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .join(' ');
    final contextText = [
      signal.textHint ?? '',
      metadataHint,
      signal.locationName ?? '',
      signal.sourceType.key,
    ].join(' ').trim();

    final inferred = OnDeviceEventInference.infer(
      contextText,
      fallbackTitle: _fallbackTitle(signal),
      fallbackMood: 3,
    );

    final confidence = _confidence(signal, contextText: contextText);
    final needsReview = confidence < _reviewThreshold;
    final event = LifeEvent(
      title: inferred.title,
      content: _buildContent(signal),
      mood: inferred.mood,
      timestamp: signal.capturedAt,
      photoPath: signal.photoPath,
      videoPath: signal.videoPath,
      voiceNotePath: signal.voicePath,
      latitude: signal.latitude,
      longitude: signal.longitude,
      locationName: signal.locationName,
      sourceType: signal.sourceType.key,
      sourceExternalId: signal.externalId,
      sourceHash: signal.dedupHash,
      sourceConfidence: confidence,
      importedAt: DateTime.now(),
      syncState: needsReview ? 'pending_review' : 'synced',
    );

    final tags = OnDeviceEventInference.inferTags(
      contextText,
      baseTags: [signal.sourceType.key, 'auto', if (needsReview) 'review'],
    );

    return NormalizedMemoryCandidate(
      event: event,
      tags: tags,
      needsReview: needsReview,
    );
  }

  static double _confidence(
    RawMemorySignal signal, {
    required String contextText,
  }) {
    // Weighted heuristic:
    // - base trust for a structured signal
    // - richer context (text/media/location) increases confidence
    // - score is bounded to [0, 1] and compared with _reviewThreshold
    var score = 0.2;
    if ((signal.textHint ?? '').trim().length >= 12) score += 0.25;
    if ((signal.photoPath ?? '').isNotEmpty || (signal.videoPath ?? '').isNotEmpty) {
      score += 0.2;
    }
    if ((signal.voicePath ?? '').isNotEmpty) score += 0.1;
    if (signal.latitude != null && signal.longitude != null) score += 0.15;
    if ((signal.locationName ?? '').trim().isNotEmpty) score += 0.1;
    if (contextText.trim().length >= 35) score += 0.1;
    if (score > 1.0) return 1.0;
    return score;
  }

  static String _fallbackTitle(RawMemorySignal signal) {
    final dateLabel = DateFormat('MMM d, yyyy').format(signal.capturedAt);
    return '${signal.sourceType.label} memory · $dateLabel';
  }

  static String _buildContent(RawMemorySignal signal) {
    final parts = <String>[
      if ((signal.textHint ?? '').trim().isNotEmpty) signal.textHint!.trim(),
      'Imported from ${signal.sourceType.label.toLowerCase()} source.',
      if (signal.metadata.isNotEmpty)
        'Metadata: ${signal.metadata.entries.map((e) => '${e.key}=${e.value}').join(', ')}.',
    ];
    return parts.join(' ');
  }
}
