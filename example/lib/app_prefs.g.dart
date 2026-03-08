// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_prefs.dart';

// **************************************************************************
// PrefsGenerator
// **************************************************************************

abstract final class AppPrefsKeys {
  static const themeMode = PreferenceKey<ThemeMode>(
    key: 'theme_mode',
    storage: PreferenceStorage.shared,
    defaultValue: ThemeMode.system,
    serializer: EnumPrefSerializer<ThemeMode>(ThemeMode.values),
  );
  static const vaultKey = PreferenceKey<String>(
    key: 'vault_key',
    storage: PreferenceStorage.secure,
  );
  static const biometricsEnabled = PreferenceKey<bool>(
    key: 'biometrics_enabled',
    storage: PreferenceStorage.secure,
    defaultValue: false,
  );
  static const preferredLocales = PreferenceKey<List<String>>(
    key: 'preferred_locales',
    storage: PreferenceStorage.shared,
    defaultValue: ['ru', 'en'],
    serializer: StringListPrefSerializer(),
  );
  static const lastSyncAt = PreferenceKey<DateTime>(
    key: 'last_sync_at',
    storage: PreferenceStorage.shared,
    serializer: DateTimeSerializer(),
  );
}

class AppPrefsStore {
  final PreferencesService _service;

  const AppPrefsStore(this._service);

  TypedPrefAccessor<ThemeMode> get themeMode =>
      TypedPrefAccessor<ThemeMode>(_service, AppPrefsKeys.themeMode);

  Future<ThemeMode> getThemeMode() =>
      themeMode.get().then((value) => value as ThemeMode);
  Future<void> setThemeMode(ThemeMode value) => themeMode.set(value);
  Future<void> removeThemeMode() => themeMode.remove();
  Stream<ThemeMode> watchThemeMode() =>
      themeMode.watch().where((value) => value != null).cast<ThemeMode>();

  TypedPrefAccessor<String> get vaultKey =>
      TypedPrefAccessor<String>(_service, AppPrefsKeys.vaultKey);

  Future<String?> getVaultKey() => vaultKey.get();
  Future<void> setVaultKey(String value) => vaultKey.set(value);
  Future<void> removeVaultKey() => vaultKey.remove();
  Stream<String?> watchVaultKey() => vaultKey.watch();

  TypedPrefAccessor<bool> get biometricsEnabled =>
      TypedPrefAccessor<bool>(_service, AppPrefsKeys.biometricsEnabled);

  Future<bool> getBiometricsEnabled() =>
      biometricsEnabled.get().then((value) => value as bool);
  Future<void> setBiometricsEnabled(bool value) => biometricsEnabled.set(value);
  Future<void> removeBiometricsEnabled() => biometricsEnabled.remove();
  Stream<bool> watchBiometricsEnabled() =>
      biometricsEnabled.watch().where((value) => value != null).cast<bool>();

  TypedPrefAccessor<List<String>> get preferredLocales =>
      TypedPrefAccessor<List<String>>(_service, AppPrefsKeys.preferredLocales);

  Future<List<String>> getPreferredLocales() =>
      preferredLocales.get().then((value) => value as List<String>);
  Future<void> setPreferredLocales(List<String> value) =>
      preferredLocales.set(value);
  Future<void> removePreferredLocales() => preferredLocales.remove();
  Stream<List<String>> watchPreferredLocales() => preferredLocales
      .watch()
      .where((value) => value != null)
      .cast<List<String>>();

  TypedPrefAccessor<DateTime> get lastSyncAt =>
      TypedPrefAccessor<DateTime>(_service, AppPrefsKeys.lastSyncAt);

  Future<DateTime?> getLastSyncAt() => lastSyncAt.get();
  Future<void> setLastSyncAt(DateTime value) => lastSyncAt.set(value);
  Future<void> removeLastSyncAt() => lastSyncAt.remove();
  Stream<DateTime?> watchLastSyncAt() => lastSyncAt.watch();
}

extension AppPrefsTypedPrefsExtension on PreferencesService {
  AppPrefsStore get appPrefs => AppPrefsStore(this);
}
