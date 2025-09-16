import 'dart:async';
import 'dart:developer' as developer;

/// Utility functions for implementing fire-and-forget patterns.
class FireAndForget {
  /// Executes an operation without waiting for its completion.
  ///
  /// [operation] The operation to execute.
  /// [operationName] Optional name for logging purposes.
  /// [onError] Optional error handler.
  static void execute(
    Future<void> Function() operation, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    unawaited(_executeWithErrorHandling(
      operation,
      operationName: operationName,
      onError: onError,
    ));
  }
  
  /// Executes an operation without waiting for its completion and returns a future.
  ///
  /// [operation] The operation to execute.
  /// [operationName] Optional name for logging purposes.
  /// [onError] Optional error handler.
  /// Returns a future that completes when the operation finishes.
  static Future<void> executeAsync(
    Future<void> Function() operation, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return _executeWithErrorHandling(
      operation,
      operationName: operationName,
      onError: onError,
    );
  }
  
  /// Executes multiple operations in parallel without waiting for completion.
  ///
  /// [operations] List of operations to execute.
  /// [operationName] Optional name for logging purposes.
  /// [onError] Optional error handler.
  static void executeAll(
    List<Future<void> Function()> operations, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    for (int i = 0; i < operations.length; i++) {
      execute(
        operations[i],
        operationName: '${operationName ?? 'unnamed'}_$i',
        onError: onError,
      );
    }
  }
  
  /// Executes multiple operations in parallel and returns a future that completes
  /// when all operations finish.
  ///
  /// [operations] List of operations to execute.
  /// [operationName] Optional name for logging purposes.
  /// [onError] Optional error handler.
  /// Returns a future that completes when all operations finish.
  static Future<void> executeAllAsync(
    List<Future<void> Function()> operations, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final futures = operations.asMap().entries.map((entry) {
      final index = entry.key;
      final operation = entry.value;
      return _executeWithErrorHandling(
        operation,
        operationName: '${operationName ?? 'unnamed'}_$index',
        onError: onError,
      );
    });
    
    return Future.wait(futures);
  }
  
  /// Executes an operation with error handling.
  static Future<void> _executeWithErrorHandling(
    Future<void> Function() operation, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    try {
      await operation();
      developer.log(
        'Fire-and-forget operation completed: ${operationName ?? 'unnamed'}',
        name: 'FireAndForget',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Fire-and-forget operation failed: ${operationName ?? 'unnamed'}: $error',
        name: 'FireAndForget',
        error: error,
        stackTrace: stackTrace,
      );
      
      if (onError != null) {
        try {
          onError(error, stackTrace);
        } catch (e) {
          developer.log(
            'Error handler failed: $e',
            name: 'FireAndForget',
            error: e,
          );
        }
      }
    }
  }
}

/// A specialized fire-and-forget handler for webhook operations.
class WebhookFireAndForget {
  /// Executes a webhook operation without waiting for completion.
  ///
  /// [webhookOperation] The webhook operation to execute.
  /// [webhookUrl] The webhook URL for logging purposes.
  /// [onError] Optional error handler.
  static void executeWebhook(
    Future<void> Function() webhookOperation, {
    String? webhookUrl,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    FireAndForget.execute(
      webhookOperation,
      operationName: 'webhook_${webhookUrl ?? 'unknown'}',
      onError: onError,
    );
  }
  
  /// Executes multiple webhook operations in parallel without waiting for completion.
  ///
  /// [webhookOperations] List of webhook operations to execute.
  /// [onError] Optional error handler.
  static void executeWebhooks(
    List<Future<void> Function()> webhookOperations, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    FireAndForget.executeAll(
      webhookOperations,
      operationName: 'webhooks',
      onError: onError,
    );
  }
  
  /// Executes multiple webhook operations in parallel and returns a future
  /// that completes when all operations finish.
  ///
  /// [webhookOperations] List of webhook operations to execute.
  /// [onError] Optional error handler.
  /// Returns a future that completes when all operations finish.
  static Future<void> executeWebhooksAsync(
    List<Future<void> Function()> webhookOperations, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    return FireAndForget.executeAllAsync(
      webhookOperations,
      operationName: 'webhooks',
      onError: onError,
    );
  }
}

/// A fire-and-forget handler that provides additional context and metrics.
class ContextualFireAndForget {
  final String _context;
  final Map<String, dynamic> _metrics = {};
  
  /// Creates a [ContextualFireAndForget] instance.
  ///
  /// [context] The context name for this handler.
  ContextualFireAndForget(this._context);
  
  /// Executes an operation with context-specific fire-and-forget handling.
  ///
  /// [operation] The operation to execute.
  /// [operationName] Optional name for the operation.
  /// [onError] Optional error handler.
  static void execute(
    Future<void> Function() operation, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    FireAndForget.execute(
      operation,
      operationName: operationName,
      onError: onError,
    );
  }
  
