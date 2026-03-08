import 'preference_key.dart';
import 'preferences_service.dart';

class TypedPrefAccessor<T> {
  final PreferencesService _service;
  final PreferenceKey<T> key;

  const TypedPrefAccessor(this._service, this.key);

  Future<bool> exists() => _service.contains(key);

  Future<T?> get() => _service.get(key);

  Future<void> remove() => _service.remove(key);

  Future<void> set(T value) => _service.set(key, value);

  Stream<T?> watch() => _service.watch(key);
}
