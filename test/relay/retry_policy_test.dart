import 'package:dio_curl_interceptor/src/relay/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('succeeds on first attempt without retries', () async {
    final p = RetryPolicy(
      maxRetries: 3,
      initialDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFraction: 0.0,
    );
    var calls = 0;
    final r = await p.execute<int>(() async {
      calls++;
      return 42;
    }, operationName: 'test');
    expect(r, 42);
    expect(calls, 1);
  });

  test('retries until success within budget', () async {
    final p = RetryPolicy(
      maxRetries: 3,
      initialDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFraction: 0.0,
    );
    var calls = 0;
    final r = await p.execute<int>(() async {
      calls++;
      if (calls < 3) throw StateError('flaky');
      return 7;
    }, operationName: 'test');
    expect(r, 7);
    expect(calls, 3);
  });

  test('throws RetryExhaustedException after max retries', () async {
    final p = RetryPolicy(
      maxRetries: 2,
      initialDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFraction: 0.0,
    );
    await expectLater(
      () => p.execute<int>(() async => throw StateError('always'), operationName: 'test'),
      throwsA(isA<RetryExhaustedException>()),
    );
  });

  test('non-retryable error throws immediately', () async {
    final p = RetryPolicy(
      maxRetries: 5,
      initialDelay: Duration.zero,
      backoffMultiplier: 1.0,
      jitterFraction: 0.0,
      isRetryable: (_) => false,
    );
    var calls = 0;
    await expectLater(
      () => p.execute<int>(() async {
        calls++;
        throw StateError('not retryable');
      }, operationName: 'test'),
      throwsA(isA<StateError>()),
    );
    expect(calls, 1);
  });
}
