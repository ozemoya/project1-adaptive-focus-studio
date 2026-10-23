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
    expect(
      await reopened.updateSession(
        FocusSession(
          id: finished.id,
          presetName: 'Writing',
          mood: 'Tired',
          plannedMinutes: 45,
          completedMinutes: 20,
          finishedAt: finished.finishedAt,
          isManual: true,
        ),
      ),
      1,
    );
    expect((await reopened.sessions()).single.isManual, isTrue);
    expect((await reopened.sessions()).single.completedMinutes, 20);
    expect(await reopened.deleteSession(finished.id!), 1);
    expect(await reopened.sessions(), isEmpty);
    expect(await reopened.delete(created.id!), 1);
    expect(await reopened.all(), isEmpty);
    await reopened.close();
    await factory.deleteDatabase(databasePath);
  });

  test('older preset databases upgrade without losing saved plans', () async {
    final factory = databaseFactoryFfi;
    final path = await factory.getDatabasesPath();
    final databasePath = '$path/preset_store_upgrade_test.db';
    await factory.deleteDatabase(databasePath);

    final legacy = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE presets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              duration_minutes INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await legacy.insert('presets', {
      'name': 'Original plan',
      'duration_minutes': 25,
    });
    await legacy.close();

    final upgraded = await PresetStore.open(factory, databasePath);
    final plans = await upgraded.all();
    expect(plans, hasLength(1));
    expect(plans.single.name, 'Original plan');
    expect(plans.single.mood, 'Calm');
    expect(await upgraded.sessions(), isEmpty);
    await upgraded.createSession(
      FocusSession(
        presetName: plans.single.name,
        mood: plans.single.mood,
        plannedMinutes: 25,
        completedMinutes: 20,
        finishedAt: DateTime.utc(2026, 10, 18),
        isManual: true,
      ),
    );
    expect((await upgraded.sessions()).single.isManual, isTrue);
    await upgraded.close();
    await factory.deleteDatabase(databasePath);
  });

  test(
    'deleting a preset cascades linked logs but keeps manual logs',
    () async {
      final store = await PresetStore.open(
        databaseFactoryFfiNoIsolate,
        inMemoryDatabasePath,
      );
      final preset = await store.create(
        const FocusPreset(name: 'Reading', durationMinutes: 25),
      );
      await store.createSession(
        FocusSession(
          presetId: preset.id,
          presetName: preset.name,
          mood: preset.mood,
          plannedMinutes: 25,
          completedMinutes: 20,
          finishedAt: DateTime.utc(2026, 10, 22),
        ),
      );
      await store.createSession(
        FocusSession(
          presetName: 'Independent log',
          mood: 'Calm',
          plannedMinutes: 10,
          completedMinutes: 10,
          finishedAt: DateTime.utc(2026, 10, 23),
          isManual: true,
        ),
      );
      expect(await store.linkedSessionCount(preset.id!), 1);
      expect(await store.delete(preset.id!), 1);
      final remaining = await store.sessions();
      expect(remaining, hasLength(1));
      expect(remaining.single.presetName, 'Independent log');
      await store.close();
    },
  );

  test('version three history survives linked-session migration', () async {
    final factory = databaseFactoryFfi;
    final path = await factory.getDatabasesPath();
    final databasePath = '$path/session_link_upgrade_test.db';
    await factory.deleteDatabase(databasePath);
    final legacy = await factory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE presets (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              duration_minutes INTEGER NOT NULL,
              mood TEXT NOT NULL DEFAULT 'Calm'
            )
          ''');
          await db.execute('''
            CREATE TABLE sessions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              preset_name TEXT NOT NULL,
              mood TEXT NOT NULL,
              planned_minutes INTEGER NOT NULL,
              completed_minutes INTEGER NOT NULL,
              finished_at TEXT NOT NULL,
              manual INTEGER NOT NULL DEFAULT 0
            )
          ''');
        },
      ),
    );
    await legacy.insert('sessions', {
      'preset_name': 'Old session',
      'mood': 'Calm',
      'planned_minutes': 25,
      'completed_minutes': 20,
      'finished_at': DateTime.utc(2026, 10, 20).toIso8601String(),
      'manual': 0,
    });
    await legacy.close();

    final upgraded = await PresetStore.open(factory, databasePath);
    final sessions = await upgraded.sessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.presetName, 'Old session');
    expect(sessions.single.presetId, isNull);
    await upgraded.close();
    await factory.deleteDatabase(databasePath);
  });
}
