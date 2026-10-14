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

The initial screen sketches are in `proposal_assets/`. [Editable five-screen Figma wireframe](https://www.figma.com/design/rXtOvNPFTtUFlgaiAUvmAb)

## Current build

The five-screen navigation is working. The dashboard now has an empty state and a preset list, and the editor validates a preset name and a whole-number duration from 1 to 180 minutes. Saved presets currently remain in memory only; SQLite storage and editing existing presets are the next implementation steps. Run `flutter test` from `app/` to check navigation and preset validation.

