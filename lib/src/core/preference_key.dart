import 'pref_serializer.dart';
import 'pref_types.dart';

class PreferenceKey<T> {
  final String key;
  final PreferenceStorage storage;
  final String? writePolicy;
  final T? defaultValue;
  final String description;
  final PrefSerializer<T>? serializer;

  const PreferenceKey({
    required this.key,
    required this.storage,
    this.writePolicy,
    this.defaultValue,
    this.description = '',
    this.serializer,
  });
}
