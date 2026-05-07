import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_replay/core/models/life_event.dart';
import 'package:life_replay/core/providers/database_provider.dart';

enum TimelineZoom { day, week, month, year }

final timelineZoomProvider = StateProvider<TimelineZoom>((ref) => TimelineZoom.day);

class EventsNotifier extends StateNotifier<AsyncValue<List<LifeEvent>>> {
  EventsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  final Ref _ref;

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final events = await db.getEvents();
      state = AsyncValue.data(events);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addEvent(LifeEvent event, List<String> tags) async {
    try {
      final db = _ref.read(databaseProvider);
      final id = await db.insertEvent(event);
      if (tags.isNotEmpty) {
        await db.setTagsForEvent(id, tags);
      }
      await db.detectAndSavePhases();
      await loadEvents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateEvent(LifeEvent event, List<String> tags) async {
    try {
      final db = _ref.read(databaseProvider);
      await db.updateEvent(event);
      if (event.id != null) {
        await db.setTagsForEvent(event.id!, tags);
      }
      await db.detectAndSavePhases();
      await loadEvents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      final db = _ref.read(databaseProvider);
      await db.deleteEvent(id);
      await db.detectAndSavePhases();
      await loadEvents();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final eventsProvider =
    StateNotifierProvider<EventsNotifier, AsyncValue<List<LifeEvent>>>(
  (ref) => EventsNotifier(ref),
);
