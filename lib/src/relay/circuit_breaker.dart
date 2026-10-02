/// State of a [CircuitBreaker]. Independent state machines are kept per sink.
enum CircuitState { closed, open, halfOpen }

/// Thrown when a closed/open [CircuitBreaker] rejects a call.
class CircuitOpenException implements Exception {
  final String message;
  const CircuitOpenException(this.message);
  @override
  String toString() => 'CircuitOpenException: $message';
}

/// Per-sink circuit breaker. Tracks consecutive failures; opens at
/// [failureThreshold]. After [resetTimeout] the next call tries in
/// [halfOpen]: success closes, failure reopens.
class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  final DateTime Function() _now;

  CircuitState _state = CircuitState.closed;
  int _consecutiveFailures = 0;
  DateTime _openedAt = DateTime.fromMillisecondsSinceEpoch(0);

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  CircuitState get state => _state;
  int get failureCount => _consecutiveFailures;

  Future<T> call<T>(Future<T> Function() op) async {
    if (_state == CircuitState.open) {
      if (_now().difference(_openedAt) >= resetTimeout) {
        _state = CircuitState.halfOpen;
      } else {
        throw CircuitOpenException('circuit open');
      }
    }
    try {
      final result = await op();
      _onSuccess();
      return result;
    } catch (e) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _consecutiveFailures = 0;
    _state = CircuitState.closed;
  }

  void _onFailure() {
    _consecutiveFailures++;
    if (_state == CircuitState.halfOpen ||
        _consecutiveFailures >= failureThreshold) {
      _state = CircuitState.open;
      _openedAt = _now();
    }
  }
}
