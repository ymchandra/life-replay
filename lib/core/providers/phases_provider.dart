import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_replay/core/models/life_phase.dart';
import 'package:life_replay/core/providers/database_provider.dart';

class PhasesNotifier extends StateNotifier<AsyncValue<List<LifePhase>>> {
  PhasesNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadPhases();
  }

  final Ref _ref;

  Future<void> loadPhases() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      final phases = await db.getPhases();
      state = AsyncValue.data(phases);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final phasesProvider =
    StateNotifierProvider<PhasesNotifier, AsyncValue<List<LifePhase>>>(
  (ref) => PhasesNotifier(ref),
);
