# typed_prefs

`typed_prefs` is a Flutter package for storing app preferences with real types instead of raw string keys.

It sits on top of:

- `shared_preferences` for regular values
- `flutter_secure_storage` for sensitive values

You can use it in two ways:

- manually, with `PreferenceKey<T>`
- with code generation, using `@Prefs` and `@Pref`

The generated API is the main value of the package: you define preferences once and get typed getters, setters, removers, watchers, and grouped accessors.

## Why use it

Working with preferences usually becomes messy over time:

- keys are repeated as strings across the app
- secure and non-secure values are handled differently
- complex types need custom encode/decode logic
- feature modules end up sharing one giant preferences file

`typed_prefs` solves that by giving you:

- type-safe preference definitions
- optional code generation for clean APIs
- automatic routing to shared or secure storage
- grouped preference modules
- reactive `watch()` streams
- built-in serializers for common non-primitive types
- runtime write policies for protected updates

## Features

- Type-safe keys with `PreferenceKey<T>`
- Code generation with `@Prefs`, `@Pref`, `PrefKey<T>`, and `PrefGroupKey<T>`
- Support for both `shared_preferences` and `flutter_secure_storage`
- Group-level secure storage with `@Prefs(protected: true)`
- Group-level and field-level write policies
- Compile-time validation for duplicate keys and unsupported generated types
- Built-in serializers for:
  - `DateTime`
  - `Duration`
  - `Uri`
  - `BigInt`
  - `List<String>`
  - `Map<String, String>`
  - enums
- Custom serializers via `PrefSerializer<T>`
- Reactive updates via `watch()`
- Singleton service for easy app-wide access

## Installation

Add the package and code generator:

```yaml
dependencies:
  typed_prefs: ^1.1.0

dev_dependencies:
  build_runner: ^2.12.2
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize the service

Initialize `PreferencesService` once before `runApp()`:

```dart
import 'package:flutter/widgets.dart';
import 'package:typed_prefs/typed_prefs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService.initialize();
  runApp(const MyApp());
}
```

After that, you can access it anywhere:

```dart
final service = PreferencesService.instance;
```

### 2. Define your preferences

Create one or more preference groups.

```dart
import 'package:flutter/material.dart';
import 'package:typed_prefs/typed_prefs.dart';

part 'app_prefs.g.dart';

@Prefs(protected: true)
class AuthPrefs {
  static const accessToken = PrefKey<String>();

  @Pref(defaultValue: false)
  static const biometricsEnabled = PrefKey<bool>();
}

@Prefs()
class SettingsPrefs {
  @Pref(defaultValue: ThemeMode.system)
  static const themeMode = PrefKey<ThemeMode>();

  @Pref(defaultValue: <String>['en'])
  static const preferredLocales = PrefKey<List<String>>();
}

@Prefs()
class AppPrefs {
  static const auth = PrefGroupKey<AuthPrefs>();
  static const settings = PrefGroupKey<SettingsPrefs>();
}
```

### 3. Generate the code

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Use the generated API

```dart
final prefs = PreferencesService.instance.appPrefs;

final theme = await prefs.settings.getThemeMode();
await prefs.settings.setThemeMode(ThemeMode.dark);

final token = await prefs.auth.getAccessToken();
await prefs.auth.accessToken.set('secret-token');

prefs.settings.watchThemeMode().listen((value) {
  print('Theme changed: $value');
});
```

## What gets generated

For each `@Prefs` class, `typed_prefs` generates:

- a keys class, such as `SettingsPrefsKeys`
- a typed accessor class, such as `SettingsPrefsStore`
- convenience methods like `getThemeMode()`, `setThemeMode()`, `removeThemeMode()`, and `watchThemeMode()`
- a `TypedPrefAccessor<T>` property for each field
- an extension on `PreferencesService`, such as `service.appPrefs`

That means you can use either style:

```dart
await prefs.settings.setThemeMode(ThemeMode.dark);
await prefs.settings.themeMode.set(ThemeMode.dark);
```

## Organizing Preferences

Large apps usually need more than one preferences file. `PrefGroupKey<T>` lets you split preferences by feature or domain and expose them through one root accessor.

Good examples:

- `AuthPrefs`
- `SettingsPrefs`
- `OnboardingPrefs`
- `ProfilePrefs`

This keeps your storage layer modular without giving up a single entry point.

## Secure Storage

If a value is sensitive, store it in secure storage.

You can do that for:

- one field, using `@Pref(protected: true)`
- a whole group, using `@Prefs(protected: true)`

Example:

```dart
@Prefs(protected: true)
class AuthPrefs {
  static const accessToken = PrefKey<String>();
  static const refreshToken = PrefKey<String>();
}
```

All keys in that group will use `flutter_secure_storage`.

## Default Values

Use `defaultValue` to return a fallback when the key is missing.

```dart
@Prefs()
class SettingsPrefs {
  @Pref(defaultValue: false)
  static const notificationsEnabled = PrefKey<bool>();
}
```

If the value was never written, `getNotificationsEnabled()` returns `false`.

## Built-in Serializers

The package can automatically handle these types:

- `DateTime`
- `Duration`
- `Uri`
- `BigInt`
- `List<String>`
- `Map<String, String>`
- any enum

Enums are supported automatically, so this is enough:

```dart
@Pref(defaultValue: ThemeMode.system)
static const themeMode = PrefKey<ThemeMode>();
```

## Custom Serializers

If you want to store your own model, create a serializer:

```dart
class UserProfile {
  final String name;
  final int age;

