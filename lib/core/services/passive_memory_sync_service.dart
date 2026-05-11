import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/ingestion/memory_normalizer.dart';
import 'package:life_replay/core/ingestion/passive_ingestion.dart';
import 'package:life_replay/core/ingestion/passive_source_adapters.dart';

class PassiveMemorySyncService {
  static List<PassiveSourceAdapter> _adapters() {
    return [
      PhotoSourceAdapter(),
      VideoSourceAdapter(),
      NotesSourceAdapter(),
      ContactsSourceAdapter(),
      CallsSourceAdapter(),
    ];
  }

  static Future<PassiveIngestionSummary> syncAllSources(
    DatabaseHelper db, {
    int maxImportsPerRun = 600,
  }) async {
    var imported = 0;
    var merged = 0;
    var pendingReview = 0;
    final importedBySource = <MemorySourceType, int>{};
    var remaining = maxImportsPerRun;

    for (final adapter in _adapters()) {
      if (remaining <= 0) break;
      final enabled = await PassiveIngestionSettings.isEnabled(adapter.sourceType);
      if (!enabled) continue;

      final seenIds = await PassiveIngestionSettings.getSeenIds(adapter.sourceType);
      final signals = await adapter.pullSignals(
        limit: remaining,
        knownExternalIds: seenIds,
      );
      if (signals.isEmpty) {
        continue;
      }

      for (final signal in signals) {
        final candidate = MemoryNormalizer.normalize(signal);
        final result = await db.upsertIngestedEvent(candidate.event, tags: candidate.tags);
        seenIds.add(signal.externalId);

        if (result.inserted) {
          imported++;
          importedBySource[adapter.sourceType] =
              (importedBySource[adapter.sourceType] ?? 0) + 1;
        } else if (result.merged) {
          merged++;
        }
        if (candidate.needsReview) {
          pendingReview++;
        }
      }

      remaining = maxImportsPerRun - (imported + merged);
      await PassiveIngestionSettings.setSeenIds(adapter.sourceType, seenIds);
    }

    if (imported > 0 || merged > 0) {
      await db.detectAndSavePhases();
    }

    return PassiveIngestionSummary(
      imported: imported,
      merged: merged,
      pendingReview: pendingReview,
      importedBySource: importedBySource,
    );
  }

  static Future<Map<MemorySourceType, bool>> getEnabledSources() {
    return PassiveIngestionSettings.getAllEnabledStates();
  }

  static Future<void> setSourceEnabled(
    MemorySourceType source,
    bool enabled,
  ) {
    return PassiveIngestionSettings.setEnabled(source, enabled);
  }
}
