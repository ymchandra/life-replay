import 'package:intl/intl.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryMemorySyncService {
  static const _seenAssetIdsKey = 'gallery_memory_seen_asset_ids_v1';

  /// Scans device photos and auto-creates one memory per photo for new assets.
  ///
  /// Returns number of memories imported during this sync pass.
  static Future<int> syncFromDevicePhotos(
    DatabaseHelper db, {
    int maxImportsPerRun = 600,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return 0;

    final prefs = await SharedPreferences.getInstance();
    final seenIds = (prefs.getStringList(_seenAssetIdsKey) ?? <String>[]).toSet();

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return 0;

    final allPhotos = paths.first;
    final totalAssets = await allPhotos.assetCountAsync;
    if (totalAssets <= 0) return 0;

    var imported = 0;
    const pageSize = 200;
    var page = 0;

    while (imported < maxImportsPerRun) {
      final assets = await allPhotos.getAssetListPaged(page: page, size: pageSize);
      if (assets.isEmpty) break;

      for (final asset in assets) {
        if (imported >= maxImportsPerRun) break;
        if (seenIds.contains(asset.id)) continue;

        final file = await asset.file;
        if (file == null) {
          seenIds.add(asset.id);
          continue;
        }

        final capturedAt = asset.createDateTime;
        final dateLabel = DateFormat('MMM d, yyyy').format(capturedAt);
        final timeLabel = DateFormat('h:mm a').format(capturedAt);
        final title = 'Photo memory · $dateLabel';
        final content = 'Imported from device gallery ($timeLabel).';
        final latLng = await asset.latlngAsync();

        final id = await db.insertEvent(
          LifeEvent(
            title: title,
            content: content,
            mood: 4,
            timestamp: capturedAt,
            photoPath: file.path,
            latitude: latLng?.latitude,
            longitude: latLng?.longitude,
            locationName: null,
          ),
        );

        await db.setTagsForEvent(id, const ['photo', 'gallery', 'memory', 'auto']);
        imported++;
        seenIds.add(asset.id);
      }

      page++;
    }

    if (imported > 0) {
      await db.detectAndSavePhases();
    }

    // Keep bounded storage for seen IDs.
    final bounded = seenIds.take(20000).toList(growable: false);
    await prefs.setStringList(_seenAssetIdsKey, bounded);

    return imported;
  }
}

