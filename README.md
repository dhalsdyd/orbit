# Orbit

Orbit is a Flutter-based personal universe archive for relationships. It keeps
contact nudges gentle for distant relationships, while turning gifts, places,
photos, and shared moments into satellites, constellations, and nebulae around
the people who matter.

## Proposed Flutter Architecture

The project is split by responsibility first, then by feature inside each layer:

```text
lib/
  main.dart
  domain/
    entities/              # Pure Dart relationship, orbit, and memory models
    repositories/          # Repository contracts when use cases grow
    use_cases/             # Contact completion, mood logging, nudge rules
  data/
    models/                # Hive/Isar persistence DTOs
    repositories/          # Local repository implementations and seed data
    services/              # OpenAI/on-device prompt clients
  presentation/
    orbit/                 # Orbit canvas, archive zoom, gestures, haptics
    contact_log/           # Mood and timeline management UI
    theme/                 # Silent-space visual system
```

Recommended next additions:

- Add Riverpod providers around `OrbitContactRepository`.
- Add Hive or Isar adapters under `data/models`.
- Keep `domain` free of Flutter imports so cadence, memory, and nudge logic can
  be tested without widgets.
- Place radial menu gesture/haptic orchestration in `presentation/orbit`, with
  platform-specific haptic tuning behind a small service interface.

## Product Direction

Orbit's primary value is not "mark that I contacted someone." The product should
feel like an archive of a relationship's history:

- inner-orbit people stay bright and focus on memory capture, not reminders
- outer-orbit people can still receive gentle nudges and icebreakers
- gifts become satellites around a planet
- shared places and meaningful moments become constellations or nebulae
- timeline views exist as a utility layer, while the main browsing experience is
  direct space exploration

## Current Implementation

This initial version includes a `CustomPaint` Orbit Canvas and the first
personal archive interaction model:

- black/deep-navy silent-space background
- central glowing sun representing "me"
- three seeded relationship planets with different radii and orbital speeds
- faint elliptical orbit lines
- ribbon-style trails whose color, thickness, and instability react to mood
- tap a planet to zoom into that person's memory universe
- gifts render as orbiting satellites
- meals, cafes, trips, and hobbies render as constellation nodes and nebulae
- tap satellites or constellation nodes to open glass-style memory cards
- "Past orbit trail" opens a timeline-style utility view for fast scanning
- one-tap memory category chips sketch the future frictionless input surface

## Brand Assets

Generated launch and store artwork is checked in under `assets/branding/`:

- `orbit_app_icon.png` - 1024x1024 launch icon source
- `orbit_play_store_feature.png` - 1024x500 Play Store feature graphic

Run on a machine with Flutter installed. If platform directories are not present
yet, generate them first:

```bash
flutter create .
flutter pub get
flutter run
```