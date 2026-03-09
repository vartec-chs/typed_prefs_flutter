import 'preference_key.dart';
import 'preference_write_policy.dart';
import 'preferences_service.dart';

class TypedPrefAccessor<T> {
  final PreferencesService _service;
  final PreferenceKey<T> key;

  const TypedPrefAccessor(this._service, this.key);

  Future<bool> exists() => _service.contains(key);

  Future<T?> get() => _service.get(key);

  Future<void> remove({PreferenceWriteErrorCallback? onWriteError}) =>
      _service.remove(key, onWriteError: onWriteError);

  Future<void> set(T value, {PreferenceWriteErrorCallback? onWriteError}) =>
      _service.set(key, value, onWriteError: onWriteError);

  Stream<T?> watch() => _service.watch(key);
}
