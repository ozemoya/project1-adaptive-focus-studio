import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as mobile;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class FocusPreset {
  const FocusPreset({
    this.id,
    required this.name,
    required this.durationMinutes,
    this.mood = 'Calm',
  });

  final int? id;
  final String name;
  final int durationMinutes;
  final String mood;
}

class FocusSession {
  const FocusSession({
    this.id,
    required this.presetName,
    required this.mood,
    required this.plannedMinutes,
    required this.completedMinutes,
    required this.finishedAt,
    this.isManual = false,
  });

  final int? id;
  final String presetName;
  final String mood;
  final int plannedMinutes;
  final int completedMinutes;
  final DateTime finishedAt;
  final bool isManual;
}

class PresetStore {
  PresetStore._(this._database);

  final Database _database;

  static Future<PresetStore> open(DatabaseFactory factory, String path) async {
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
          CREATE TABLE presets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL CHECK(duration_minutes BETWEEN 1 AND 180),
            mood TEXT NOT NULL DEFAULT 'Calm'
          )
        ''');
          await _createSessions(db, withManual: true);
        },
        onUpgrade: (db, oldVersion, _) async {
          if (oldVersion < 2) {
            await db.execute(
              "ALTER TABLE presets ADD COLUMN mood TEXT NOT NULL DEFAULT 'Calm'",
            );
            await _createSessions(db, withManual: false);
          }
          if (oldVersion < 3) {
            await db.execute(
              'ALTER TABLE sessions ADD COLUMN manual INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      ),
    );
    return PresetStore._(database);
  }

  static Future<PresetStore> openDevice() async {
    final directory = await getApplicationSupportDirectory();
    final path = p.join(directory.path, 'adaptive_focus_studio.db');
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return open(databaseFactoryFfi, path);
    }
    return open(mobile.databaseFactory, path);
  }

  Future<List<FocusPreset>> all() async {
    final rows = await _database.query('presets', orderBy: 'id DESC');
    return [
      for (final row in rows)
        FocusPreset(
          id: row['id'] as int,
          name: row['name'] as String,
          durationMinutes: row['duration_minutes'] as int,
          mood: row['mood'] as String,
        ),
    ];
  }

  Future<FocusPreset> create(FocusPreset preset) async {
    final id = await _database.insert('presets', {
      'name': preset.name,
      'duration_minutes': preset.durationMinutes,
      'mood': preset.mood,
    });
    return FocusPreset(
      id: id,
      name: preset.name,
      durationMinutes: preset.durationMinutes,
      mood: preset.mood,
    );
  }

  Future<int> update(FocusPreset preset) async {
    if (preset.id == null) {
      throw ArgumentError('Cannot update an unsaved preset');
    }
    return _database.update(
      'presets',
      {
        'name': preset.name,
        'duration_minutes': preset.durationMinutes,
        'mood': preset.mood,
      },
      where: 'id = ?',
      whereArgs: [preset.id],
    );
  }

  Future<int> delete(int id) =>
      _database.delete('presets', where: 'id = ?', whereArgs: [id]);

  static Future<void> _createSessions(
    DatabaseExecutor db, {
    required bool withManual,
  }) => db.execute('''
    CREATE TABLE sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      preset_name TEXT NOT NULL,
      mood TEXT NOT NULL,
      planned_minutes INTEGER NOT NULL,
      completed_minutes INTEGER NOT NULL,
      finished_at TEXT NOT NULL${withManual ? ', manual INTEGER NOT NULL DEFAULT 0' : ''}
    )
  ''');

  Future<List<FocusSession>> sessions() async {
    final rows = await _database.query(
      'sessions',
      orderBy: 'finished_at DESC, id DESC',
    );
    return [
      for (final row in rows)
        FocusSession(
          id: row['id'] as int,
          presetName: row['preset_name'] as String,
          mood: row['mood'] as String,
          plannedMinutes: row['planned_minutes'] as int,
          completedMinutes: row['completed_minutes'] as int,
          finishedAt: DateTime.parse(row['finished_at'] as String),
          isManual: (row['manual'] as int) == 1,
        ),
    ];
  }

  Future<FocusSession> createSession(FocusSession session) async {
    final id = await _database.insert('sessions', {
      'preset_name': session.presetName,
      'mood': session.mood,
      'planned_minutes': session.plannedMinutes,
      'completed_minutes': session.completedMinutes,
      'finished_at': session.finishedAt.toIso8601String(),
      'manual': session.isManual ? 1 : 0,
    });
    return FocusSession(
      id: id,
      presetName: session.presetName,
      mood: session.mood,
      plannedMinutes: session.plannedMinutes,
      completedMinutes: session.completedMinutes,
      finishedAt: session.finishedAt,
      isManual: session.isManual,
    );
  }

  Future<int> updateSession(FocusSession session) {
    if (session.id == null) {
      throw ArgumentError('Cannot update an unsaved session');
    }
    return _database.update(
      'sessions',
      {
        'preset_name': session.presetName,
        'mood': session.mood,
        'planned_minutes': session.plannedMinutes,
        'completed_minutes': session.completedMinutes,
        'finished_at': session.finishedAt.toIso8601String(),
        'manual': session.isManual ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) =>
      _database.delete('sessions', where: 'id = ?', whereArgs: [id]);

  Future<void> close() => _database.close();
}
