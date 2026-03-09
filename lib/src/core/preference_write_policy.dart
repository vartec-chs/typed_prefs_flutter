import 'dart:async';

import 'preference_key.dart';

enum PreferenceWriteOperation { set, remove }

class PreferenceWriteRequest<T> {
  final PreferenceKey<T> key;
  final PreferenceWriteOperation operation;
  final T? currentValue;
  final T? nextValue;

  const PreferenceWriteRequest({
    required this.key,
    required this.operation,
    required this.currentValue,
    required this.nextValue,
  });

  bool get isRemoval => operation == PreferenceWriteOperation.remove;
}

class PreferenceWriteFailure {
  final String? policyName;
  final String key;
  final PreferenceWriteOperation operation;
  final Object? currentValue;
  final Object? nextValue;
  final Object error;
  final StackTrace stackTrace;

  const PreferenceWriteFailure({
    required this.policyName,
    required this.key,
    required this.operation,
    required this.currentValue,
    required this.nextValue,
    required this.error,
    required this.stackTrace,
  });
}

typedef PreferenceWriteErrorCallback =
    FutureOr<void> Function(PreferenceWriteFailure failure);

abstract interface class PreferenceWritePolicy {
  FutureOr<void> authorize<T>(PreferenceWriteRequest<T> request);
}

class PreferenceWriteDeniedException implements Exception {
  final String message;

  const PreferenceWriteDeniedException(this.message);

  @override
  String toString() => 'PreferenceWriteDeniedException: $message';
}
