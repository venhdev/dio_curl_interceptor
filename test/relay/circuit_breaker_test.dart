import 'package:dio_curl_interceptor/src/relay/circuit_breaker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starts closed; calls succeed', () async {
    final cb = CircuitBreaker(
      failureThreshold: 3,
      resetTimeout: const Duration(seconds: 1),
    );
    expect(cb.state, CircuitState.closed);
    final r = await cb.call<int>(() async => 1);
    expect(r, 1);
  });

  test('opens after threshold failures, throws CircuitOpenException', () async {
    final cb = CircuitBreaker(
      failureThreshold: 3,
      resetTimeout: const Duration(seconds: 1),
    );
    Future<int> boom() async => throw StateError('x');
    for (var i = 0; i < 3; i++) {
      await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    }
    expect(cb.state, CircuitState.open);
    await expectLater(
      () => cb.call<int>(() async => 1),
      throwsA(isA<CircuitOpenException>()),
    );
  });

  test('half-open success closes the breaker', () async {
    final cb = CircuitBreaker(
      failureThreshold: 2,
      resetTimeout: const Duration(milliseconds: 1),
    );
    Future<int> boom() async => throw StateError('x');
    await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    expect(cb.state, CircuitState.open);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final r = await cb.call<int>(() async => 99);
    expect(r, 99);
    expect(cb.state, CircuitState.closed);
  });

  test('half-open failure reopens the breaker', () async {
    final cb = CircuitBreaker(
      failureThreshold: 2,
      resetTimeout: const Duration(milliseconds: 1),
    );
    Future<int> boom() async => throw StateError('x');
    await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await expectLater(() => cb.call(boom), throwsA(isA<StateError>()));
    expect(cb.state, CircuitState.open);
  });
}
