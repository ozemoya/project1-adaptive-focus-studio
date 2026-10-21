import 'package:adaptive_focus_studio/preset_store.dart';
import 'package:adaptive_focus_studio/session_scout.dart';
import 'package:flutter_test/flutter_test.dart';

FocusSession session(int minutes, int day, {String mood = 'Calm'}) =>
    FocusSession(
      presetName: 'Focus',
      mood: mood,
      plannedMinutes: 25,
      completedMinutes: minutes,
      finishedAt: DateTime.utc(2026, 10, day),
    );

void main() {
  test('normal case takes the median of the three most recent matches', () {
    final result = suggestDuration([
      session(55, 1), // Older and excluded.
      session(30, 3),
      session(20, 2),
      session(25, 4),
      session(40, 5, mood: 'Tired'),
    ], 'Calm');
    expect(result?.samples, [20, 25, 30]);
    expect(result?.minutes, 25);
    expect(ScoutSuggestion.baselineMinutes, 25);
  });

  test('insufficient matching history gives no suggestion', () {
    expect(suggestDuration([session(20, 1), session(30, 2)], 'Calm'), isNull);
  });

  test('invalid completed durations are excluded', () {
    expect(
      suggestDuration([
        session(0, 5),
        session(-2, 4),
        session(181, 3),
        session(20, 2),
        session(25, 1),
      ], 'Calm'),
      isNull,
    );
  });

  test('boundary and outlier case clamps the median to 60 minutes', () {
    final result = suggestDuration([
      session(2, 1),
      session(100, 2),
      session(180, 3),
    ], 'Calm');
    expect(result?.minutes, 60);
  });

  test('short-session counterexample shows the ten-minute lower clamp', () {
    final result = suggestDuration([
      session(1, 1),
      session(2, 2),
      session(3, 3),
    ], 'Calm');
    expect(result?.minutes, 10);
  });
}
