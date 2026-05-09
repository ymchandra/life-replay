# AGENTS.md

## Purpose
- This repo is a Flutter mobile app for offline-first life journaling and timeline replay.
- Use this file as the working contract for AI coding agents; prioritize existing patterns over new abstractions.

## Existing AI guidance source
- The required rules glob currently resolves only to `README.md` (no repo-specific agent/rules files yet).

## Architecture map (start here)
- App bootstrap: `lib/main.dart` initializes `DatabaseHelper`, then overrides `databaseProvider` in `ProviderScope`.
- Root app: `lib/app.dart` uses `MaterialApp.router` + `appRouterProvider`.
- Navigation: `lib/core/routing/app_router.dart` uses `ShellRoute` for 5-tab navigation and dedicated routes for `/event/new` and `/event/:id`.
- Data boundary: all persistent data goes through `lib/core/database/database_helper.dart` (sqflite).
- State layer: Riverpod providers in `lib/core/providers/*.dart`; screens consume `AsyncValue` via `.when(...)`.
- Features are vertical slices under `lib/features/<feature>/{screens,widgets}`; reusable UI lives in `lib/shared/widgets`.

## Data flow and cross-component contracts
- Typical write flow: UI (`EventEditorScreen`) -> `eventsProvider` -> `DatabaseHelper`.
- After add/update/delete, `EventsNotifier` always runs `detectAndSavePhases()` and reloads events (`lib/core/providers/events_provider.dart`).
- Phase generation logic is keyword/week-threshold based in `lib/core/utils/phase_detector.dart`; changing thresholds affects `PhasesScreen` output.
- Tags are normalized to lowercase+trimmed in DB writes (`setTagsForEvent`), so keep tag UI/analytics compatible with normalized values.
- Models are simple mappers (`toMap`, `fromMap`, `copyWith`) in `lib/core/models/life_event.dart` and `lib/core/models/life_phase.dart`; preserve DB column names.

## UI and styling conventions
- Theme is centralized in `lib/core/theme/app_theme.dart` (dark warm palette, typography, component themes).
- Prefer existing shared components (`GlassmorphismCard`, `EmptyState`, `MoodIndicator`, `TagChip`, `WarmHeroArt`) before adding new variants.
- Navigation shell UX depends on `AppBottomNav` + `AppShell._locationToIndex`; update both when adding/removing tabs.
- Existing feature screens use subtle motion (`animations`, `flutter_animate`) and low-friction empty states.

## Developer workflow (project-specific)
- Install deps: `flutter pub get`
- Static checks: `flutter analyze` (rules from `analysis_options.yaml` -> `flutter_lints`).
- Unit tests: `flutter test` (current tests focus on `test/core/models` and `test/core/utils`).
- Build app: `flutter run` (or `flutter build apk --debug` for Android artifact testing).
- In this environment, `flutter` is not on PATH; verify toolchain availability before assuming commands will run.

## Change guidance for agents
- Keep provider/database contracts stable; many screens directly depend on current method signatures.
- For new data features, implement in this order: DB method -> provider exposure -> screen/widget usage -> unit tests.
- If you change date grouping or phase logic, update `test/core/utils/date_utils_test.dart` and `test/core/utils/phase_detector_test.dart`.
- Preserve feature-first file organization and snake_case filenames; follow existing import style (`package:life_replay/...`).

