class Prefs {
  final String? accessorName;
  final String? keysName;

  /// When true, all keys in this class are stored in secure storage,
  /// overriding any individual [@Pref(protected:)] settings.
  final bool protected;
  final String? writePolicy;

  const Prefs({
    this.accessorName,
    this.keysName,
    this.protected = false,
    this.writePolicy,
  });
}

class Pref {
  final String? key;
  final bool protected;
  final String? writePolicy;
  final Object? defaultValue;
  final String description;
  final Type? serializer;

  const Pref({
    this.key,
    this.protected = false,
    this.writePolicy,
    this.defaultValue,
    this.description = '',
    this.serializer,
  });
}

class PrefKey<T> {
  const PrefKey();
}

/// Marks a static const field as a reference to another [@Prefs]-annotated
/// class. The generator will emit a sub-accessor getter for it.
///
/// ```dart
/// @Prefs()
/// class AppPrefs {
///   static const auth = PrefGroupKey<AuthPrefs>();
///   static const settings = PrefGroupKey<SettingsPrefs>();
/// }
/// ```
class PrefGroupKey<T> {
  const PrefGroupKey();
}
