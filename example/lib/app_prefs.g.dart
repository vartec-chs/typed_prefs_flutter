// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_prefs.dart';

// **************************************************************************
// PrefsGenerator
// **************************************************************************

abstract final class AuthPrefsKeys {
  static const vaultKey = PreferenceKey<String>(
    key: 'vault_key',
    storage: PreferenceStorage.secure,
  );
  static const biometricsEnabled = PreferenceKey<bool>(
    key: 'biometrics_enabled',
    storage: PreferenceStorage.secure,
    defaultValue: false,
  );
  static const lastSyncAt = PreferenceKey<DateTime>(
    key: 'last_sync_at',
    storage: PreferenceStorage.secure,
    serializer: DateTimeSerializer(),
  );
}

class AuthPrefsStore {
  final PreferencesService _service;

  const AuthPrefsStore(this._service);

  TypedPrefAccessor<String> get vaultKey =>
      TypedPrefAccessor<String>(_service, AuthPrefsKeys.vaultKey);

  Future<String?> getVaultKey() => vaultKey.get();
  Future<void> setVaultKey(String value) => vaultKey.set(value);
  Future<void> removeVaultKey() => vaultKey.remove();
  Stream<String?> watchVaultKey() => vaultKey.watch();

  TypedPrefAccessor<bool> get biometricsEnabled =>
      TypedPrefAccessor<bool>(_service, AuthPrefsKeys.biometricsEnabled);

  Future<bool> getBiometricsEnabled() async =>
      (await biometricsEnabled.get()) ?? false;
  Future<void> setBiometricsEnabled(bool value) => biometricsEnabled.set(value);
  Future<void> removeBiometricsEnabled() => biometricsEnabled.remove();
  Stream<bool> watchBiometricsEnabled() =>
      biometricsEnabled.watch().map((value) => value ?? false);

  TypedPrefAccessor<DateTime> get lastSyncAt =>
      TypedPrefAccessor<DateTime>(_service, AuthPrefsKeys.lastSyncAt);

  Future<DateTime?> getLastSyncAt() => lastSyncAt.get();
  Future<void> setLastSyncAt(DateTime value) => lastSyncAt.set(value);
  Future<void> removeLastSyncAt() => lastSyncAt.remove();
  Stream<DateTime?> watchLastSyncAt() => lastSyncAt.watch();
}

extension AuthPrefsTypedPrefsExtension on PreferencesService {
  AuthPrefsStore get authPrefs => AuthPrefsStore(this);
}

abstract final class SettingsPrefsKeys {
  static const themeMode = PreferenceKey<ThemeMode>(
    key: 'theme_mode',
    storage: PreferenceStorage.shared,
    defaultValue: ThemeMode.system,
    serializer: EnumPrefSerializer<ThemeMode>(ThemeMode.values),
  );
  static const preferredLocales = PreferenceKey<List<String>>(
    key: 'preferred_locales',
    storage: PreferenceStorage.shared,
    defaultValue: ['ru', 'en'],
    serializer: StringListPrefSerializer(),
  );
}

class SettingsPrefsStore {
  final PreferencesService _service;

  const SettingsPrefsStore(this._service);

  TypedPrefAccessor<ThemeMode> get themeMode =>
      TypedPrefAccessor<ThemeMode>(_service, SettingsPrefsKeys.themeMode);

  Future<ThemeMode> getThemeMode() async =>
      (await themeMode.get()) ?? ThemeMode.system;
  Future<void> setThemeMode(ThemeMode value) => themeMode.set(value);
  Future<void> removeThemeMode() => themeMode.remove();
  Stream<ThemeMode> watchThemeMode() =>
      themeMode.watch().map((value) => value ?? ThemeMode.system);

  TypedPrefAccessor<List<String>> get preferredLocales =>
      TypedPrefAccessor<List<String>>(
        _service,
        SettingsPrefsKeys.preferredLocales,
      );

  Future<List<String>> getPreferredLocales() async =>
      (await preferredLocales.get()) ?? ['ru', 'en'];
  Future<void> setPreferredLocales(List<String> value) =>
      preferredLocales.set(value);
  Future<void> removePreferredLocales() => preferredLocales.remove();
  Stream<List<String>> watchPreferredLocales() =>
      preferredLocales.watch().map((value) => value ?? ['ru', 'en']);
}

extension SettingsPrefsTypedPrefsExtension on PreferencesService {
  SettingsPrefsStore get settingsPrefs => SettingsPrefsStore(this);
}

class AppPrefsStore {
  final PreferencesService _service;

  const AppPrefsStore(this._service);

  AuthPrefsStore get auth => AuthPrefsStore(_service);

  SettingsPrefsStore get settings => SettingsPrefsStore(_service);
}

extension AppPrefsTypedPrefsExtension on PreferencesService {
  AppPrefsStore get appPrefs => AppPrefsStore(this);
}
