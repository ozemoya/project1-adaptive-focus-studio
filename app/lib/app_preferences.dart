import 'package:shared_preferences/shared_preferences.dart';

/// Small, replaceable boundary around device preferences.
abstract class AppPreferences {
  Future<bool> darkMode();
  Future<void> setDarkMode(bool value);
  Future<int> defaultMinutes();
  Future<void> setDefaultMinutes(int value);
  Future<bool> reducedMotion();
  Future<void> setReducedMotion(bool value);
}

class DeviceAppPreferences implements AppPreferences {
  DeviceAppPreferences() : _storage = SharedPreferencesAsync();

  final SharedPreferencesAsync _storage;

  static const _darkKey = 'dark_mode';
  static const _minutesKey = 'default_minutes';
  static const _motionKey = 'reduced_motion';

  @override
  Future<bool> darkMode() async => await _storage.getBool(_darkKey) ?? false;

  @override
  Future<void> setDarkMode(bool value) => _storage.setBool(_darkKey, value);

  @override
  Future<int> defaultMinutes() async =>
      await _storage.getInt(_minutesKey) ?? 25;

  @override
  Future<void> setDefaultMinutes(int value) =>
      _storage.setInt(_minutesKey, value);

  @override
  Future<bool> reducedMotion() async =>
      await _storage.getBool(_motionKey) ?? false;

  @override
  Future<void> setReducedMotion(bool value) =>
      _storage.setBool(_motionKey, value);
}