  const UserProfile({required this.name, required this.age});

  factory UserProfile.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return UserProfile(
      name: map['name'] as String,
      age: map['age'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
      };
}

class UserProfileSerializer extends PrefSerializer<UserProfile> {
  const UserProfileSerializer();

  static final _json = JsonPrefSerializer<UserProfile>(
    fromJson: UserProfile.fromJson,
    toJson: (value) => value.toJson(),
  );

  @override
  UserProfile decode(String value) => _json.decode(value);

  @override
  String encode(UserProfile value) => _json.encode(value);
}
```

Then use it in a preference:

```dart
@Pref(serializer: UserProfileSerializer)
static const currentUser = PrefKey<UserProfile>();
```

## Write Policies

Write policies let you intercept `set()` and `remove()` at runtime.

This is useful when a preference should only be changed after:

- biometric authentication
- PIN confirmation
- a business rule check
- a custom permission flow

Example:

```dart
class BiometricPolicy implements PreferenceWritePolicy {
  @override
  Future<void> authorize<T>(PreferenceWriteRequest<T> request) async {
    final authenticated = await localAuth.authenticate(
      localizedReason: 'Confirm this change',
    );

    if (!authenticated) {
      throw const PreferenceWriteDeniedException('Authentication required');
    }
  }
}

await PreferencesService.initialize(
  writePolicies: {
    'auth': BiometricPolicy(),
  },
);
```

Apply the policy by name:

```dart
@Pref(writePolicy: 'auth')
static const vaultKey = PrefKey<String>();
```

You can also apply one policy to an entire group:

```dart
@Prefs(writePolicy: 'auditLog')
class SettingsPrefs {
  ...
}
```

If you want to handle policy failures without throwing, use `onWriteError`:

```dart
await prefs.auth.vaultKey.set(
  'new-value',
  onWriteError: (failure) async {
    print(failure.error);
  },
);
```

## Manual API Without Code Generation

If you do not want generated files, you can work directly with `PreferenceKey<T>`.

```dart
const themeModeKey = PreferenceKey<String>(
  key: 'theme_mode',
  storage: PreferenceStorage.shared,
  defaultValue: 'system',
);

const accessTokenKey = PreferenceKey<String>(
  key: 'access_token',
  storage: PreferenceStorage.secure,
);

final service = PreferencesService.instance;

await service.set(themeModeKey, 'dark');
final value = await service.get(themeModeKey);

service.watch(themeModeKey).listen((nextValue) {
  print(nextValue);
});
```

This is useful if you want the type safety without adding code generation to a specific module.

## Annotation Reference

### `@Prefs`

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `accessorName` | `String?` | generated | Custom accessor class name |
| `keysName` | `String?` | generated | Custom keys class name |
| `protected` | `bool` | `false` | Store all keys in secure storage |
| `writePolicy` | `String?` | `null` | Apply the same write policy to the whole group |

### `@Pref`

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `key` | `String?` | generated from field name | Custom storage key |
| `protected` | `bool` | `false` | Store this field in secure storage |
| `writePolicy` | `String?` | `null` | Runtime write policy name |
| `defaultValue` | `Object?` | `null` | Value returned when missing |
| `description` | `String` | `''` | Documentation text for the generated key |
| `serializer` | `Type?` | `null` | Custom serializer type |

## Storage Behavior

Storage is chosen automatically for each key:

- shared values use `SharedPreferences`
- protected values use `FlutterSecureStorage`

In general:

- primitives are stored natively when possible
- secure values are stored as strings
- custom values are serialized to strings

## Testing

Reset the singleton between tests:

```dart
setUp(() async {
  PreferencesService.resetForTesting();
  SharedPreferences.setMockInitialValues({});
  await PreferencesService.initialize();
});
```

## Example App

A runnable example is included in this repository:

- `example/lib/app_prefs.dart`
- `example/lib/main.dart`

It demonstrates:

- grouped preferences
- secure storage
- enum and model serialization
- reactive updates
- write policies

## When to use typed_prefs

This package is a good fit if you want:

- a clean replacement for scattered `SharedPreferences` string keys
- typed access to both secure and non-secure preferences
- a scalable preference layer for medium or large Flutter apps
- generated APIs that are easy for teams to read and maintain

If your app only stores one or two simple values, plain `SharedPreferences` may be enough. For anything beyond that, `typed_prefs` gives you structure without much overhead.
