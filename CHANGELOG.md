# Changelog

## 1.1.0

- Released on pub.dev.

## 1.0.4

- Added per-call `onWriteError` callbacks to guarded `set` and `remove`
  operations.
- When `onWriteError` is provided, write-policy failures are delivered to the
  callback and are no longer rethrown for that call.
- Added `PreferenceWriteFailure` and `PreferenceWriteErrorCallback` to expose
  structured write-policy error context.
- Updated generated `setX` and `removeX` methods to include `onWriteError` only
  for fields that use `writePolicy`.

## 1.0.3

- Added named write policies resolved through `PreferencesService` for guarding
  `set` and `remove` operations.
- Added `writePolicy` support to `PreferenceKey`, `@Pref`, and `@Prefs` so
  generated accessors can opt into runtime authorization.

## 1.0.2

- `EnumPrefSerializer` can now be specified explicitly via
  `@Pref(serializer: EnumPrefSerializer)`; the generator automatically injects
  the correct `T.values` argument.
- Custom serializers subclassing `PrefSerializer<T>` with a no-arg const
  constructor work correctly when passed to `@Pref(serializer: ...)`.
- Fixed generator: explicit `serializer:` type argument now properly resolves
  `EnumPrefSerializer` to `EnumPrefSerializer<T>(T.values)` instead of
  `EnumPrefSerializer<dynamic>()`.

## 1.0.1

- Updated dependencies to latest versions.

## 1.0.0

- Stabilized API, no breaking changes since 0.1.0.
- Updated to null safety.
- Updated dependencies to latest versions.

## 0.1.0

- Added typed runtime API for SharedPreferences and flutter_secure_storage.
- Added `PreferenceKey<T>`, `PreferencesStorageRouter` and `PreferencesService`.
- `PreferencesService` is now a singleton - initialize once with
  `PreferencesService.initialize()`, access anywhere via
  `PreferencesService.instance`.
- Added reactive `watch()` support for preference updates.
- Added built-in serializers for `DateTime`, `Duration`, `Uri`, `BigInt`,
  `List<String>`, `Map<String, String>` and all `enum` types.
- Added source_gen / build_runner code generation with `@Prefs` and `@Pref`.
- Added `PrefGroupKey<T>` to compose multiple `@Prefs` classes into a single
  root accessor (`service.appPrefs.auth.getVaultKey()`).
- Added `@Prefs(protected: true)` to force all keys in a class into secure
  storage without repeating `protected: true` on every field.
- Added compile-time validation: duplicate storage keys and unsupported types
  without a serializer are rejected at code-generation time.
- Added `PreferencesService.resetForTesting()` for clean test isolation.

## 0.0.1

- Dev.
