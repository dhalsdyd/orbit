# orbit

## Cursor Cloud specific instructions

### Repository layout (important)
- The `main` branch currently contains only this `README`/`AGENTS.md`. The actual
  Flutter application lives on the branch **`cursor/orbit-canvas-aa61`** (a
  Flutter/Dart personal-CRM "orbit" app with `pubspec.yaml`, `lib/`, `test/`).
- To work on / run the app without leaving another branch, use a worktree, e.g.
  `git worktree add /tmp/orbit-app origin/cursor/orbit-canvas-aa61`.

### Toolchain (already baked into the VM snapshot)
- Flutter stable SDK is installed at `/opt/flutter` and is on `PATH` via
  `~/.bashrc` (`flutter`, `dart`). Web (Chrome) and Linux desktop targets are
  enabled.
- Linux desktop builds compile C++ via `clang++`, which selects the newest GCC
  toolchain. `libstdc++-14-dev` (plus `ninja-build`, `libgtk-3-dev`,
  `pkg-config`) is installed so `clang++` can find `<string>`/`-lstdc++`.
- Google Chrome is available for web runs.

### Running the app (from the app worktree/branch)
- Platform folders (`linux/`, `web/`, etc.) are **not** committed. Generate them
  once per checkout before running: `flutter create .` then `flutter pub get`.
- Web dev server: `flutter run -d web-server --web-port=8080` (open in Chrome),
  or `flutter run -d chrome`.
- Linux desktop: `DISPLAY=:1 flutter run -d linux` (a GUI desktop runs on
  display `:1`). `libEGL ... DRI3` warnings are harmless (software rendering).
- Lint: `flutter analyze` (the app branch has 4 pre-existing `info`-level
  `unnecessary_underscores` lints in `orbit_canvas_screen.dart`).
- Tests: `flutter test`. Note: running `flutter create .` also drops a default
  `test/widget_test.dart` that references a non-existent `MyApp`; it is untracked
  and should be deleted before `flutter test`/`flutter analyze` (the real test is
  `test/orbit_app_test.dart`).

### Known caveats
- The home orbit scene renders squished into a thin band at the top of the
  window (sun + planets near the top, everything else black). This is a
  pre-existing app-layout bug on `cursor/orbit-canvas-aa61`: the `Scaffold` body
  receives loose height constraints, so the root `Stack` collapses to its header
  and the full-screen `CustomPaint` is only as tall as that header. It is not an
  environment/toolchain problem. (Locally forcing the `Stack` to fill, e.g.
  `StackFit.expand`, makes the scene center correctly and the app fully
  interactive.)
- Core interaction flow when the layout fills correctly: tap a planet to zoom
  into "<Name> Universe", then tap a bottom category chip (e.g. "Cafe") to
  instantly capture a memory (a new glowing node appears and the memory count
  increments).