  /// Executes an operation with context-specific fire-and-forget handling.
  ///
  /// [operation] The operation to execute.
  /// [operationName] Optional name for the operation.
  /// [onError] Optional error handler.
  void executeWithContext(
    Future<void> Function() operation, {
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    final startTime = DateTime.now();
    _metrics['${_context}_${operationName ?? 'unknown'}_started'] = 
        (_metrics['${_context}_${operationName ?? 'unknown'}_started'] ?? 0) + 1;
    
    FireAndForget.execute(
      () async {
        await operation();
        final duration = DateTime.now().difference(startTime);
        _metrics['${_context}_${operationName ?? 'unknown'}_completed'] = 
            (_metrics['${_context}_${operationName ?? 'unknown'}_completed'] ?? 0) + 1;
        _metrics['${_context}_${operationName ?? 'unknown'}_total_duration'] = 
            (_metrics['${_context}_${operationName ?? 'unknown'}_total_duration'] ?? 0) + duration.inMilliseconds;
      },
      operationName: '${_context}_${operationName ?? 'unknown'}',
      onError: (error, stackTrace) {
        final duration = DateTime.now().difference(startTime);
        _metrics['${_context}_${operationName ?? 'unknown'}_failed'] = 
            (_metrics['${_context}_${operationName ?? 'unknown'}_failed'] ?? 0) + 1;
        _metrics['${_context}_${operationName ?? 'unknown'}_total_duration'] = 
            (_metrics['${_context}_${operationName ?? 'unknown'}_total_duration'] ?? 0) + duration.inMilliseconds;
        
        if (onError != null) {
          onError(error, stackTrace);
        }
      },
    );
  }
  
  /// Gets the current metrics for this handler.
  Map<String, dynamic> getMetrics() => Map.from(_metrics);
  
  /// Resets the metrics.
  void resetMetrics() => _metrics.clear();
}

/// A fire-and-forget handler that provides rate limiting.
class RateLimitedFireAndForget {
  final Map<String, List<DateTime>> _requestTimes = {};
  final Duration _window;
  final int _maxRequests;
  
  /// Creates a [RateLimitedFireAndForget] instance.
  ///
  /// [window] The time window for rate limiting.
  /// [maxRequests] The maximum number of requests allowed in the window.
  RateLimitedFireAndForget({
    Duration window = const Duration(minutes: 1),
    int maxRequests = 60,
  }) : _window = window,
       _maxRequests = maxRequests;
  
  /// Executes an operation with rate limiting.
  ///
  /// [operation] The operation to execute.
  /// [key] The rate limit key.
  /// [operationName] Optional name for logging purposes.
  /// [onError] Optional error handler.
  static void execute(
    Future<void> Function() operation, {
    String? key,
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    FireAndForget.execute(
      operation,
      operationName: operationName,
      onError: onError,
    );
  }
  
  /// Executes an operation with rate limiting.
  ///
  /// [operation] The operation to execute.
  /// [key] The rate limit key.
  /// [operationName] Optional name for logging purposes.
  /// [onError] Optional error handler.
  void executeWithRateLimit(
    Future<void> Function() operation, {
    required String key,
    String? operationName,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    if (!_isAllowed(key)) {
      developer.log(
        'Rate limit exceeded for key: $key, skipping operation: ${operationName ?? 'unnamed'}',
        name: 'RateLimitedFireAndForget',
      );
      return;
    }
    
    _recordRequest(key);
    
    FireAndForget.execute(
      operation,
      operationName: operationName,
      onError: onError,
    );
  }
  
  /// Checks if a request is allowed based on rate limiting.
  bool _isAllowed(String key) {
    final now = DateTime.now();
    final requests = _requestTimes[key] ?? [];
    
    // Remove old requests outside the window
    final validRequests = requests.where((request) => 
        now.difference(request) <= _window).toList();
    
    _requestTimes[key] = validRequests;
    
    return validRequests.length < _maxRequests;
  }
  
  /// Records a request for rate limiting purposes.
  void _recordRequest(String key) {
    final now = DateTime.now();
    final requests = _requestTimes[key] ?? [];
    requests.add(now);
    _requestTimes[key] = requests;
  }
  
  /// Gets the number of requests in the current window.
  int getRequestCount(String key) {
    final now = DateTime.now();
    final requests = _requestTimes[key] ?? [];
    
    // Remove old requests outside the window
    final validRequests = requests.where((request) => 
        now.difference(request) <= _window).toList();
    
    _requestTimes[key] = validRequests;
    
    return validRequests.length;
  }
  
  /// Clears all rate limit data.
  void clear() {
    _requestTimes.clear();
  }
}
