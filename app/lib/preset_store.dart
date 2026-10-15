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
  });

  final int? id;
  final String name;
  final int durationMinutes;
}

class PresetStore {
  PresetStore._(this._database);

  final Database _database;

  static Future<PresetStore> open(DatabaseFactory factory, String path) async {
    final database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute('''
          CREATE TABLE presets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            duration_minutes INTEGER NOT NULL CHECK(duration_minutes BETWEEN 1 AND 180)
          )
        '''),
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
        ),
    ];
  }

  Future<FocusPreset> create(FocusPreset preset) async {
    final id = await _database.insert('presets', {
      'name': preset.name,
      'duration_minutes': preset.durationMinutes,
    });
    return FocusPreset(
      id: id,
      name: preset.name,
      durationMinutes: preset.durationMinutes,
    );
  }

  Future<int> update(FocusPreset preset) async {
    if (preset.id == null) {
      throw ArgumentError('Cannot update an unsaved preset');
    }
    return _database.update(
      'presets',
      {'name': preset.name, 'duration_minutes': preset.durationMinutes},
      where: 'id = ?',
      whereArgs: [preset.id],
    );
  }

  Future<int> delete(int id) =>
      _database.delete('presets', where: 'id = ?', whereArgs: [id]);

  Future<void> close() => _database.close();
}
