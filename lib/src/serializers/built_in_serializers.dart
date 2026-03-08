import 'dart:convert';

import '../core/pref_serializer.dart';

class DateTimePrefSerializer extends PrefSerializer<DateTime> {
  const DateTimePrefSerializer();

  @override
  DateTime decode(String value) => DateTime.parse(value);

  @override
  String encode(DateTime value) => value.toIso8601String();
}

class DurationPrefSerializer extends PrefSerializer<Duration> {
  const DurationPrefSerializer();

  @override
  Duration decode(String value) => Duration(microseconds: int.parse(value));

  @override
  String encode(Duration value) => value.inMicroseconds.toString();
}

class UriPrefSerializer extends PrefSerializer<Uri> {
  const UriPrefSerializer();

  @override
  Uri decode(String value) => Uri.parse(value);

  @override
  String encode(Uri value) => value.toString();
}

class BigIntPrefSerializer extends PrefSerializer<BigInt> {
  const BigIntPrefSerializer();

  @override
  BigInt decode(String value) => BigInt.parse(value);

  @override
  String encode(BigInt value) => value.toString();
}

class StringListPrefSerializer extends PrefSerializer<List<String>> {
  const StringListPrefSerializer();

  @override
  List<String> decode(String value) =>
      List<String>.from(jsonDecode(value) as List<dynamic>);

  @override
  String encode(List<String> value) => jsonEncode(value);
}

class StringMapPrefSerializer extends PrefSerializer<Map<String, String>> {
  const StringMapPrefSerializer();

  @override
  Map<String, String> decode(String value) =>
      Map<String, String>.from(jsonDecode(value) as Map<String, dynamic>);

  @override
  String encode(Map<String, String> value) => jsonEncode(value);
}

class JsonPrefSerializer<T> extends PrefSerializer<T> {
  final Object? Function(T value) toJson;
  final T Function(Object? json) fromJson;

  const JsonPrefSerializer({required this.toJson, required this.fromJson});

  @override
  T decode(String value) => fromJson(jsonDecode(value));

  @override
  String encode(T value) => jsonEncode(toJson(value));
}

class EnumPrefSerializer<T extends Enum> extends PrefSerializer<T> {
  final List<T> values;

  const EnumPrefSerializer(this.values);

  @override
  T decode(String value) {
    for (final item in values) {
      if (item.name == value) {
        return item;
      }
    }

    throw FormatException('Unknown enum value "$value" for $T');
  }

  @override
  String encode(T value) => value.name;
}
