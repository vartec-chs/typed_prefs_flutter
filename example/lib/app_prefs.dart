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
  @Pref(defaultValue: ThemeMode.system, serializer: EnumPrefSerializer)
  static const themeMode = PrefKey<ThemeMode>();

  @Pref(defaultValue: <String>['ru', 'en'])
  static const preferredLocales = PrefKey<List<String>>();
}

// ── custom model stored via JsonPrefSerializer ───────────────────────────────

class UserProfile {
  final String name;
  final int age;

  const UserProfile({required this.name, required this.age});

  factory UserProfile.fromJson(Object? json) {
    final map = json as Map<String, dynamic>;
    return UserProfile(name: map['name'] as String, age: map['age'] as int);
  }

  Map<String, dynamic> toJson() => {'name': name, 'age': age};
}

class UserProfileSerializer extends PrefSerializer<UserProfile> {
  const UserProfileSerializer();

  static final _json = JsonPrefSerializer<UserProfile>(
    fromJson: UserProfile.fromJson,
    toJson: (v) => v.toJson(),
  );

  @override
  UserProfile decode(String value) => _json.decode(value);

  @override
  String encode(UserProfile value) => _json.encode(value);
}

// ── root accessor that composes both sub-groups ──────────────────────────────
// Usage:  service.appPrefs.auth.getVaultKey()
//         service.appPrefs.settings.getThemeMode()

@Prefs()
class AppPrefs {
  static const auth = PrefGroupKey<AuthPrefs>();
  static const settings = PrefGroupKey<SettingsPrefs>();

  @Pref(serializer: UserProfileSerializer)
  static const currentUser = PrefKey<UserProfile>();
}
