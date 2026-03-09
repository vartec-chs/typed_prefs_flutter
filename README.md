# typed_prefs

A Flutter package that provides a type-safe preferences layer on top of
[SharedPreferences](https://pub.dev/packages/shared_preferences) and
[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage), with
optional code generation for ergonomic, boilerplate-free accessors.

## Features

- **Typed keys** — `PreferenceKey<T>` eliminates stringly-typed storage calls.
- **Automatic storage routing** — keys are transparently routed to
  `SharedPreferences` or `flutter_secure_storage` based on a single flag.
- **Secure groups** — mark an entire `@Prefs` class as `protected: true` to
  store all its keys in secure storage without repeating the flag on each field.
- **Grouped / modular preferences** — split keys across multiple `@Prefs`
  classes and compose them with `PrefGroupKey<T>` into a single root accessor.
- **Reactive streams** — `watch()` emits the current value on subscription and
  every subsequent write or removal.
- **Built-in serializers** for `DateTime`, `Duration`, `Uri`, `BigInt`,
  `List<String>`, `Map<String, String>` and all `enum` types.
- **Custom serializers** via `PrefSerializer<T>`.
- **Singleton service** — `PreferencesService.initialize()` once at startup;
  access anywhere via `PreferencesService.instance`.
- **Compile-time validation** — the generator rejects duplicate storage keys and
  unsupported types without a serializer.
- **Code generation** — `@Prefs`, `@Pref` and `PrefKey<T>` produce fully-typed
  accessor classes (`getX()`, `setX()`, `removeX()`, `watchX()`, `x.get()`).

## Installation

```yaml
dependencies:
  typed_prefs: ^1.0.0

dev_dependencies:
  build_runner: ^2.12.2
```

## Quick start

### 1. Initialize the service

Call `initialize()` once, before `runApp`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService.initialize();
  runApp(const MyApp());
}
```

Access the singleton anywhere:

```dart
final service = PreferencesService.instance;
```

### 2. Declare preferences

Split keys into focused groups and compose them:

```dart
// auth_prefs.dart
part 'auth_prefs.g.dart';

@Prefs(protected: true)          // all keys → flutter_secure_storage
class AuthPrefs {
  static const vaultKey = PrefKey<String>();

  @Pref(defaultValue: false)
  static const biometricsEnabled = PrefKey<bool>();

  @Pref(serializer: DateTimeSerializer)
  static const lastSyncAt = PrefKey<DateTime>();
}

// settings_prefs.dart
part 'settings_prefs.g.dart';

@Prefs()
class SettingsPrefs {
  @Pref(defaultValue: ThemeMode.system)
  static const themeMode = PrefKey<ThemeMode>();

  @Pref(defaultValue: <String>['ru', 'en'])
  static const preferredLocales = PrefKey<List<String>>();
}

// app_prefs.dart — root compositor
part 'app_prefs.g.dart';

@Prefs()
class AppPrefs {
  static const auth     = PrefGroupKey<AuthPrefs>();
  static const settings = PrefGroupKey<SettingsPrefs>();
}
```

### 3. Run code generation

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Use the generated API

```dart
final prefs = PreferencesService.instance.appPrefs;

// grouped access
final theme = await prefs.settings.getThemeMode();
await prefs.settings.setThemeMode(ThemeMode.dark);

final key = await prefs.auth.getVaultKey();
await prefs.auth.vaultKey.set('s3cr3t');

// reactive
prefs.settings.watchThemeMode().listen((mode) {
  print('theme changed: $mode');
});
```

## @Prefs options

| Parameter      | Type     | Default             | Description                                       |
| -------------- | -------- | ------------------- | ------------------------------------------------- |
| `accessorName` | `String` | `${ClassName}Store` | Override the generated accessor class name.       |
| `keysName`     | `String` | `${ClassName}Keys`  | Override the generated keys class name.           |
| `protected`    | `bool`   | `false`             | Force all keys in this class into secure storage. |

## @Pref options

| Parameter      | Type     | Default                  | Description                                                  |
| -------------- | -------- | ------------------------ | ------------------------------------------------------------ |
| `key`          | `String` | snake_case of field name | Override the storage key string.                             |
| `protected`    | `bool`   | `false`                  | Store this individual key in secure storage.                 |
| `defaultValue` | `Object` | —                        | Value returned when the key is absent.                       |
| `description`  | `String` | `''`                     | Documentation string embedded in the generated key constant. |
| `serializer`   | `Type`   | —                        | Custom `PrefSerializer<T>` class.                            |

## Manual API

Use `PreferenceKey<T>` directly without code generation:

```dart
const themeModeKey = PreferenceKey<String>(
  key: 'theme_mode',
  storage: PreferenceStorage.shared,
  defaultValue: 'system',
  description: 'Theme mode of the application',
);

const biometricsKey = PreferenceKey<bool>(
  key: 'biometrics_enabled',
  storage: PreferenceStorage.secure,
  defaultValue: false,
);

final service = PreferencesService.instance;

await service.set(themeModeKey, 'dark');
final theme = await service.get(themeModeKey);   // 'dark'

service.watch(themeModeKey).listen((value) {
  print('Theme changed: $value');
});
```

## Custom serializers

```dart
class DateTimeSerializer extends PrefSerializer<DateTime> {
  const DateTimeSerializer();

  @override
  String encode(DateTime value) => value.toIso8601String();

  @override
  DateTime decode(String value) => DateTime.parse(value);
}

@Prefs()
class SyncPrefs {
  @Pref(serializer: DateTimeSerializer)
  static const lastSyncAt = PrefKey<DateTime>();
}
```

Built-in serializers are selected automatically for: `DateTime`, `Duration`,
`Uri`, `BigInt`, `List<String>`, `Map<String, String>` and any `enum`.

## Storage model

| Value type              | `shared` storage                  | `secure` storage      |
| ----------------------- | --------------------------------- | --------------------- |
| `bool`, `int`, `double` | Native `SharedPreferences` setter | Encoded as `String`   |
| `String`                | `SharedPreferences.setString`     | Stored as-is          |
| `List<String>`          | `SharedPreferences.setStringList` | JSON-encoded `String` |
| Complex / custom        | Serializer → `setString`          | Serializer → `String` |

## Testing

Reset the singleton between tests:

```dart
setUp(() async {
  PreferencesService.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  await PreferencesService.initialize();
});
```

## Example

A runnable Flutter example is in [example/lib/main.dart](example/lib/main.dart)
and [example/lib/app_prefs.dart](example/lib/app_prefs.dart).
