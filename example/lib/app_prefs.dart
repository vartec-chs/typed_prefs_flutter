import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:typed_prefs/typed_prefs.dart';

part 'app_prefs.g.dart';

class DateTimeSerializer extends PrefSerializer<DateTime> {
  const DateTimeSerializer();

  @override
  DateTime decode(String value) => DateTime.parse(value);

  @override
  String encode(DateTime value) => value.toIso8601String();
}

// ── write policies ──────────────────────────────────────────────────────────

/// Allows writing only once — throws if the value is already set.
class WriteOncePolicy implements PreferenceWritePolicy {
  const WriteOncePolicy();

  @override
  Future<void> authorize<T>(PreferenceWriteRequest<T> request) async {
    if (request.operation == PreferenceWriteOperation.set &&
        request.currentValue != null) {
      throw const PreferenceWriteDeniedException(
        'This preference can only be written once.',
      );
    }
  }
}

/// Logs every write operation to the console (example audit policy).
class AuditLogPolicy implements PreferenceWritePolicy {
  const AuditLogPolicy();

  @override
  void authorize<T>(PreferenceWriteRequest<T> request) {
    // ignore: avoid_print
    print(
      '[audit] ${request.operation.name} '
      '"${request.key.key}": '
      '${request.currentValue} → ${request.nextValue}',
    );
  }
}

/// Requires successful biometric (or device credential) authentication
/// before any write or remove operation on the protected key.
class BiometricAuthPolicy implements PreferenceWritePolicy {
  final LocalAuthentication _auth;
  final String localizedReason;

  const BiometricAuthPolicy(
    this._auth, {
    this.localizedReason = 'Authenticate to change secure settings',
  });

  @override
  Future<void> authorize<T>(PreferenceWriteRequest<T> request) async {
    final authenticated = await _auth.authenticate(
      localizedReason: localizedReason,
    );
    if (!authenticated) {
      throw const PreferenceWriteDeniedException(
        'Biometric authentication failed or was cancelled.',
      );
    }
  }
}

// ── sub-group: auth ─────────────────────────────────────────────────────────

@Prefs(protected: true)
class AuthPrefs {
  /// Set once — write policy rejects subsequent overwrites.
  @Pref(writePolicy: 'writeOnce')
  static const vaultKey = PrefKey<String>();

  /// Requires biometric confirmation before toggling.
  @Pref(defaultValue: false, writePolicy: 'biometric')
  static const biometricsEnabled = PrefKey<bool>();

  @Pref(serializer: DateTimeSerializer)
  static const lastSyncAt = PrefKey<DateTime>();
}

// ── sub-group: settings ──────────────────────────────────────────────────────

/// All writes to SettingsPrefs are audit-logged via the 'auditLog' policy.
@Prefs(writePolicy: 'auditLog')
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

  /// Requires biometric auth to overwrite the stored profile.
  @Pref(serializer: UserProfileSerializer, writePolicy: 'biometric')
  static const currentUser = PrefKey<UserProfile>();
}
