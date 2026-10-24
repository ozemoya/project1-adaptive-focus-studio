# Android device check — October 24, 2026

Tested the debug APK on the Pixel 7 Pro Android emulator (Android 17, x86_64, 16 KB pages).

- Initial launch exposed a native JNI crash from newer Android platform plugins. The Android implementations of `path_provider` and `shared_preferences` are now pinned to channel-based releases; the rebuilt APK launched without that crash.
- Opened the five-tab dashboard and preset editor, created a 25-minute Calm preset named Practice, and saw it on the dashboard.
- Force-stopped and relaunched the app. Practice was still present, confirming this preset survived a process restart. [Restart screenshot](evidence/pixel7pro-saved-plan-after-restart.png).
- `flutter test --no-pub` passed 19 tests; `dart analyze lib test` found no issues. A 320-pixel widget test at 200% text size verified the timer's accessible remaining-time label without overflow.

This is one emulator check. A second device or emulator and a peer usability trial are still needed. No peer observations are recorded yet.
