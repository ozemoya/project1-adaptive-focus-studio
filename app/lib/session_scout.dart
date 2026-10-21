import 'preset_store.dart';

/// A transparent, local duration suggestion based on three finished sessions.
class ScoutSuggestion {
  const ScoutSuggestion(this.minutes, this.samples);

  static const baselineMinutes = 25;

  final int minutes;
  final List<int> samples;
}

ScoutSuggestion? suggestDuration(
  List<FocusSession> sessions,
  String selectedMood,
) {
  final matching =
      sessions
          .where(
            (session) =>
                session.mood == selectedMood &&
                session.completedMinutes >= 1 &&
                session.completedMinutes <= 180,
          )
          .toList()
        ..sort((a, b) => b.finishedAt.compareTo(a.finishedAt));
  if (matching.length < 3) return null;

  final samples =
      matching.take(3).map((session) => session.completedMinutes).toList()
        ..sort();
  return ScoutSuggestion(samples[1].clamp(10, 60), samples);
}
