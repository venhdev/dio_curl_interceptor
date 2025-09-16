import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

/// A retry policy that implements exponential backoff for handling
/// transient failures in webhook services and other operations.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final Duration? jitter;
  final bool Function(Object)? shouldRetry;
  
  /// Creates a [RetryPolicy] instance.
  ///
  /// [maxRetries] The maximum number of retry attempts.
  /// [initialDelay] The initial delay before the first retry.
  /// [backoffMultiplier] The multiplier for exponential backoff.
  /// [maxDelay] The maximum delay between retries.
  /// [jitter] Optional random jitter to add to delays.
  /// [shouldRetry] Optional function to determine if an error should be retried.
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 1),
    this.jitter,
    this.shouldRetry,
  });
  
  /// Executes an operation with retry logic.
  ///
  /// [operation] The operation to execute.
  /// [operationName] Optional name for logging purposes.
  /// Returns the result of the operation if successful.
  /// Throws the last error if all retries are exhausted.
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;
    Object? lastError;
    
    while (attempt <= maxRetries) {
      try {
        final result = await operation();
        if (attempt > 0) {
          developer.log(
            'Operation ${operationName ?? 'unnamed'} succeeded on attempt ${attempt + 1}',
            name: 'RetryPolicy',
          );
        }
        return result;
      } catch (e) {
        lastError = e;
        attempt++;
        
        if (attempt > maxRetries) {
          developer.log(
            'Max retries exceeded for ${operationName ?? 'unnamed'}: $e',
            name: 'RetryPolicy',
          );
          break;
        }
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry!(e)) {
          developer.log(
            'Error should not be retried for ${operationName ?? 'unnamed'}: $e',
            name: 'RetryPolicy',
          );
          break;
        }
        
        final delayWithJitter = _calculateDelayWithJitter(delay);
        developer.log(
          'Retry attempt $attempt for ${operationName ?? 'unnamed'} after ${delayWithJitter.inMilliseconds}ms: $e',
          name: 'RetryPolicy',
        );
        
        await Future.delayed(delayWithJitter);
        
        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: math.min(
            (delay.inMilliseconds * backoffMultiplier).round(),
            maxDelay.inMilliseconds,
          ),
        );
      }
    }
    
    // Re-throw the last error
    if (lastError is Exception) {
      throw lastError;
    } else {
      throw Exception(lastError.toString());
    }
  }
  
  /// Calculates the delay with optional jitter.
  Duration _calculateDelayWithJitter(Duration baseDelay) {
    if (jitter == null) return baseDelay;
    
    final jitterMs = jitter!.inMilliseconds;
    final randomJitter = math.Random().nextInt(jitterMs * 2) - jitterMs;
    
    return Duration(
      milliseconds: math.max(0, baseDelay.inMilliseconds + randomJitter),
    );
  }
}

/// A specialized retry policy for webhook operations.
class WebhookRetryPolicy extends RetryPolicy {
  /// Creates a [WebhookRetryPolicy] instance optimized for webhook operations.
  const WebhookRetryPolicy({
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    Duration maxDelay = const Duration(minutes: 1),
    Duration? jitter = const Duration(milliseconds: 100),
  }) : super(
          maxRetries: maxRetries,
          initialDelay: initialDelay,
          backoffMultiplier: backoffMultiplier,
          maxDelay: maxDelay,
          jitter: jitter,
          shouldRetry: _shouldRetryWebhookError,
        );
  
  /// Determines if a webhook error should be retried.
  static bool _shouldRetryWebhookError(Object error) {
    // Retry on network errors, timeouts, and 5xx server errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('Connection refused') ||
        error.toString().contains('Connection reset') ||
        error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503') ||
        error.toString().contains('504')) {
      return true;
    }
    
    // Don't retry on 4xx client errors (except 429 rate limiting)
    if (error.toString().contains('400') ||
        error.toString().contains('401') ||
        error.toString().contains('403') ||
        error.toString().contains('404')) {
      return false;
    }
    
    // Retry on 429 rate limiting
    if (error.toString().contains('429')) {
      return true;
    }
    
    // Default to retry for unknown errors
    return true;
  }
}

/// A retry policy that never retries (useful for testing or when retries are disabled).
class NoRetryPolicy extends RetryPolicy {
  /// Creates a [NoRetryPolicy] instance that never retries.
  const NoRetryPolicy() : super(maxRetries: 0);
}
