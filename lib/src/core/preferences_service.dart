import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preference_key.dart';
import 'preferences_storage_router.dart';
import 'storage_adapters.dart';

class PreferencesService {
  static PreferencesService? _instance;

  static PreferencesService get instance {
    assert(
      _instance != null,
      'PreferencesService is not initialized. '
      'Call PreferencesService.initialize() before accessing instance.',
    );
    return _instance!;
  }

  final PreferencesStorageRouter router;
  final Map<String, StreamController<Object?>> _controllers =
      <String, StreamController<Object?>>{};

  PreferencesService._(this.router);

  static Future<PreferencesService> initialize({
    SharedPreferences? sharedPreferences,
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) async {
    if (_instance != null) return _instance!;
    final shared = sharedPreferences ?? await SharedPreferences.getInstance();
    _instance = PreferencesService._(
      PreferencesStorageRouter(
        shared: SharedPreferencesStoreAdapter(shared),
        secure: FlutterSecureStorageAdapter(secureStorage),
      ),
    );
    return _instance!;
  }

  /// Resets the singleton — intended for testing only.
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  Future<bool> contains<T>(PreferenceKey<T> key) => router.exists(key);

  Future<T?> get<T>(PreferenceKey<T> key) async {
    final value = await router.read(key);
    return value ?? key.defaultValue;
  }

  Future<void> remove<T>(PreferenceKey<T> key) async {
    await router.delete(key);
    _emit(key, key.defaultValue);
  }

  Future<void> set<T>(PreferenceKey<T> key, T value) async {
    await router.write(key, value);
    _emit(key, value);
  }

  Future<void> sync<T>(PreferenceKey<T> key) async {
    _emit(key, await get(key));
  }

  Stream<T?> watch<T>(PreferenceKey<T> key) {
    return Stream<T?>.multi((multi) async {
      multi.add(await get(key));
      final controller = _controllerFor(key.key);
      final subscription = controller.stream.listen(
        (event) => multi.add(event as T?),
        onError: multi.addError,
      );
      multi.onCancel = subscription.cancel;
    }, isBroadcast: true);
  }

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  StreamController<Object?> _controllerFor(String key) {
    return _controllers.putIfAbsent(
      key,
      () => StreamController<Object?>.broadcast(),
    );
  }

  void _emit<T>(PreferenceKey<T> key, T? value) {
    if (!_controllers.containsKey(key.key)) {
      return;
    }

    _controllers[key.key]!.add(value);
  }
}

typedef TypedPrefsService = PreferencesService;
