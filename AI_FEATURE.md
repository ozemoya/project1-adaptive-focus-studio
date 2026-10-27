# Session Scout local helper

Session Scout suggests a focus-session duration from the student's own completed sessions. It is a transparent local rule, not a trained machine-learning model or a cloud service. The user may apply the suggestion or dismiss it.

The helper reads completed session durations in minutes and the selected preset mood from local SQLite data. It keeps the three most recent sessions with the same mood whose completed durations are within 1–180 minutes. With fewer than three valid matches, it makes no suggestion. Otherwise it takes the median and limits the displayed suggestion to 10–60 minutes. The card explains the three source values and offers Apply and Not now controls. A fixed 25-minute duration is the comparison baseline.

The choice of a median reduces sensitivity to one unusually long or short session. A mean was considered, but an outlier would move it more. A fixed baseline needs no personal history and works when the helper has too little data, but it does not adapt to the student's recent sessions.

The five controlled fixtures in [the evaluation log](docs/session-scout-evaluation.md) cover normal values, insufficient data, invalid values, an outlier and boundary case, and a counterexample. All five passed. The counterexample uses 1, 2, and 3 minutes: the median is 2, but the 10-minute minimum produces a suggestion that may still be too long. A follow-up could lower or let the user adjust that minimum and compare completed-session error against the fixed 25-minute baseline on new sessions. These tests establish rule behavior, not improved productivity or predictive accuracy.

The code runs on device and reads no remote service. SQLite and SharedPreferences are the runtime storage. Offline/restart checks on Android emulators are documented in [the device check](docs/device-check-2026-10-24.md); the project does not claim a measured helper outcome from a real-world trial.
