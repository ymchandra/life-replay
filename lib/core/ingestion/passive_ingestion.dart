import 'package:shared_preferences/shared_preferences.dart';

enum MemorySourceType { manual, photo, video, note, contact, call, social }

extension MemorySourceTypeX on MemorySourceType {
  String get key => switch (this) {
        MemorySourceType.manual => 'manual',
        MemorySourceType.photo => 'photo',
        MemorySourceType.video => 'video',
        MemorySourceType.note => 'note',
        MemorySourceType.contact => 'contact',
        MemorySourceType.call => 'call',
        MemorySourceType.social => 'social',
      };

  String get label => switch (this) {
        MemorySourceType.manual => 'Manual',
        MemorySourceType.photo => 'Photos',
        MemorySourceType.video => 'Videos',
        MemorySourceType.note => 'Notes/Text',
        MemorySourceType.contact => 'Contacts',
        MemorySourceType.call => 'Calls',
        MemorySourceType.social => 'Social',
      };

  static MemorySourceType fromKey(String key) {
    return MemorySourceType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => MemorySourceType.manual,
    );
  }
}

class RawMemorySignal {
  final MemorySourceType sourceType;
  final String externalId;
  final String dedupHash;
  final DateTime capturedAt;
  final String? textHint;
  final String? photoPath;
  final String? videoPath;
  final String? voicePath;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final Map<String, String> metadata;

  const RawMemorySignal({
    required this.sourceType,
    required this.externalId,
    required this.dedupHash,
    required this.capturedAt,
    this.textHint,
    this.photoPath,
    this.videoPath,
    this.voicePath,
    this.latitude,
    this.longitude,
    this.locationName,
    this.metadata = const {},
  });
}

abstract class PassiveSourceAdapter {
  MemorySourceType get sourceType;

  Future<List<RawMemorySignal>> pullSignals({
    required int limit,
    required Set<String> knownExternalIds,
  });
}

class PassiveIngestionSettings {
  static const _enabledPrefix = 'passive_source_enabled_v1_';
  static const _seenPrefix = 'passive_source_seen_ids_v1_';
  static const _maxSeenIdsPerSource = 20000;

  static bool defaultEnabled(MemorySourceType source) {
    return switch (source) {
      MemorySourceType.photo || MemorySourceType.video => true,
      _ => false,
    };
  }

  static Future<bool> isEnabled(MemorySourceType source) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_enabledPrefix${source.key}';
    return prefs.getBool(key) ?? defaultEnabled(source);
  }

  static Future<void> setEnabled(MemorySourceType source, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_enabledPrefix${source.key}';
    await prefs.setBool(key, enabled);
  }

  static Future<Map<MemorySourceType, bool>> getAllEnabledStates() async {
    final map = <MemorySourceType, bool>{};
    for (final source in MemorySourceType.values) {
      if (source == MemorySourceType.manual || source == MemorySourceType.social) continue;
      map[source] = await isEnabled(source);
    }
    return map;
  }

  static Future<Set<String>> getSeenIds(MemorySourceType source) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_seenPrefix${source.key}';
    return (prefs.getStringList(key) ?? const <String>[]).toSet();
  }

  static Future<void> setSeenIds(MemorySourceType source, Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_seenPrefix${source.key}';
    final bounded = ids.take(_maxSeenIdsPerSource).toList(growable: false);
    await prefs.setStringList(key, bounded);
  }
}

class PassiveIngestionSummary {
  final int imported;
  final int merged;
  final int pendingReview;
  final Map<MemorySourceType, int> importedBySource;

  const PassiveIngestionSummary({
    required this.imported,
    required this.merged,
    required this.pendingReview,
    required this.importedBySource,
  });

  bool get hasMeaningfulChanges => imported > 0 || merged > 0;
}
