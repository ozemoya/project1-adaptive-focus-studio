import 'dart:async';

import 'package:adaptive_focus_studio/main.dart';
import 'package:adaptive_focus_studio/app_preferences.dart';
import 'package:adaptive_focus_studio/focus_screen.dart';
import 'package:adaptive_focus_studio/history_screen.dart';
import 'package:adaptive_focus_studio/preset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late PresetStore store;
  late _MemoryPreferences preferences;
  setUp(() async {
    preferences = _MemoryPreferences();
    store = await PresetStore.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
    );
  });
  tearDown(() async => store.close());

  testWidgets('manual history save cannot be submitted twice', (tester) async {
    _useTallPhone(tester);
    final pendingSave = Completer<bool>();
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            sessions: const [],
            onDelete: (_) {},
            onSave: (_) {
              requests++;
              return pendingSave.future;
            },
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('+ Add manual log'));
    await tester.tap(find.text('+ Add manual log'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Plan name'),
      'Review',
    );
    await tester.tap(find.text('Save log'));
    await tester.pump();
    expect(requests, 1);
    expect(find.text('Saving...'), findsOneWidget);
    final saveButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Saving...'),
    );
    expect(saveButton.onPressed, isNull);
    pendingSave.complete(true);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expect(find.text('Add manual log'), findsNothing);
  });

  testWidgets('timer catches up after delayed ticks and respects pause', (
    tester,
  ) async {
    _useTallPhone(tester);
    var now = DateTime.utc(2026, 10, 20, 9);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusScreen(
            preset: const FocusPreset(
              name: 'Short session',
              durationMinutes: 1,
            ),
            sessions: const [],
            onFinish: (_) async => true,
            onChoosePlan: () {},
            now: () => now,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start session'));
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:30'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    now = now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:30'), findsOneWidget);
    await tester.tap(find.text('Resume'));
    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:00'), findsOneWidget);
    expect(find.textContaining('Complete · Elapsed 01:00'), findsOneWidget);
    final resume = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Resume'),
    );
    expect(resume.onPressed, isNull);
  });

  testWidgets('focus timer remains readable with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: FocusScreen(
              preset: const FocusPreset(name: 'Read', durationMinutes: 25),
              sessions: const [],
              onFinish: (_) async => true,
              onChoosePlan: () {},
            ),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('focus-timer')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('25:00'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Time remaining: 25 minutes and 0 seconds'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Session Scout applies a transparent duration suggestion', (
    tester,
  ) async {
    _useTallPhone(tester);
    final samples = [20, 30, 40]
        .asMap()
        .entries
        .map(
          (entry) => FocusSession(
            presetName: 'Earlier plan',
            mood: 'Calm',
            plannedMinutes: 25,
            completedMinutes: entry.value,
            finishedAt: DateTime.utc(2026, 10, entry.key + 1),
          ),
        )
        .toList();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusScreen(
            preset: const FocusPreset(name: 'Reading', durationMinutes: 25),
            sessions: samples,
            onFinish: (_) async => true,
            onChoosePlan: () {},
          ),
        ),
      ),
    );
    expect(find.text('Try 30 minutes'), findsOneWidget);
    expect(find.textContaining('Fixed baseline: 25 min'), findsOneWidget);
    await tester.ensureVisible(find.text('Apply suggestion'));
    await tester.tap(find.text('Apply suggestion'));
    await tester.pump();
    expect(find.text('30:00'), findsOneWidget);
    expect(find.textContaining('Planned 30 minutes'), findsOneWidget);
    expect(find.text('Try 30 minutes'), findsNothing);
  });

  testWidgets('all five sections are reachable from the navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();

    final sections = <String, String>{
      'Presets': 'Daily\nFocus',
      'Editor': 'Make a plan',
      'Focus': 'Time to focus',
      'History': 'Your progress',
      'Settings': 'Make it yours',
    };

    for (final entry in sections.entries) {
      await tester.tap(find.byKey(Key('nav-${entry.key}')));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('preset editor rejects invalid values and shows a saved preset', (
    tester,
  ) async {
    _useTallPhone(tester);
    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add new  +'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a preset name'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preset name'),
      'Reading',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '0',
    );
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number from 1 to 180'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '30',
    );
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();
    expect(find.text('Your Plan'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect((await store.all()).single.name, 'Reading');
  });

  testWidgets('home fits a phone screen in both color modes', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();
    expect(find.text('Daily\nFocus'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);

    tester.view.physicalSize = const Size(320, 700);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved plans can be edited and deleted from the dashboard', (
    tester,
  ) async {
    _useTallPhone(tester);
    final created = await store.create(
      const FocusPreset(name: 'Reading', durationMinutes: 30),
    );
    await store.createSession(
      FocusSession(
        presetId: created.id,
        presetName: created.name,
        mood: created.mood,
        plannedMinutes: 30,
        completedMinutes: 20,
        finishedAt: DateTime.utc(2026, 10, 23),
      ),
    );
    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(Key('plan-menu-${created.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit plan'));
    await tester.pumpAndSettle();
    expect(find.text('Edit preset'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Preset name'),
      'Writing',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect((await store.all()).single.name, 'Writing');
    expect((await store.all()).single.id, created.id);

    await tester.tap(find.byKey(Key('plan-menu-${created.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this plan?'), findsOneWidget);
    expect(find.textContaining('1 linked session'), findsOneWidget);
    await tester.tap(find.text('Keep plan'));
    await tester.pumpAndSettle();
    expect(await store.all(), hasLength(1));
    expect(await store.sessions(), hasLength(1));

    await tester.tap(find.byKey(Key('plan-menu-${created.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await store.all(), isEmpty);
    expect(await store.sessions(), isEmpty);
  });

  testWidgets('settings persist and set the next preset duration', (
    tester,
  ) async {
    _useTallPhone(tester);
    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-Settings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('25 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('45 min').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Dark mode'));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reduce motion'));
    await tester.tap(find.text('Reduce motion'));
    await tester.pumpAndSettle();

    expect(preferences.minutes, 45);
    expect(preferences.dark, isTrue);
    expect(preferences.motion, isTrue);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-Editor')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, '45'), findsOneWidget);
  });

  testWidgets('a selected plan runs and saves a session in history', (
    tester,
  ) async {
    _useTallPhone(tester);
    await store.create(
      const FocusPreset(
        name: 'Biology review',
        durationMinutes: 25,
        mood: 'Calm',
      ),
    );
    await tester.pumpWidget(
      AdaptiveFocusApp(store: store, preferences: preferences),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Biology review'));
    await tester.pumpAndSettle();
    expect(find.text('Time to focus'), findsOneWidget);
    expect(find.text('25:00'), findsOneWidget);

    await tester.tap(find.text('Start session'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);
    await tester.ensureVisible(find.text('Finish'));
    await tester.pump();
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect((await store.sessions()).single.presetName, 'Biology review');

    await tester.tap(find.byKey(const Key('nav-History')));
    await tester.pumpAndSettle();
    expect(find.text('Biology review'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-session-1')));
    await tester.pumpAndSettle();
    expect(find.text('Delete this session?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await store.sessions(), isEmpty);
  });
}

void _useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

class _MemoryPreferences implements AppPreferences {
  bool dark = false;
  bool motion = false;
  int minutes = 25;

  @override
  Future<bool> darkMode() async => dark;
  @override
  Future<void> setDarkMode(bool value) async => dark = value;
  @override
  Future<int> defaultMinutes() async => minutes;
  @override
  Future<void> setDefaultMinutes(int value) async => minutes = value;
  @override
  Future<bool> reducedMotion() async => motion;
  @override
  Future<void> setReducedMotion(bool value) async => motion = value;
}
