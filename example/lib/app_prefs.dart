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

  @Pref(serializer: DateTimeSerializer)
  static const lastSyncAt = PrefKey<DateTime>();
}
