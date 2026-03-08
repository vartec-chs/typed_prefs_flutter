import '../serializers/built_in_serializers.dart';
import 'pref_serializer.dart';
import 'pref_types.dart';
import 'preference_key.dart';
import 'storage_adapters.dart';

class PreferencesStorageRouter {
  final SharedPreferencesStore shared;
  final SecurePreferencesStore secure;

  const PreferencesStorageRouter({required this.shared, required this.secure});

  Future<void> delete<T>(PreferenceKey<T> key) async {
    if (key.storage == PreferenceStorage.secure) {
      await secure.delete(key: key.key);
      return;
    }

    await shared.remove(key.key);
  }

  Future<bool> exists<T>(PreferenceKey<T> key) async {
    if (key.storage == PreferenceStorage.secure) {
      return await secure.read(key: key.key) != null;
    }

    return shared.containsKey(key.key);
  }

  Future<T?> read<T>(PreferenceKey<T> key) async {
    if (key.storage == PreferenceStorage.secure) {
      final value = await secure.read(key: key.key);
      if (value == null) {
        return null;
      }

      return _decode(key, value);
    }

    final rawValue = shared.get(key.key);
    if (rawValue == null) {
      return null;
    }

    return _decodeSharedValue(key, rawValue);
  }

  Future<void> write<T>(PreferenceKey<T> key, T value) async {
    if (key.storage == PreferenceStorage.secure) {
      await secure.write(key: key.key, value: _encode(key, value));
      return;
    }

    final serializer = key.serializer ?? _builtinSerializer<T>();
    if (serializer != null) {
      await shared.setString(key.key, serializer.encode(value));
      return;
    }

    final objectValue = value as Object?;
    if (objectValue is bool) {
      await shared.setBool(key.key, objectValue);
      return;
    }
    if (objectValue is int) {
      await shared.setInt(key.key, objectValue);
      return;
    }
    if (objectValue is double) {
      await shared.setDouble(key.key, objectValue);
      return;
    }
    if (objectValue is String) {
      await shared.setString(key.key, objectValue);
      return;
    }
    if (objectValue is List<String>) {
      await shared.setStringList(key.key, objectValue);
      return;
    }

    throw UnsupportedError(
      'Type $T is not supported directly. Provide a PrefSerializer<$T>.',
    );
  }

  T? _decode<T>(PreferenceKey<T> key, String value) {
    final serializer = key.serializer ?? _builtinSerializer<T>();
    if (serializer != null) {
      return serializer.decode(value);
    }
    if (T == String || value is T) {
      return value as T;
    }
    if (T == bool) {
      return (value.toLowerCase() == 'true') as T;
    }
    if (T == int) {
      return int.parse(value) as T;
    }
    if (T == double) {
      return double.parse(value) as T;
    }

    throw UnsupportedError('Type $T cannot be decoded without a serializer.');
  }

  T? _decodeSharedValue<T>(PreferenceKey<T> key, Object rawValue) {
    final serializer = key.serializer ?? _builtinSerializer<T>();
    if (serializer != null) {
      if (rawValue is! String) {
        throw StateError(
          'Preference ${key.key} uses a serializer and must be stored as String.',
        );
      }
      return serializer.decode(rawValue);
    }
    if (rawValue is T) {
      return rawValue as T;
    }

    throw StateError(
      'Preference ${key.key} was stored as ${rawValue.runtimeType}, expected $T.',
    );
  }

  String _encode<T>(PreferenceKey<T> key, T value) {
    final serializer = key.serializer ?? _builtinSerializer<T>();
    if (serializer != null) {
      return serializer.encode(value);
    }
    if (value is String) {
      return value;
    }
    if (value is bool || value is int || value is double) {
      return value.toString();
    }

    throw UnsupportedError('Type $T cannot be encoded without a serializer.');
  }

  PrefSerializer<T>? _builtinSerializer<T>() {
    if (T == DateTime) {
      return const DateTimePrefSerializer() as PrefSerializer<T>;
    }
    if (T == Duration) {
      return const DurationPrefSerializer() as PrefSerializer<T>;
    }
    if (T == Uri) {
      return const UriPrefSerializer() as PrefSerializer<T>;
    }
    if (T == BigInt) {
      return const BigIntPrefSerializer() as PrefSerializer<T>;
    }
    if (T == List<String>) {
      return const StringListPrefSerializer() as PrefSerializer<T>;
    }
    if (T == Map<String, String>) {
      return const StringMapPrefSerializer() as PrefSerializer<T>;
    }

    return null;
  }
}
