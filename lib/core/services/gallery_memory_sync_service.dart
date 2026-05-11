import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/services/passive_memory_sync_service.dart';

class GalleryMemorySyncService {
  /// Legacy wrapper maintained for compatibility.
  /// Returns only newly imported count from passive source sync.
  static Future<int> syncFromDevicePhotos(
    DatabaseHelper db, {
    int maxImportsPerRun = 600,
  }) async {
    final summary = await PassiveMemorySyncService.syncAllSources(
      db,
      maxImportsPerRun: maxImportsPerRun,
    );
    return summary.imported;
  }
}
