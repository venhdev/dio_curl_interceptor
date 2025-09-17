import 'dart:async';
import 'dart:developer' as developer;

/// Fire-and-forget utility for non-blocking operations.
class FireAndForget {
  /// Executes an operation without waiting for its completion.
  ///
  /// [operation] The operation to execute.
  /// [operationName] Optional name for logging purposes.
  static void execute(
    Future<void> Function() operation, {
    String? operationName,
  }) {
    unawaited(_executeWithErrorHandling(operation, operationName));
  }

  /// Executes multiple operations in parallel without waiting for completion.
  ///
  /// [operations] List of operations to execute.
  /// [operationName] Optional name for logging purposes.
  static void executeAll(
    List<Future<void> Function()> operations, {
    String? operationName,
  }) {
    for (int i = 0; i < operations.length; i++) {
      execute(
        operations[i],
        operationName: '${operationName ?? 'unnamed'}_$i',
      );
    }
  }

  /// Executes an operation with error handling.
  static Future<void> _executeWithErrorHandling(
    Future<void> Function() operation,
    String? operationName,
  ) async {
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
    }
  }
}
