import 'dart:async';
import 'dart:developer' as developer;

/// Provides error isolation utilities to prevent errors from disrupting
/// the main application flow.
class ErrorIsolator {
  /// Isolates an operation that returns a value, catching any errors
  /// and returning null if an error occurs.
  ///
  /// [operation] The operation to isolate.
  /// [operationName] Optional name for logging purposes.
  /// Returns the result of the operation or null if an error occurs.
  static Future<T?> isolate<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      developer.log(
        'Isolated operation ${operationName ?? 'unnamed'} failed: $e',
        name: 'ErrorIsolator',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Isolates a void operation, catching any errors and logging them.
  ///
  /// [operation] The operation to isolate.
  /// [operationName] Optional name for logging purposes.
  static void isolateVoid(
    Future<void> Function() operation, {
    String? operationName,
  }) {
    unawaited(_isolateVoidInternal(operation, operationName));
  }
  
  static Future<void> _isolateVoidInternal(
    Future<void> Function() operation,
    String? operationName,
  ) async {
    try {
      await operation();
    } catch (e, stackTrace) {
      developer.log(
        'Isolated void operation ${operationName ?? 'unnamed'} failed: $e',
        name: 'ErrorIsolator',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
  
  /// Isolates a synchronous operation that returns a value.
  ///
  /// [operation] The operation to isolate.
  /// [operationName] Optional name for logging purposes.
  /// Returns the result of the operation or null if an error occurs.
  static T? isolateSync<T>(
    T Function() operation, {
    String? operationName,
  }) {
    try {
      return operation();
    } catch (e, stackTrace) {
      developer.log(
        'Isolated sync operation ${operationName ?? 'unnamed'} failed: $e',
        name: 'ErrorIsolator',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Isolates a synchronous void operation.
  ///
  /// [operation] The operation to isolate.
  /// [operationName] Optional name for logging purposes.
  static void isolateSyncVoid(
    void Function() operation, {
    String? operationName,
  }) {
    try {
      operation();
    } catch (e, stackTrace) {
      developer.log(
        'Isolated sync void operation ${operationName ?? 'unnamed'} failed: $e',
        name: 'ErrorIsolator',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// A specialized error isolator for webhook operations.
class WebhookErrorIsolator {
  /// Isolates a webhook sending operation.
  ///
  /// [webhookOperation] The webhook operation to isolate.
  /// [webhookUrl] The webhook URL for logging purposes.
  /// Returns true if the operation succeeded, false otherwise.
  static Future<bool> isolateWebhook(
    Future<void> Function() webhookOperation, {
    String? webhookUrl,
  }) async {
    try {
      await webhookOperation();
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Webhook operation failed for ${webhookUrl ?? 'unknown URL'}: $e',
        name: 'WebhookErrorIsolator',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
  
  /// Isolates multiple webhook operations in parallel.
  ///
  /// [webhookOperations] List of webhook operations to execute.
  /// Returns a list of results indicating success/failure for each operation.
  static Future<List<bool>> isolateWebhooks(
    List<Future<void> Function()> webhookOperations,
  ) async {
    final futures = webhookOperations.map((operation) => isolateWebhook(operation));
    return await Future.wait(futures);
  }
}

/// An error isolator that provides additional context and metrics.
class ContextualErrorIsolator {
  final String _context;
  final Map<String, dynamic> _metrics = {};
  
  /// Creates a [ContextualErrorIsolator] instance.
  ///
  /// [context] The context name for this isolator.
  ContextualErrorIsolator(this._context);
  
  /// Isolates an operation with context-specific error handling.
  ///
  /// [operation] The operation to isolate.
  /// [operationName] Optional name for the operation.
  /// Returns the result of the operation or null if an error occurs.
  Future<T?> isolate<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    final startTime = DateTime.now();
    try {
      final result = await operation();
      _recordSuccess(operationName, startTime);
      return result;
    } catch (e, stackTrace) {
      _recordError(operationName, e, stackTrace, startTime);
      return null;
    }
  }
  
  /// Records a successful operation.
  void _recordSuccess(String? operationName, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    final key = '${_context}_${operationName ?? 'unknown'}_success';
    _metrics[key] = (_metrics[key] ?? 0) + 1;
    _metrics['${key}_total_duration'] = 
        (_metrics['${key}_total_duration'] ?? 0) + duration.inMilliseconds;
  }
  
  /// Records a failed operation.
  void _recordError(
    String? operationName,
    Object error,
    StackTrace stackTrace,
    DateTime startTime,
  ) {
    final duration = DateTime.now().difference(startTime);
    final key = '${_context}_${operationName ?? 'unknown'}_error';
    _metrics[key] = (_metrics[key] ?? 0) + 1;
    _metrics['${key}_total_duration'] = 
        (_metrics['${key}_total_duration'] ?? 0) + duration.inMilliseconds;
    
    developer.log(
      'Contextual error in $_context: ${operationName ?? 'unknown operation'}: $error',
      name: 'ContextualErrorIsolator',
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Gets the current metrics for this isolator.
  Map<String, dynamic> getMetrics() => Map.from(_metrics);
  
  /// Resets the metrics.
  void resetMetrics() => _metrics.clear();
}

/// A utility class for safe execution of operations with timeout.
class SafeExecutor {
  /// Executes an operation with a timeout, isolating any errors.
  ///
  /// [operation] The operation to execute.
  /// [timeout] The timeout duration.
  /// [operationName] Optional name for logging purposes.
  /// Returns the result of the operation or null if timeout/error occurs.
  static Future<T?> executeWithTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
    String? operationName,
  }) async {
    try {
      return await operation().timeout(timeout);
    } catch (e, stackTrace) {
      developer.log(
        'Operation ${operationName ?? 'unnamed'} failed or timed out: $e',
        name: 'SafeExecutor',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
  
  /// Executes multiple operations in parallel with individual timeouts.
  ///
  /// [operations] List of operations to execute.
  /// [timeout] The timeout duration for each operation.
  /// Returns a list of results, with null for failed/timed out operations.
  static Future<List<T?>> executeAllWithTimeout<T>(
    List<Future<T> Function()> operations, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final futures = operations.map((operation) => 
        executeWithTimeout(operation, timeout: timeout));
    return await Future.wait(futures);
  }
}
