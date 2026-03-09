## 1.0.0

- Stabilized API, no breaking changes since 0.1.0.
- Updated to null safety.
- Updated dependencies to latest versions.

## 0.1.0

- Added typed runtime API for SharedPreferences and flutter_secure_storage.
- Added `PreferenceKey<T>`, `PreferencesStorageRouter` and `PreferencesService`.
- `PreferencesService` is now a singleton — initialize once with
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
