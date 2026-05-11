import 'package:intl/intl.dart';
import 'package:life_replay/core/ingestion/passive_ingestion.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoSourceAdapter implements PassiveSourceAdapter {
  @override
  MemorySourceType get sourceType => MemorySourceType.photo;

  @override
  Future<List<RawMemorySignal>> pullSignals({
    required int limit,
    required Set<String> knownExternalIds,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return const [];

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );
    if (paths.isEmpty) return const [];

    final signals = <RawMemorySignal>[];
    const pageSize = 200;
    var page = 0;

    while (signals.length < limit) {
      final assets = await paths.first.getAssetListPaged(page: page, size: pageSize);
      if (assets.isEmpty) break;
      for (final asset in assets) {
        if (signals.length >= limit) break;
        if (knownExternalIds.contains(asset.id)) continue;

        final file = await asset.file;
        if (file == null) continue;

        final latLng = await asset.latlngAsync();
        final dateLabel = DateFormat('MMM d, yyyy').format(asset.createDateTime);
        signals.add(
          RawMemorySignal(
            sourceType: sourceType,
            externalId: asset.id,
            dedupHash: 'photo:${asset.id}:${asset.createDateTime.millisecondsSinceEpoch}',
            capturedAt: asset.createDateTime,
            textHint: 'Photo memory captured on $dateLabel',
            photoPath: file.path,
            latitude: latLng?.latitude,
            longitude: latLng?.longitude,
            metadata: {
              'filename': file.path.split('/').last,
            },
          ),
        );
      }
      page++;
    }

    return signals;
  }
}

class VideoSourceAdapter implements PassiveSourceAdapter {
  @override
  MemorySourceType get sourceType => MemorySourceType.video;

  @override
  Future<List<RawMemorySignal>> pullSignals({
    required int limit,
    required Set<String> knownExternalIds,
  }) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) return const [];

    final paths = await PhotoManager.getAssetPathList(
      type: RequestType.video,
      onlyAll: true,
    );
    if (paths.isEmpty) return const [];

    final signals = <RawMemorySignal>[];
    const pageSize = 120;
    var page = 0;

    while (signals.length < limit) {
      final assets = await paths.first.getAssetListPaged(page: page, size: pageSize);
      if (assets.isEmpty) break;
      for (final asset in assets) {
        if (signals.length >= limit) break;
        if (knownExternalIds.contains(asset.id)) continue;

        final file = await asset.file;
        if (file == null) continue;

        final latLng = await asset.latlngAsync();
        final dateLabel = DateFormat('MMM d, yyyy').format(asset.createDateTime);
        signals.add(
          RawMemorySignal(
            sourceType: sourceType,
            externalId: asset.id,
            dedupHash: 'video:${asset.id}:${asset.createDateTime.millisecondsSinceEpoch}',
            capturedAt: asset.createDateTime,
            textHint: 'Video memory recorded on $dateLabel',
            videoPath: file.path,
            latitude: latLng?.latitude,
            longitude: latLng?.longitude,
            metadata: {
              'filename': file.path.split('/').last,
            },
          ),
        );
      }
      page++;
    }

    return signals;
  }
}

class NotesSourceAdapter implements PassiveSourceAdapter {
  @override
  MemorySourceType get sourceType => MemorySourceType.note;

  @override
  Future<List<RawMemorySignal>> pullSignals({
    required int limit,
    required Set<String> knownExternalIds,
  }) async {
    // Staged adapter placeholder; passive local notes ingestion is opt-in and platform-specific.
    return const [];
  }
}

class ContactsSourceAdapter implements PassiveSourceAdapter {
  @override
  MemorySourceType get sourceType => MemorySourceType.contact;

  @override
  Future<List<RawMemorySignal>> pullSignals({
    required int limit,
    required Set<String> knownExternalIds,
  }) async {
    // Staged adapter placeholder; contacts APIs differ by platform and permissions.
    return const [];
  }
}

class CallsSourceAdapter implements PassiveSourceAdapter {
  @override
  MemorySourceType get sourceType => MemorySourceType.call;

  @override
  Future<List<RawMemorySignal>> pullSignals({
    required int limit,
    required Set<String> knownExternalIds,
  }) async {
    // Staged adapter placeholder; call log APIs may be unavailable per platform/app-store policy.
    return const [];
  }
}
