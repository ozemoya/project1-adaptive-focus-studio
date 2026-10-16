import 'package:adaptive_focus_studio/main.dart';
import 'package:adaptive_focus_studio/preset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late PresetStore store;
  setUp(() async {
    store = await PresetStore.open(
      databaseFactoryFfiNoIsolate,
      inMemoryDatabasePath,
    );
  });
  tearDown(() async => store.close());

  testWidgets('all five sections are reachable from the navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(AdaptiveFocusApp(store: store));
    await tester.pumpAndSettle();

    final sections = <String, String>{
      'Presets': 'Daily\nFocus',
      'Editor': 'Create a preset',
      'Focus': 'Run a focus session',
      'History': 'Review your sessions',
      'Settings': 'Choose local preferences',
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
    await tester.pumpWidget(AdaptiveFocusApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add new  +'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save preset'));
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
    await tester.tap(find.text('Save preset'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a whole number from 1 to 180'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Duration (minutes)'),
      '30',
    );
    await tester.tap(find.text('Save preset'));
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

    await tester.pumpWidget(AdaptiveFocusApp(store: store));
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
    final created = await store.create(
      const FocusPreset(name: 'Reading', durationMinutes: 30),
    );
    await tester.pumpWidget(AdaptiveFocusApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reading'));
    await tester.pumpAndSettle();
    expect(find.text('Edit a preset'), findsOneWidget);
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
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(await store.all(), isEmpty);
  });
}
