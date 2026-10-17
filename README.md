# Adaptive Focus Studio

Adaptive Focus Studio is an offline Flutter app for managing focus sessions. Students can create reusable presets, run and pause a timer, review editable session history, and see a transparent, rule-based duration suggestion.

## Project status

The Project One proposal has been approved. The Word proposal and signed team acknowledgment were submitted through iCollege. Those documents are kept outside this public repository because they contain student IDs and signatures. Development will proceed in small, descriptive commits.

## Planned app

- Five screens: dashboard, preset editor, session activity, history and insights, and settings.
- Local SQLite storage for presets and session logs, with create, read, update, and delete operations for both.
- SharedPreferences for settings and a rule-based session-duration suggestion that the user can override.
- Offline and restart testing, plus accessible interaction and a documented peer-review revision.

## Team

Myles Miller and Eziz Bagshiyev (undergraduate pathway).

The initial screen sketches are in `proposal_assets/`. [Editable five-screen Figma wireframe](https://www.figma.com/design/rXtOvNPFTtUFlgaiAUvmAb) now also includes [light](https://www.figma.com/design/rXtOvNPFTtUFlgaiAUvmAb?node-id=8-2) and [dark](https://www.figma.com/design/rXtOvNPFTtUFlgaiAUvmAb?node-id=8-70) dashboard designs matching the updated app.

## Current build

The five-screen navigation is working. The dashboard has an empty state and a preset list, and the editor validates a preset name and a whole-number duration from 1 to 180 minutes. Presets are saved locally in SQLite and loaded again at startup. Tapping a saved plan opens it for editing; its menu offers a confirmed delete action. The Settings screen saves dark mode, default plan duration, and reduced motion preferences on the device; the default duration fills the next new preset. Run `flutter test` from `app/` to check navigation, validation, settings persistence, and SQLite CRUD. The dashboard and editor have been checked on an Android emulator.

The dashboard now uses a compact lavender focus banner, a seven-day strip, warm plan cards, and a rounded five-destination navigation bar. The header switches between light and dark palettes. The flower artwork is drawn in Flutter; the reference image is not bundled into the app.

