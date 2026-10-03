import 'package:dio_curl_interceptor/src/relay/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_clock.dart';

void main() {
  test('starts closed; calls succeed', () async {
    final cb = CircuitBreaker(resetTimeout: const Duration(seconds: 1));
    expect(cb.state, CircuitState.closed);
    final r = await cb.call<int>(() async => 1);
    expect(r, 1);
  });

  test('opens after threshold failures, throws CircuitOpenException', () async {
    final cb = CircuitBreaker(resetTimeout: const Duration(seconds: 1));
    Future<int> boom() async => throw StateError('x');
    for (var i = 0; i < CircuitBreaker.failureThreshold; i++) {
      await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    }
    expect(cb.state, CircuitState.open);
    await expectLater(
      () => cb.call<int>(() async => 1),
      throwsA(isA<CircuitOpenException>()),
    );
  });

  test('half-open success closes the breaker', () async {
    final clock = TestClock(DateTime.utc(2026));
    final cb = CircuitBreaker(
      resetTimeout: const Duration(seconds: 1),
      now: clock.now,
    );
    Future<int> boom() async => throw StateError('x');
    for (var i = 0; i < CircuitBreaker.failureThreshold; i++) {
      await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    }
    expect(cb.state, CircuitState.open);
    clock.elapse(const Duration(seconds: 1));
    final r = await cb.call<int>(() async => 99);
    expect(r, 99);
    expect(cb.state, CircuitState.closed);
  });

  test('half-open failure reopens the breaker', () async {
    final clock = TestClock(DateTime.utc(2026));
    final cb = CircuitBreaker(
      resetTimeout: const Duration(seconds: 1),
      now: clock.now,
    );
    Future<int> boom() async => throw StateError('x');
    for (var i = 0; i < CircuitBreaker.failureThreshold; i++) {
      await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    }
    clock.elapse(const Duration(seconds: 1));
    await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    expect(cb.state, CircuitState.open);
  });
}
