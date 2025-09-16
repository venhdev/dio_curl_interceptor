import 'dart:developer' as developer;

/// Retry policy with exponential backoff.
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  
  /// Creates a [RetryPolicy] instance.
  ///
  /// [maxRetries] The maximum number of retry attempts.
  /// [initialDelay] The initial delay before the first retry.
  /// [backoffMultiplier] The multiplier for exponential backoff.
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
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
        
        developer.log(
          'Retry attempt $attempt for ${operationName ?? 'unnamed'} after ${delay.inMilliseconds}ms: $e',
          name: 'RetryPolicy',
        );
        
        await Future.delayed(delay);
        
        // Calculate next delay with exponential backoff
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
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
}
