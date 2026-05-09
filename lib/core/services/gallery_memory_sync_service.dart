import 'package:intl/intl.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GalleryMemorySyncService {
  static const _seenAssetIdsKey = 'gallery_memory_seen_asset_ids_v1';

  /// Scans recent device photos and auto-creates one memory per day for new photos.
  ///
  /// Returns number of memories imported during this sync pass.
  static Future<int> syncFromDevicePhotos(DatabaseHelper db) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return 0;

    final prefs = await SharedPreferences.getInstance();
    final seenIds = (prefs.getStringList(_seenAssetIdsKey) ?? <String>[]).toSet();

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return 0;

    final recentAssets = await paths.first.getAssetListPaged(page: 0, size: 400);
    final freshAssets = recentAssets.where((a) => !seenIds.contains(a.id)).toList();
    if (freshAssets.isEmpty) return 0;

    final grouped = <String, List<AssetEntity>>{};
    for (final asset in freshAssets) {
      final dt = asset.createDateTime;
      final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => <AssetEntity>[]).add(asset);
    }

    var imported = 0;

    for (final entry in grouped.entries) {
      final assetsForDay = entry.value..sort((a, b) => a.createDateTime.compareTo(b.createDateTime));
      final first = assetsForDay.first;
      final firstFile = await first.file;
      if (firstFile == null) continue;

      final firstTime = first.createDateTime;
      final dayStart = DateTime(firstTime.year, firstTime.month, firstTime.day);
      final dayEnd = dayStart.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

      // Avoid duplicates for the same day if an auto-photo memory already exists.
      final existing = await db.getEventsByDateRange(dayStart, dayEnd);
      final marker = '[auto_photo_memory:${entry.key}]';
      final alreadyExists = existing.any((e) => e.content.contains(marker));
      if (alreadyExists) {
        for (final a in assetsForDay) {
          seenIds.add(a.id);
        }
        continue;
      }

      final count = assetsForDay.length;
      final dateLabel = DateFormat('MMM d, yyyy').format(firstTime);
      final title = count == 1
          ? 'Photo memory from $dateLabel'
          : '$count photo memories from $dateLabel';

      final content =
          '$marker\nCaptured $count new photo${count == 1 ? '' : 's'} on your device. Revisit this day in Replay.';

      final latLng = await first.latlngAsync();

      final id = await db.insertEvent(
        LifeEvent(
          title: title,
          content: content,
          mood: 4,
          timestamp: firstTime,
          photoPath: firstFile.path,
          latitude: latLng?.latitude,
          longitude: latLng?.longitude,
          locationName: null,
        ),
      );

      await db.setTagsForEvent(id, const ['photo', 'gallery', 'memory']);
      imported++;

      for (final a in assetsForDay) {
        seenIds.add(a.id);
      }
    }

    if (imported > 0) {
      await db.detectAndSavePhases();
    }

    // Keep bounded storage for seen IDs.
    final bounded = seenIds.take(6000).toList(growable: false);
    await prefs.setStringList(_seenAssetIdsKey, bounded);

    return imported;
  }
}

