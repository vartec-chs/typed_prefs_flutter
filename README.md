# typed_prefs

typed_prefs is a Flutter package that gives you a typed preferences layer on top
of SharedPreferences and flutter_secure_storage, plus code generation for
ergonomic accessors.

It solves four problems at once:

- typed keys instead of stringly-typed storage calls;
- automatic routing between shared and secure storage;
- serializers for complex values;
- generated APIs via build_runner and source_gen.

## Features

- PreferenceKey<T> for manually declared keys.
- PreferencesService for get, set, remove, contains and reactive watch.
- PreferencesStorageRouter that routes secure keys to flutter_secure_storage and
  shared keys to SharedPreferences.
- Built-in serializers for DateTime, Duration, Uri, BigInt, List<String>,
  Map<String, String> and enums.
- Custom serializers via PrefSerializer<T>.
- Code generation with @Prefs, @Pref and PrefKey<T> declarations.
- Generated typed accessors such as getThemeMode(), setThemeMode(),
  watchThemeMode() and prefs.themeMode.get().

## Installation

Add the package and generator tooling:

```yaml
dependencies:
	typed_prefs: ^0.0.1

dev_dependencies:
	build_runner: ^2.12.2
```

## Manual API

```dart
import 'package:typed_prefs/typed_prefs.dart';

class AppPreferenceKeys {
	static const themeMode = PreferenceKey<String>(
		key: 'theme_mode',
		storage: PreferenceStorage.shared,
		defaultValue: 'system',
		description: 'Theme mode of the application',
	);

	static const biometricsEnabled = PreferenceKey<bool>(
		key: 'biometrics_enabled',
		storage: PreferenceStorage.secure,
		defaultValue: false,
		description: 'Whether biometric auth is enabled',
	);
}

final service = await PreferencesService.create();

await service.set(AppPreferenceKeys.themeMode, 'dark');
final theme = await service.get(AppPreferenceKeys.themeMode);

service.watch(AppPreferenceKeys.themeMode).listen((value) {
	print('Theme changed: $value');
});
```

## Code Generation

Declare your preferences in a single class:

```dart
import 'package:flutter/material.dart';
import 'package:typed_prefs/typed_prefs.dart';

part 'app_prefs.g.dart';

@Prefs()
class AppPrefs {
	@Pref(defaultValue: ThemeMode.system)
	static const themeMode = PrefKey<ThemeMode>();

	@Pref(protected: true)
	static const vaultKey = PrefKey<String>();

	@Pref(defaultValue: false, protected: true)
	static const biometricsEnabled = PrefKey<bool>();

	@Pref(defaultValue: <String>['ru', 'en'])
	static const preferredLocales = PrefKey<List<String>>();
}
```

Run generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated API:

```dart
final service = await PreferencesService.create();
final prefs = service.appPrefs;

final themeMode = await prefs.getThemeMode();
await prefs.setThemeMode(ThemeMode.dark);

final vaultKey = await prefs.getVaultKey();
await prefs.vaultKey.set('super-secret');

prefs.watchThemeMode().listen((mode) {
	print('Theme mode updated: $mode');
});
```

## Serializers

Create custom serializers for complex objects:

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

Built-in serializers are selected automatically for:

- DateTime
- Duration
- Uri
- BigInt
- List<String>
- Map<String, String>
- Enum values

## Reactive Updates

Every key can be observed through PreferencesService.watch or generated watchX
methods:

```dart
service.watch(AppPreferenceKeys.themeMode).listen((value) {
	print('manual watch => $value');
});

service.appPrefs.watchThemeMode().listen((value) {
	print('generated watch => $value');
});
```

The stream emits the current value immediately and then emits all writes and
removals performed through the same PreferencesService instance.

## Storage Model

- PreferenceStorage.shared uses SharedPreferences.
- PreferenceStorage.secure uses flutter_secure_storage.
- Primitive shared values are written natively when possible.
- Secure values are persisted as strings, using serializers when needed.

## Example

A runnable Flutter example is available in
[example/lib/main.dart](example/lib/main.dart) and
[example/lib/app_prefs.dart](example/lib/app_prefs.dart).

## Publishing

The package structure, code generation and documentation are ready for
publication workflow, but actual publication to pub.dev must be performed from
the owner account with valid package metadata and credentials.
