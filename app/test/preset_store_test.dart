import 'package:adaptive_focus_studio/preset_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('preset records survive a database reopen and support CRUD', () async {
    final factory = databaseFactoryFfi;
    final path = await factory.getDatabasesPath();
    final databasePath = '$path/preset_store_test.db';
    await factory.deleteDatabase(databasePath);

    final first = await PresetStore.open(factory, databasePath);
    final created = await first.create(
      const FocusPreset(name: 'Reading', durationMinutes: 30),
    );
    expect(created.id, isNotNull);
    await first.close();

    final reopened = await PresetStore.open(factory, databasePath);
    expect((await reopened.all()).single.name, 'Reading');
    expect(
      await reopened.update(
        FocusPreset(id: created.id, name: 'Writing', durationMinutes: 45),
      ),
      1,
    );
    expect((await reopened.all()).single.durationMinutes, 45);
    expect((await reopened.all()).single.mood, 'Calm');
    final finished = await reopened.createSession(
      FocusSession(
        presetName: 'Writing',
        mood: 'Calm',
        plannedMinutes: 45,
        completedMinutes: 23,
        finishedAt: DateTime.utc(2026, 10, 17, 9),
      ),
    );
    expect((await reopened.sessions()).single.completedMinutes, 23);
    expect(await reopened.deleteSession(finished.id!), 1);
    expect(await reopened.sessions(), isEmpty);
    expect(await reopened.delete(created.id!), 1);
    expect(await reopened.all(), isEmpty);
    await reopened.close();
    await factory.deleteDatabase(databasePath);
  });
}
