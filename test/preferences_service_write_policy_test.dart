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

  test('denied policy prevents write', () async {
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

  test('missing registered policy throws state error', () async {
    final shared = await SharedPreferences.getInstance();
    final service = await PreferencesService.initialize(
      sharedPreferences: shared,
    );

    await expectLater(
      service.set(guardedStringKey, 'secret'),
      throwsA(isA<StateError>()),
    );
  });

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
}
