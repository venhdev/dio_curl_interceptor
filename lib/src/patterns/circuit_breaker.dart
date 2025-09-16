import 'dart:developer' as developer;

/// A circuit breaker implementation for preventing cascading failures
/// from webhook services and other external dependencies.
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitState _state = CircuitState.closed;
  
  /// Creates a [CircuitBreaker] instance.
  ///
  /// [failureThreshold] The number of consecutive failures before opening the circuit.
  /// [timeout] The timeout for individual operations.
  /// [resetTimeout] The time to wait before attempting to reset the circuit.
  CircuitBreaker({
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.resetTimeout = const Duration(minutes: 1),
  });
  
  /// Executes an operation with circuit breaker protection.
  ///
  /// [operation] The operation to execute.
  /// Returns the result of the operation if successful.
  /// Throws [CircuitBreakerOpenException] if the circuit is open.
  Future<T> call<T>(Future<T> Function() operation) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
        developer.log('Circuit breaker attempting reset', name: 'CircuitBreaker');
      } else {
        throw CircuitBreakerOpenException('Circuit breaker is open');
      }
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
    _state = CircuitState.closed;
  }
  
  /// Handles failed operation execution.
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
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
  CircuitState get state => _state;
  
  /// Gets the current failure count.
  int get failureCount => _failureCount;
  
  /// Resets the circuit breaker to closed state.
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitState.closed;
    developer.log('Circuit breaker manually reset', name: 'CircuitBreaker');
  }
}

/// The state of a circuit breaker.
enum CircuitState {
  /// Circuit is closed and operations are allowed.
  closed,
  /// Circuit is open and operations are blocked.
  open,
  /// Circuit is half-open and testing if operations should be allowed.
  halfOpen,
}

/// Exception thrown when a circuit breaker is open.
class CircuitBreakerOpenException implements Exception {
  final String message;
  
  const CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}
