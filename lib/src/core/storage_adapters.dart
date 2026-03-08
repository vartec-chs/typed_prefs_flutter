import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SharedPreferencesStore {
  Object? get(String key);

  bool containsKey(String key);

  Future<bool> remove(String key);

  Future<bool> setBool(String key, bool value);

  Future<bool> setDouble(String key, double value);

  Future<bool> setInt(String key, int value);

  Future<bool> setString(String key, String value);

  Future<bool> setStringList(String key, List<String> value);
}

abstract interface class SecurePreferencesStore {
  Future<void> delete({required String key});

  Future<String?> read({required String key});

  Future<void> write({required String key, required String value});
}

class SharedPreferencesStoreAdapter implements SharedPreferencesStore {
  final SharedPreferences preferences;

  const SharedPreferencesStoreAdapter(this.preferences);

  @override
  bool containsKey(String key) => preferences.containsKey(key);

  @override
  Object? get(String key) => preferences.get(key);

  @override
  Future<bool> remove(String key) => preferences.remove(key);

  @override
  Future<bool> setBool(String key, bool value) =>
      preferences.setBool(key, value);

  @override
  Future<bool> setDouble(String key, double value) =>
      preferences.setDouble(key, value);

  @override
  Future<bool> setInt(String key, int value) => preferences.setInt(key, value);

  @override
  Future<bool> setString(String key, String value) =>
      preferences.setString(key, value);

  @override
  Future<bool> setStringList(String key, List<String> value) =>
      preferences.setStringList(key, value);
}

class FlutterSecureStorageAdapter implements SecurePreferencesStore {
  final FlutterSecureStorage storage;

  const FlutterSecureStorageAdapter(this.storage);

  @override
  Future<void> delete({required String key}) => storage.delete(key: key);

  @override
  Future<String?> read({required String key}) => storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      storage.write(key: key, value: value);
}
