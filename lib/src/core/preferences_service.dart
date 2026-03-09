import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preference_key.dart';
import 'preference_write_policy.dart';
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
  final Map<String, PreferenceWritePolicy> _writePolicies;
  final Map<String, StreamController<Object?>> _controllers =
      <String, StreamController<Object?>>{};

  PreferencesService._(this.router, this._writePolicies);

  static Future<PreferencesService> initialize({
    SharedPreferences? sharedPreferences,
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
    Map<String, PreferenceWritePolicy> writePolicies = const {},
  }) async {
    if (_instance != null) return _instance!;
    final shared = sharedPreferences ?? await SharedPreferences.getInstance();
    _instance = PreferencesService._(
      PreferencesStorageRouter(
        shared: SharedPreferencesStoreAdapter(shared),
        secure: FlutterSecureStorageAdapter(secureStorage),
      ),
      Map<String, PreferenceWritePolicy>.from(writePolicies),
    );
    return _instance!;
  }

  /// Resets the singleton - intended for testing only.
  static void resetForTesting() {
    _instance?.dispose();
    _instance = null;
  }

  Future<bool> contains<T>(PreferenceKey<T> key) => router.exists(key);

  Future<T?> get<T>(PreferenceKey<T> key) async {
    final value = await router.read(key);
    return value ?? key.defaultValue;
  }

  Future<void> remove<T>(
    PreferenceKey<T> key, {
    PreferenceWriteErrorCallback? onWriteError,
  }) async {
    final authorized = await _authorizeWrite(
      key,
      operation: PreferenceWriteOperation.remove,
      nextValue: key.defaultValue,
      onWriteError: onWriteError,
    );
    if (!authorized) {
      return;
    }

    await router.delete(key);
    _emit(key, key.defaultValue);
  }

  Future<void> set<T>(
    PreferenceKey<T> key,
    T value, {
    PreferenceWriteErrorCallback? onWriteError,
  }) async {
    final authorized = await _authorizeWrite(
      key,
      operation: PreferenceWriteOperation.set,
      nextValue: value,
      onWriteError: onWriteError,
    );
    if (!authorized) {
      return;
    }

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

  void registerWritePolicy(String name, PreferenceWritePolicy policy) {
    _writePolicies[name] = policy;
  }

  void registerWritePolicies(Map<String, PreferenceWritePolicy> policies) {
    _writePolicies.addAll(policies);
  }

  void unregisterWritePolicy(String name) {
    _writePolicies.remove(name);
  }

  PreferenceWritePolicy? writePolicy(String name) => _writePolicies[name];

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    _writePolicies.clear();
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

  Future<bool> _authorizeWrite<T>(
    PreferenceKey<T> key, {
    required PreferenceWriteOperation operation,
    required T? nextValue,
    PreferenceWriteErrorCallback? onWriteError,
  }) async {
    final policyName = key.writePolicy;
    if (policyName == null) {
      return true;
    }

    final currentValue = await get(key);
    final policy = _writePolicies[policyName];
    if (policy == null) {
      return _handleWriteFailure(
        policyName: policyName,
        key: key,
        operation: operation,
        currentValue: currentValue,
        nextValue: nextValue,
        error: StateError(
          'Write policy "$policyName" is not registered for key "${key.key}".',
        ),
        stackTrace: StackTrace.current,
        onWriteError: onWriteError,
      );
    }

    try {
      await policy.authorize<T>(
        PreferenceWriteRequest<T>(
          key: key,
          operation: operation,
          currentValue: currentValue,
          nextValue: nextValue,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      return _handleWriteFailure(
        policyName: policyName,
        key: key,
        operation: operation,
        currentValue: currentValue,
        nextValue: nextValue,
        error: error,
        stackTrace: stackTrace,
        onWriteError: onWriteError,
      );
    }
  }

  Future<bool> _handleWriteFailure<T>({
    required String? policyName,
    required PreferenceKey<T> key,
    required PreferenceWriteOperation operation,
    required T? currentValue,
    required T? nextValue,
    required Object error,
    required StackTrace stackTrace,
    required PreferenceWriteErrorCallback? onWriteError,
  }) async {
    if (onWriteError != null) {
      await onWriteError(
        PreferenceWriteFailure(
          policyName: policyName,
          key: key.key,
          operation: operation,
          currentValue: currentValue,
          nextValue: nextValue,
          error: error,
          stackTrace: stackTrace,
        ),
      );
      return false;
    }

    Error.throwWithStackTrace(error, stackTrace);
  }
}

typedef TypedPrefsService = PreferencesService;
