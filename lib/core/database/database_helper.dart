import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/models/life_phase.dart';
import 'package:life_replay/core/utils/phase_detector.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'life_replay.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE life_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        mood INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        photo_path TEXT,
        video_path TEXT,
        voice_note_path TEXT,
        latitude REAL,
        longitude REAL,
        location_name TEXT,
        phase_id INTEGER,
        source_type TEXT DEFAULT 'manual',
        source_external_id TEXT,
        source_hash TEXT,
        source_confidence REAL DEFAULT 1.0,
        imported_at INTEGER,
        sync_state TEXT DEFAULT 'manual'
      )
    ''');

    await db.execute('''
      CREATE TABLE event_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        tag TEXT NOT NULL,
        FOREIGN KEY (event_id) REFERENCES life_events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE life_phases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER NOT NULL,
        phase_type TEXT NOT NULL,
        description TEXT NOT NULL,
        avg_mood REAL DEFAULT 3.0,
        event_count INTEGER DEFAULT 0,
        top_tags TEXT DEFAULT ''
      )
    ''');

    await db.execute('''
      CREATE TABLE event_sources (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_id INTEGER NOT NULL,
        source_type TEXT NOT NULL,
        external_id TEXT,
        source_hash TEXT,
        confidence REAL DEFAULT 1.0,
        imported_at INTEGER,
        sync_state TEXT DEFAULT 'synced',
        metadata_json TEXT DEFAULT '',
        FOREIGN KEY (event_id) REFERENCES life_events (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_events_timestamp ON life_events (timestamp)');
    await db.execute('CREATE INDEX idx_events_source_external ON life_events (source_type, source_external_id)');
    await db.execute('CREATE INDEX idx_events_source_hash ON life_events (source_hash)');
    await db.execute('CREATE INDEX idx_tags_event_id ON event_tags (event_id)');
    await db.execute('CREATE INDEX idx_event_sources_event_id ON event_sources (event_id)');
    await db.execute('CREATE INDEX idx_event_sources_external ON event_sources (source_type, external_id)');
    await db.execute('CREATE INDEX idx_event_sources_hash ON event_sources (source_hash)');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE life_events ADD COLUMN location_name TEXT');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE life_phases ADD COLUMN avg_mood REAL DEFAULT 3.0");
      await db.execute("ALTER TABLE life_phases ADD COLUMN event_count INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE life_phases ADD COLUMN top_tags TEXT DEFAULT ''");
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE life_events ADD COLUMN video_path TEXT');
      await db.execute('ALTER TABLE life_events ADD COLUMN voice_note_path TEXT');
    }
    if (oldVersion < 5) {
      await db.execute("ALTER TABLE life_events ADD COLUMN source_type TEXT DEFAULT 'manual'");
      await db.execute('ALTER TABLE life_events ADD COLUMN source_external_id TEXT');
      await db.execute('ALTER TABLE life_events ADD COLUMN source_hash TEXT');
      await db.execute('ALTER TABLE life_events ADD COLUMN source_confidence REAL DEFAULT 1.0');
      await db.execute('ALTER TABLE life_events ADD COLUMN imported_at INTEGER');
      await db.execute("ALTER TABLE life_events ADD COLUMN sync_state TEXT DEFAULT 'manual'");

      await db.execute('''
        CREATE TABLE IF NOT EXISTS event_sources (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          source_type TEXT NOT NULL,
          external_id TEXT,
          source_hash TEXT,
          confidence REAL DEFAULT 1.0,
          imported_at INTEGER,
          sync_state TEXT DEFAULT 'synced',
          metadata_json TEXT DEFAULT '',
          FOREIGN KEY (event_id) REFERENCES life_events (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        "INSERT INTO event_sources(event_id, source_type, external_id, source_hash, confidence, imported_at, sync_state) "
        "SELECT id, COALESCE(source_type, 'manual'), source_external_id, source_hash, COALESCE(source_confidence, 1.0), imported_at, COALESCE(sync_state, 'manual') "
        "FROM life_events",
      );
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_source_external ON life_events (source_type, source_external_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_events_source_hash ON life_events (source_hash)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_event_sources_event_id ON event_sources (event_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_event_sources_external ON event_sources (source_type, external_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_event_sources_hash ON event_sources (source_hash)');
    }
  }

  Future<void> seedSampleDataIfEmpty() async {
    final db = await database;
    final existing = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM life_events'),
    );
    if ((existing ?? 0) > 0) return;

    final now = DateTime.now();
    final seeds = <({LifeEvent event, List<String> tags})>[
      (
        event: LifeEvent(
          title: 'Morning sprint planning',
          content:
              'Aligned priorities for this week and set clear delivery goals with the team.',
          mood: 4,
          timestamp: now.subtract(const Duration(days: 9, hours: 2)),
        ),
        tags: ['work', 'planning', 'team']
      ),
      (
        event: LifeEvent(
          title: 'Evening walk in the park',
          content:
              'Slow walk after work. Felt calm and reset after a busy day.',
          mood: 5,
          timestamp: now.subtract(const Duration(days: 8, hours: 6)),
        ),
        tags: ['health', 'recovery']
      ),
      (
        event: LifeEvent(
          title: 'Deep focus coding session',
          content:
              'Implemented a tricky feature and wrote tests. Good progress, but a little tired.',
          mood: 4,
          timestamp: now.subtract(const Duration(days: 6, hours: 4)),
        ),
        tags: ['work', 'build', 'focus']
      ),
      (
        event: LifeEvent(
          title: 'Coffee with a close friend',
          content:
              'Great conversation about goals and travel plans. Felt energised afterwards.',
          mood: 5,
          timestamp: now.subtract(const Duration(days: 4, hours: 3)),
        ),
        tags: ['social', 'friend']
      ),
      (
        event: LifeEvent(
          title: 'Unexpected production issue',
          content:
              'Spent late hours fixing a regression. Stressful, but finally resolved.',
          mood: 2,
          timestamp: now.subtract(const Duration(days: 2, hours: 8)),
        ),
        tags: ['work', 'incident']
      ),
      (
        event: LifeEvent(
          title: 'Quiet reflection before bed',
          content:
              'Wrote a journal note and planned a slower day tomorrow. Feeling balanced.',
          mood: 4,
          timestamp: now.subtract(const Duration(days: 1, hours: 1)),
        ),
        tags: ['journal', 'recovery']
      ),
    ];

    for (final seed in seeds) {
      final id = await insertEvent(seed.event);
      await setTagsForEvent(id, seed.tags);
    }
    await detectAndSavePhases();
  }

  // ── Events ──────────────────────────────────────────────────────────────────

  Future<int> insertEvent(LifeEvent event) async {
    final db = await database;
    final id = await db.insert('life_events', event.toMap());
    await _upsertEventSourceLink(id, event);
    return id;
  }

  Future<List<LifeEvent>> getEvents({int? limit, int? offset}) async {
    final db = await database;
    final maps = await db.query(
      'life_events',
      orderBy: 'timestamp DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map(LifeEvent.fromMap).toList();
  }

  Future<LifeEvent?> getEventById(int id) async {
    final db = await database;
    final maps = await db.query('life_events', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return LifeEvent.fromMap(maps.first);
  }

  Future<int> updateEvent(LifeEvent event) async {
    final db = await database;
    final updated = await db.update(
      'life_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
    if ((event.id ?? 0) > 0) {
      await _upsertEventSourceLink(event.id!, event);
    }
    return updated;
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    await db.delete('event_sources', where: 'event_id = ?', whereArgs: [id]);
    await db.delete('event_tags', where: 'event_id = ?', whereArgs: [id]);
    return await db.delete('life_events', where: 'id = ?', whereArgs: [id]);
  }

  Future<({int eventId, bool inserted, bool merged})> upsertIngestedEvent(
    LifeEvent event, {
    List<String> tags = const [],
  }) async {
    final existingId = await _findEventIdForIngested(event);
    if (existingId == null) {
      final id = await insertEvent(event);
      if (tags.isNotEmpty) {
        await setTagsForEvent(id, tags);
      }
      return (eventId: id, inserted: true, merged: false);
    }

    final existing = await getEventById(existingId);
    if (existing == null) {
      final id = await insertEvent(event);
      if (tags.isNotEmpty) {
        await setTagsForEvent(id, tags);
      }
      return (eventId: id, inserted: true, merged: false);
    }

    final mergedEvent = _mergeEventWithIngested(existing, event);
    final changed = _isMeaningfullyDifferent(existing, mergedEvent);
    if (changed) {
      await updateEvent(mergedEvent);
    }
    if (tags.isNotEmpty) {
      final existingTags = await getTagsForEvent(existingId);
      final mergedTags = <String>{
        ...existingTags.map((t) => t.trim().toLowerCase()),
        ...tags.map((t) => t.trim().toLowerCase()),
      }.where((tag) => tag.isNotEmpty).toList();
      await setTagsForEvent(existingId, mergedTags);
    }
    await _upsertEventSourceLink(existingId, event);
    return (eventId: existingId, inserted: false, merged: changed);
  }

  Future<int?> _findEventIdForIngested(LifeEvent event) async {
    final db = await database;
    if ((event.sourceExternalId ?? '').isNotEmpty) {
      final rows = await db.query(
        'event_sources',
        columns: ['event_id'],
        where: 'source_type = ? AND external_id = ?',
        whereArgs: [event.sourceType, event.sourceExternalId],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows.first['event_id'] as int?;
    }

    if ((event.sourceHash ?? '').isNotEmpty) {
      final rows = await db.query(
        'event_sources',
        columns: ['event_id'],
        where: 'source_hash = ?',
        whereArgs: [event.sourceHash],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows.first['event_id'] as int?;
    }

    return null;
  }

  Future<void> _upsertEventSourceLink(int eventId, LifeEvent event) async {
    final db = await database;
    final externalId = (event.sourceExternalId ?? '').trim();
    final sourceHash = (event.sourceHash ?? '').trim();
    List<Map<String, Object?>> existing;
    if (externalId.isNotEmpty) {
      existing = await db.query(
        'event_sources',
        columns: ['id'],
        where: 'source_type = ? AND external_id = ?',
        whereArgs: [event.sourceType, externalId],
        limit: 1,
      );
    } else if (sourceHash.isNotEmpty) {
      existing = await db.query(
        'event_sources',
        columns: ['id'],
        where: 'source_hash = ?',
        whereArgs: [sourceHash],
        limit: 1,
      );
    } else {
      existing = await db.query(
        'event_sources',
        columns: ['id'],
        where: 'event_id = ? AND source_type = ?',
        whereArgs: [eventId, event.sourceType],
        limit: 1,
      );
    }
    final values = <String, Object?>{
      'event_id': eventId,
      'source_type': event.sourceType,
      'external_id': externalId.isEmpty ? null : externalId,
      'source_hash': sourceHash.isEmpty ? null : sourceHash,
      'confidence': event.sourceConfidence,
      'imported_at': event.importedAt?.millisecondsSinceEpoch,
      'sync_state': event.syncState,
      'metadata_json': '',
    };

    if (existing.isEmpty) {
      await db.insert('event_sources', values);
      return;
    }

    final id = existing.first['id'] as int?;
    if (id != null) {
      await db.update('event_sources', values, where: 'id = ?', whereArgs: [id]);
    }
  }

  LifeEvent _mergeEventWithIngested(LifeEvent existing, LifeEvent incoming) {
    final existingTitle = existing.title.trim();
    final preferIncomingTitle =
        existingTitle.isEmpty || existingTitle.toLowerCase() == 'memory';
    final hasManualContent = existing.sourceType == 'manual' && existing.content.trim().isNotEmpty;
    final mergedSyncState = existing.syncState == 'manual'
        ? 'manual'
        : (existing.syncState == 'pending_review' || incoming.syncState == 'pending_review')
            ? 'pending_review'
            : 'synced';

    return existing.copyWith(
      title: preferIncomingTitle ? incoming.title : existing.title,
      content: hasManualContent
          ? existing.content
          : _firstNonEmpty(existing.content, incoming.content),
      mood: incoming.sourceConfidence >= existing.sourceConfidence
          ? incoming.mood
          : existing.mood,
      photoPath: _firstNonEmpty(existing.photoPath, incoming.photoPath),
      videoPath: _firstNonEmpty(existing.videoPath, incoming.videoPath),
      voiceNotePath: _firstNonEmpty(existing.voiceNotePath, incoming.voiceNotePath),
      latitude: existing.latitude ?? incoming.latitude,
      longitude: existing.longitude ?? incoming.longitude,
      locationName: _firstNonEmpty(existing.locationName, incoming.locationName),
      sourceType: existing.sourceType == 'manual' ? existing.sourceType : incoming.sourceType,
      sourceExternalId: _firstNonEmpty(existing.sourceExternalId, incoming.sourceExternalId),
      sourceHash: _firstNonEmpty(existing.sourceHash, incoming.sourceHash),
      sourceConfidence: incoming.sourceConfidence > existing.sourceConfidence
          ? incoming.sourceConfidence
          : existing.sourceConfidence,
      importedAt: existing.importedAt ?? incoming.importedAt,
      syncState: mergedSyncState,
    );
  }

  bool _isMeaningfullyDifferent(LifeEvent a, LifeEvent b) {
    return a.title != b.title ||
        a.content != b.content ||
        a.mood != b.mood ||
        a.photoPath != b.photoPath ||
        a.videoPath != b.videoPath ||
        a.voiceNotePath != b.voiceNotePath ||
        a.latitude != b.latitude ||
        a.longitude != b.longitude ||
        a.locationName != b.locationName ||
        a.sourceType != b.sourceType ||
        a.sourceExternalId != b.sourceExternalId ||
        a.sourceHash != b.sourceHash ||
        a.sourceConfidence != b.sourceConfidence ||
        a.importedAt != b.importedAt ||
        a.syncState != b.syncState;
  }

  String? _firstNonEmpty(String? first, String? second) {
    final a = first?.trim() ?? '';
    if (a.isNotEmpty) return first;
    final b = second?.trim() ?? '';
    if (b.isNotEmpty) return second;
    return first ?? second;
  }

  Future<List<LifeEvent>> getEventsByDateRange(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'life_events',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'timestamp ASC',
    );
    return maps.map(LifeEvent.fromMap).toList();
  }

  /// Returns events for the same month-day across all years (On This Day).
  Future<List<LifeEvent>> getEventsForDayAcrossYears(int month, int day) async {
    final db = await database;
    final allMaps = await db.query('life_events', orderBy: 'timestamp DESC');
    final all = allMaps.map(LifeEvent.fromMap).toList();
    return all.where((e) => e.timestamp.month == month && e.timestamp.day == day).toList();
  }

  // ── Tags ─────────────────────────────────────────────────────────────────────

  Future<void> setTagsForEvent(int eventId, List<String> tags) async {
    final db = await database;
    await db.delete('event_tags', where: 'event_id = ?', whereArgs: [eventId]);
    for (final tag in tags) {
      await db.insert('event_tags', {'event_id': eventId, 'tag': tag.trim().toLowerCase()});
    }
  }

  Future<List<String>> getTagsForEvent(int eventId) async {
    final db = await database;
    final maps = await db.query('event_tags', where: 'event_id = ?', whereArgs: [eventId]);
    return maps.map((m) => m['tag'] as String).toList();
  }

  Future<Map<int, List<String>>> getTagsForEvents(List<int> eventIds) async {
    if (eventIds.isEmpty) return const {};
    final db = await database;
    final placeholders = List.filled(eventIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT event_id, tag FROM event_tags WHERE event_id IN ($placeholders) ORDER BY event_id ASC',
      eventIds,
    );

    final tagsByEventId = <int, List<String>>{};
    for (final row in rows) {
      final eventId = row['event_id'] as int?;
      final tag = row['tag'] as String?;
      if (eventId == null || tag == null) continue;
      tagsByEventId.putIfAbsent(eventId, () => <String>[]).add(tag);
    }
    return tagsByEventId;
  }

  Future<Map<int, List<String>>> getSourceTypesForEvents(List<int> eventIds) async {
    if (eventIds.isEmpty) return const {};
    final db = await database;
    final placeholders = List.filled(eventIds.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT event_id, source_type FROM event_sources WHERE event_id IN ($placeholders) ORDER BY event_id ASC',
      eventIds,
    );
    final byEvent = <int, List<String>>{};
    for (final row in rows) {
      final eventId = row['event_id'] as int?;
      final sourceType = row['source_type'] as String?;
      if (eventId == null || sourceType == null || sourceType.trim().isEmpty) continue;
      final bucket = byEvent.putIfAbsent(eventId, () => <String>[]);
      if (!bucket.contains(sourceType)) {
        bucket.add(sourceType);
      }
    }
    return byEvent;
  }

  Future<Map<String, int>> getTopTags(int limit) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT tag, COUNT(*) as count
      FROM event_tags
      GROUP BY tag
      ORDER BY count DESC
      LIMIT ?
    ''', [limit]);
    return {for (final row in result) row['tag'] as String: row['count'] as int};
  }

  Future<List<String>> getAllTags() async {
    final db = await database;
    final result = await db.rawQuery('SELECT DISTINCT tag FROM event_tags ORDER BY tag ASC');
    return result.map((r) => r['tag'] as String).toList();
  }

  // ── Phases ───────────────────────────────────────────────────────────────────

  Future<void> detectAndSavePhases() async {
    final events = await getEvents();
    if (events.isEmpty) return;

    // Load all tags so the detector can use them for smarter classification
    final tagsByEventId = <int, List<String>>{};
    for (final event in events) {
      if (event.id != null) {
        tagsByEventId[event.id!] = await getTagsForEvent(event.id!);
      }
    }

    final db = await database;
    await db.delete('life_phases');

    final detected = PhaseDetector.detectPhases(
      events,
      tagsByEventId: tagsByEventId,
    );
    for (final phase in detected) {
      await db.insert('life_phases', {
        'name': phase['name'],
        'start_date': phase['start_date'],
        'end_date': phase['end_date'],
        'phase_type': phase['phase_type'],
        'description': phase['description'],
        'avg_mood': phase['avg_mood'] ?? 3.0,
        'event_count': phase['event_count'] ?? 0,
        'top_tags': phase['top_tags'] ?? '',
      });
    }
  }

  Future<List<LifePhase>> getPhases() async {
    final db = await database;
    // Newest first
    final maps = await db.query('life_phases', orderBy: 'start_date DESC');
    return maps.map(LifePhase.fromMap).toList();
  }

  // ── Analytics ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMoodTrend(int days) async {
    final db = await database;
    final since = DateTime.now().subtract(Duration(days: days)).millisecondsSinceEpoch;
    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m-%d', timestamp / 1000, 'unixepoch') as date,
        AVG(mood) as avg_mood
      FROM life_events
      WHERE timestamp >= ?
      GROUP BY date
      ORDER BY date ASC
    ''', [since]);
    return result.cast<Map<String, dynamic>>();
  }

  Future<Map<DateTime, int>> getActivityHeatmap() async {
    final db = await database;
    final since = DateTime.now().subtract(const Duration(days: 364)).millisecondsSinceEpoch;
    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m-%d', timestamp / 1000, 'unixepoch') as date,
        COUNT(*) as count
      FROM life_events
      WHERE timestamp >= ?
      GROUP BY date
    ''', [since]);

    final map = <DateTime, int>{};
    for (final row in result) {
      try {
        final d = DateTime.parse(row['date'] as String);
        map[DateTime(d.year, d.month, d.day)] = (row['count'] as int?) ?? 0;
      } catch (_) {}
    }
    return map;
  }

  Future<Map<String, int>> getTimeOfDayDistribution() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        CAST(strftime('%H', timestamp / 1000, 'unixepoch') AS INTEGER) as hour,
        COUNT(*) as count
      FROM life_events
      GROUP BY hour
    ''');

    var morning = 0, afternoon = 0, evening = 0, night = 0;
    for (final row in result) {
      final hour = (row['hour'] as int?) ?? 0;
      final count = (row['count'] as int?) ?? 0;
      if (hour >= 5 && hour < 12) {
        morning += count;
      } else if (hour >= 12 && hour < 17) {
        afternoon += count;
      } else if (hour >= 17 && hour < 21) {
        evening += count;
      } else {
        night += count;
      }
    }
    return {
      'Morning': morning,
      'Afternoon': afternoon,
      'Evening': evening,
      'Night': night,
    };
  }
}
