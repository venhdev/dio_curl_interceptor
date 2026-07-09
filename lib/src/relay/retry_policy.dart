import 'dart:async';
import 'dart:math';

/// Thrown when [RetryPolicy.execute] exhausts its retry budget.
class RetryExhaustedException implements Exception {
  final String message;
  const RetryExhaustedException(this.message);
  @override
  String toString() => 'RetryExhaustedException: $message';
}

/// Retries an operation with exponential backoff and ±jitter, capped by
/// [maxRetries]. Delays are bounded by [maxDelay]. The [isRetryable]
/// predicate decides which errors are retried; defaults to retry-anything.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final double jitterFraction;
  final Duration maxDelay;
  final bool Function(Object)? isRetryable;
  final Random _rng = Random();

  RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.jitterFraction = 0.2,
    this.maxDelay = const Duration(seconds: 30),
    this.isRetryable,
  });

  Future<T> execute<T>(
    Future<T> Function() op, {
    required String operationName,
  }) async {
    final retry = isRetryable ?? (_) => true;
    var attempt = 0;
    while (true) {
      try {
        return await op();
      } catch (e) {
        if (!retry(e)) rethrow;
        if (attempt >= maxRetries) {
          throw RetryExhaustedException(
            '$operationName failed after $maxRetries retries',
          );
        }
        await Future<void>.delayed(_delayFor(attempt));
        attempt++;
      }
    }
  }

  Duration _delayFor(int attempt) {
    final base = initialDelay.inMilliseconds *
        pow(backoffMultiplier, attempt).toDouble();
    final capped = base.clamp(0, maxDelay.inMilliseconds).toInt();
    final jitterRange = (capped * jitterFraction).toInt();
    final jitter =
        jitterRange == 0 ? 0 : _rng.nextInt(2 * jitterRange) - jitterRange;
    final ms = (capped + jitter).clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: ms);
  }
}
