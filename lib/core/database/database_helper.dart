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
    return await openDatabase(path, version: 1, onCreate: _createDatabase);
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
        latitude REAL,
        longitude REAL,
        phase_id INTEGER
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
        description TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_events_timestamp ON life_events (timestamp)');
    await db.execute('CREATE INDEX idx_tags_event_id ON event_tags (event_id)');
  }

  // ── Events ──────────────────────────────────────────────────────────────────

  Future<int> insertEvent(LifeEvent event) async {
    final db = await database;
    return await db.insert('life_events', event.toMap());
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
    return await db.update(
      'life_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int id) async {
    final db = await database;
    await db.delete('event_tags', where: 'event_id = ?', whereArgs: [id]);
    return await db.delete('life_events', where: 'id = ?', whereArgs: [id]);
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

    final db = await database;
    await db.delete('life_phases');

    final detected = PhaseDetector.detectPhases(events);
    for (final phase in detected) {
      await db.insert('life_phases', {
        'name': phase['name'],
        'start_date': phase['start_date'],
        'end_date': phase['end_date'],
        'phase_type': phase['phase_type'],
        'description': phase['description'],
      });
    }
  }

  Future<List<LifePhase>> getPhases() async {
    final db = await database;
    final maps = await db.query('life_phases', orderBy: 'start_date ASC');
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
