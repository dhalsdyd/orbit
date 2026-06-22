# Orbit

Orbit is a Flutter-based personal CRM and relationship tracker. It visualizes
each relationship as a planet moving through a quiet, tactile space instead of
presenting contact cadences as urgent tasks.

## Proposed Flutter Architecture

The project is split by responsibility first, then by feature inside each layer:

```text
lib/
  main.dart
  domain/
    entities/              # Pure Dart relationship/orbit models
    repositories/          # Repository contracts when use cases grow
    use_cases/             # Contact completion, mood logging, nudge rules
  data/
    models/                # Hive/Isar persistence DTOs
    repositories/          # Local repository implementations
    services/              # OpenAI/on-device prompt clients
  presentation/
    orbit/                 # Orbit canvas screen, painter, gestures, haptics
    contact_log/           # Mood selection and interaction history UI
    theme/                 # Silent-space visual system
```

Recommended next additions:

- Add Riverpod providers around `OrbitContactRepository`.
- Add Hive or Isar adapters under `data/models`.
- Keep `domain` free of Flutter imports so cadence and nudge logic can be
  tested without widgets.
- Place radial menu gesture/haptic orchestration in `presentation/orbit`, with
  platform-specific haptic tuning behind a small service interface.

## Current Implementation

This initial version includes a basic `CustomPaint` Orbit Canvas:

- black/deep-navy silent-space background
- central glowing sun representing "me"
- three seeded relationship planets with different radii and orbital speeds
- faint elliptical orbit lines
- ribbon-style trails whose color, thickness, and instability react to mood

Run on a machine with Flutter installed. If platform directories are not present
yet, generate them first:

```bash
flutter create .
flutter pub get
flutter run
```