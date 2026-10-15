import 'package:adaptive_focus_studio/main.dart';
import 'package:adaptive_focus_studio/preset_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late PresetStore store;
  setUp(() async {
    store = await PresetStore.open(databaseFactoryFfiNoIsolate, inMemoryDatabasePath);
  });
  tearDown(() async => store.close());

  testWidgets('all five sections are reachable from the navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(AdaptiveFocusApp(store: store));
    await tester.pumpAndSettle();

    final sections = <String, String>{
      'Presets': 'Choose a focus plan',
      'Editor': 'Create or edit a preset',
      'Focus': 'Run a focus session',
      'History': 'Review your sessions',
      'Settings': 'Choose local preferences',
    };

    for (final entry in sections.entries) {
      await tester.tap(find.widgetWithText(NavigationDestination, entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
    }
  });

  testWidgets('preset editor rejects invalid values and shows a saved preset', (
    tester,
  ) async {
    await tester.pumpWidget(AdaptiveFocusApp(store: store));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create preset'));
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
    expect(find.text('Choose a focus plan'), findsOneWidget);
    expect(find.text('Reading'), findsOneWidget);
    expect(find.text('30 minutes'), findsOneWidget);
    expect((await store.all()).single.name, 'Reading');
  });
}
