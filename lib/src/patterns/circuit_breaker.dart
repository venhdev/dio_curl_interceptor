import 'dart:developer' as developer;

/// Circuit breaker for preventing cascading failures.
class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  /// Creates a [CircuitBreaker] instance.
  ///
  /// [failureThreshold] The number of consecutive failures before opening the circuit.
  /// [resetTimeout] The time to wait before attempting to reset the circuit.
  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 1),
  });

  /// Executes an operation with circuit breaker protection.
  ///
  /// [operation] The operation to execute.
  /// Returns the result of the operation if successful.
  /// Throws [CircuitBreakerOpenException] if the circuit is open.
  Future<T> call<T>(Future<T> Function() operation) async {
    if (_isOpen && _shouldAttemptReset()) {
      _isOpen = false;
      developer.log('Circuit breaker attempting reset', name: 'CircuitBreaker');
    }

    if (_isOpen) {
      throw CircuitBreakerOpenException('Circuit breaker is open');
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  /// Handles successful operation execution.
  void _onSuccess() {
    _failureCount = 0;
  }

  /// Handles failed operation execution.
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      developer.log(
        'Circuit breaker opened after $failureThreshold failures',
        name: 'CircuitBreaker',
      );
    }
  }

  /// Determines if the circuit should attempt a reset.
  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
        DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  /// Gets the current state of the circuit breaker.
  bool get isOpen => _isOpen;

  /// Gets the current failure count.
  int get failureCount => _failureCount;

  /// Resets the circuit breaker to closed state.
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _isOpen = false;
    developer.log('Circuit breaker manually reset', name: 'CircuitBreaker');
  }
}

/// Exception thrown when a circuit breaker is open.
class CircuitBreakerOpenException implements Exception {
  final String message;

  const CircuitBreakerOpenException(this.message);

  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
