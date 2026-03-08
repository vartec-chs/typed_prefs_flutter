import 'package:flutter/material.dart';
import 'package:typed_prefs/typed_prefs.dart';

part 'app_prefs.g.dart';

class DateTimeSerializer extends PrefSerializer<DateTime> {
  const DateTimeSerializer();

  @override
  DateTime decode(String value) => DateTime.parse(value);

  @override
  String encode(DateTime value) => value.toIso8601String();
}

// ── sub-group: auth ─────────────────────────────────────────────────────────

@Prefs(protected: true)
class AuthPrefs {
  static const vaultKey = PrefKey<String>();

  @Pref(defaultValue: false)
  static const biometricsEnabled = PrefKey<bool>();

  @Pref(serializer: DateTimeSerializer)
  static const lastSyncAt = PrefKey<DateTime>();
}

// ── sub-group: settings ──────────────────────────────────────────────────────

@Prefs()
class SettingsPrefs {
  @Pref(defaultValue: ThemeMode.system)
  static const themeMode = PrefKey<ThemeMode>();

  @Pref(defaultValue: <String>['ru', 'en'])
  static const preferredLocales = PrefKey<List<String>>();
}

// ── root accessor that composes both sub-groups ──────────────────────────────
// Usage:  service.appPrefs.auth.getVaultKey()
//         service.appPrefs.settings.getThemeMode()

@Prefs()
class AppPrefs {
  static const auth = PrefGroupKey<AuthPrefs>();
  static const settings = PrefGroupKey<SettingsPrefs>();
}
