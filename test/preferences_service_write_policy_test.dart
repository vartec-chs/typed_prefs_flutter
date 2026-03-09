import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typed_prefs/typed_prefs.dart';

class _RecordingPolicy implements PreferenceWritePolicy {
  int callCount = 0;
  PreferenceWriteOperation? lastOperation;
  Object? lastCurrentValue;
  Object? lastNextValue;
  String? lastKey;

  @override
  Future<void> authorize<T>(PreferenceWriteRequest<T> request) async {
    callCount += 1;
    lastOperation = request.operation;
    lastCurrentValue = request.currentValue;
    lastNextValue = request.nextValue;
    lastKey = request.key.key;
  }
}

class _DenyingPolicy implements PreferenceWritePolicy {
  @override
  Future<void> authorize<T>(PreferenceWriteRequest<T> request) {
    throw const PreferenceWriteDeniedException('blocked');
  }
}

class _RecordingErrorCallback {
  int callCount = 0;
  PreferenceWriteFailure? lastFailure;

  Future<void> call(PreferenceWriteFailure failure) async {
    callCount += 1;
    lastFailure = failure;
  }
}

void main() {
  const guardedStringKey = PreferenceKey<String>(
    key: 'guarded_string',
    storage: PreferenceStorage.shared,
    writePolicy: 'auth',
  );
  const guardedBoolKey = PreferenceKey<bool>(
    key: 'guarded_bool',
    storage: PreferenceStorage.shared,
    writePolicy: 'auth',
    defaultValue: false,
  );

  setUp(() async {
    PreferencesService.resetForTesting();
    SharedPreferences.setMockInitialValues({});
  });

  test('set uses registered write policy and persists value', () async {
    final policy = _RecordingPolicy();
    final shared = await SharedPreferences.getInstance();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
      writePolicies: {'auth': policy},
    );

    await service.set(guardedStringKey, 'secret');

    expect(await service.get(guardedStringKey), 'secret');
    expect(policy.callCount, 1);
    expect(policy.lastKey, 'guarded_string');
    expect(policy.lastOperation, PreferenceWriteOperation.set);
    expect(policy.lastCurrentValue, isNull);
    expect(policy.lastNextValue, 'secret');
  });

  test(
    'remove uses registered write policy with effective next value',
    () async {
      final policy = _RecordingPolicy();
      final shared = await SharedPreferences.getInstance();
      final service = await PreferencesService.initialize(
        sharedPreferences: shared,
        writePolicies: {'auth': policy},
      );

      await service.set(guardedBoolKey, true);
      await service.remove(guardedBoolKey);

      expect(await service.get(guardedBoolKey), false);
      expect(policy.callCount, 2);
      expect(policy.lastOperation, PreferenceWriteOperation.remove);
      expect(policy.lastCurrentValue, true);
      expect(policy.lastNextValue, false);
    },
  );

  test('denied policy still throws without callback', () async {
    final shared = await SharedPreferences.getInstance();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
      writePolicies: {'auth': _DenyingPolicy()},
    );

    await expectLater(
      service.set(guardedStringKey, 'secret'),
      throwsA(isA<PreferenceWriteDeniedException>()),
    );
    expect(await service.get(guardedStringKey), isNull);
  });

  test('set callback receives policy error and suppresses throw', () async {
    final shared = await SharedPreferences.getInstance();
    final callback = _RecordingErrorCallback();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
      writePolicies: {'auth': _DenyingPolicy()},
    );

    await service.set(guardedStringKey, 'secret', onWriteError: callback.call);

    expect(callback.callCount, 1);
    expect(callback.lastFailure?.policyName, 'auth');
    expect(callback.lastFailure?.key, 'guarded_string');
    expect(callback.lastFailure?.operation, PreferenceWriteOperation.set);
    expect(callback.lastFailure?.currentValue, isNull);
    expect(callback.lastFailure?.nextValue, 'secret');
    expect(callback.lastFailure?.error, isA<PreferenceWriteDeniedException>());
    expect(await service.get(guardedStringKey), isNull);
  });

  test('remove callback receives policy error and suppresses throw', () async {
    final shared = await SharedPreferences.getInstance();
    final callback = _RecordingErrorCallback();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
      writePolicies: {'auth': _DenyingPolicy()},
    );

    await service.remove(guardedBoolKey, onWriteError: callback.call);

    expect(callback.callCount, 1);
    expect(callback.lastFailure?.operation, PreferenceWriteOperation.remove);
    expect(callback.lastFailure?.nextValue, false);
    expect(callback.lastFailure?.error, isA<PreferenceWriteDeniedException>());
  });

  test('missing registered policy callback suppresses throw', () async {
    final shared = await SharedPreferences.getInstance();
    final callback = _RecordingErrorCallback();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
    );

    await service.set(guardedStringKey, 'secret', onWriteError: callback.call);

    expect(callback.callCount, 1);
    expect(callback.lastFailure?.policyName, 'auth');
    expect(callback.lastFailure?.error, isA<StateError>());
    expect(await service.get(guardedStringKey), isNull);
  });

  test(
    'missing registered policy throws state error without callback',
    () async {
      final shared = await SharedPreferences.getInstance();
      final service = await PreferencesService.initialize(
        sharedPreferences: shared,
      );

      await expectLater(
        service.set(guardedStringKey, 'secret'),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('policies can be registered after initialization', () async {
    final shared = await SharedPreferences.getInstance();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
    );
    final policy = _RecordingPolicy();

    service.registerWritePolicy('auth', policy);
    await service.set(guardedStringKey, 'late');

    expect(await service.get(guardedStringKey), 'late');
    expect(policy.callCount, 1);
  });

  test('typed accessor forwards write callback', () async {
    final shared = await SharedPreferences.getInstance();
    final callback = _RecordingErrorCallback();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
      writePolicies: {'auth': _DenyingPolicy()},
    );
    final accessor = TypedPrefAccessor<String>(service, guardedStringKey);

    await accessor.set('secret', onWriteError: callback.call);

    expect(callback.callCount, 1);
    expect(await service.get(guardedStringKey), isNull);
  });
}
