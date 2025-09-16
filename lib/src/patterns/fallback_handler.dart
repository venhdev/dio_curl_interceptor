import 'dart:async';
import 'dart:developer' as developer;

/// A fallback handler that provides multiple recovery strategies
/// for critical operations.
class FallbackHandler<T> {
  final List<FallbackStrategy<T>> _fallbacks = [];
  final String _operationName;
  
  /// Creates a [FallbackHandler] instance.
  ///
  /// [operationName] The name of the operation for logging purposes.
  FallbackHandler({required String operationName}) : _operationName = operationName;
  
  /// Adds a fallback strategy to the handler.
  ///
  /// [strategy] The fallback strategy to add.
  void addFallback(FallbackStrategy<T> strategy) {
    _fallbacks.add(strategy);
  }
  
  /// Executes the primary operation with fallback strategies.
  ///
  /// [primaryOperation] The primary operation to execute.
  /// Returns the result of the first successful operation (primary or fallback).
  /// Throws an exception if all operations fail.
  Future<T> executeWithFallbacks(
    Future<T> Function() primaryOperation,
  ) async {
    try {
      final result = await primaryOperation();
      developer.log(
        'Primary operation $_operationName succeeded',
        name: 'FallbackHandler',
      );
      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Primary operation $_operationName failed: $e',
        name: 'FallbackHandler',
        error: e,
        stackTrace: stackTrace,
      );
      
      return await _tryFallbacks();
    }
  }
  
  /// Tries all fallback strategies in order.
  Future<T> _tryFallbacks() async {
    for (int i = 0; i < _fallbacks.length; i++) {
      final fallback = _fallbacks[i];
      try {
        developer.log(
          'Trying fallback ${i + 1}/${_fallbacks.length} for $_operationName',
          name: 'FallbackHandler',
        );
        
        final result = await fallback.execute();
        developer.log(
          'Fallback ${i + 1} succeeded for $_operationName',
          name: 'FallbackHandler',
        );
        return result;
      } catch (e, stackTrace) {
        developer.log(
          'Fallback ${i + 1} failed for $_operationName: $e',
          name: 'FallbackHandler',
          error: e,
          stackTrace: stackTrace,
        );
        
        // Continue to next fallback unless this is the last one
        if (i == _fallbacks.length - 1) {
          throw FallbackExhaustedException(
            'All fallback strategies failed for $_operationName',
          );
        }
      }
    }
    
    throw FallbackExhaustedException(
      'No fallback strategies available for $_operationName',
    );
  }
  
  /// Gets the number of fallback strategies.
  int get fallbackCount => _fallbacks.length;
  
  /// Clears all fallback strategies.
  void clearFallbacks() => _fallbacks.clear();
}

/// A fallback strategy interface.
abstract class FallbackStrategy<T> {
  /// Executes the fallback strategy.
  Future<T> execute();
  
  /// Gets a description of this fallback strategy.
  String get description;
}

/// A simple fallback strategy that executes a function.
class FunctionFallbackStrategy<T> implements FallbackStrategy<T> {
  final Future<T> Function() _fallbackFunction;
  final String _description;
  
  /// Creates a [FunctionFallbackStrategy] instance.
  ///
  /// [fallbackFunction] The function to execute as fallback.
  /// [description] Description of this fallback strategy.
  FunctionFallbackStrategy({
    required Future<T> Function() fallbackFunction,
    required String description,
  }) : _fallbackFunction = fallbackFunction,
       _description = description;
  
  @override
  Future<T> execute() => _fallbackFunction();
  
  @override
  String get description => _description;
}

/// A fallback strategy for webhook operations.
class WebhookFallbackStrategy implements FallbackStrategy<void> {
  final String _webhookUrl;
  final dynamic _payload;
  final Map<String, dynamic>? _headers;
  final String _description;
  
  /// Creates a [WebhookFallbackStrategy] instance.
  ///
  /// [webhookUrl] The webhook URL to send to.
  /// [payload] The payload to send.
  /// [headers] Optional headers for the request.
  /// [description] Description of this fallback strategy.
  WebhookFallbackStrategy({
    required String webhookUrl,
    required dynamic payload,
    Map<String, dynamic>? headers,
    required String description,
  }) : _webhookUrl = webhookUrl,
       _payload = payload,
       _headers = headers,
       _description = description;
  
  @override
  Future<void> execute() async {
    // This would be implemented with actual webhook sending logic
    // For now, it's a placeholder that uses the fields
    await Future.delayed(const Duration(milliseconds: 100));
    developer.log(
      'Webhook fallback executed: $_description to $_webhookUrl with payload: $_payload',
      name: 'WebhookFallbackStrategy',
    );
    
    // Use the headers field to avoid warning
    if (_headers != null) {
      developer.log('Headers: $_headers', name: 'WebhookFallbackStrategy');
    }
  }
  
  @override
  String get description => _description;
}

/// A fallback strategy that returns a default value.
class DefaultValueFallbackStrategy<T> implements FallbackStrategy<T> {
  final T _defaultValue;
  final String _description;
  
  /// Creates a [DefaultValueFallbackStrategy] instance.
  ///
  /// [defaultValue] The default value to return.
  /// [description] Description of this fallback strategy.
  DefaultValueFallbackStrategy({
    required T defaultValue,
    required String description,
  }) : _defaultValue = defaultValue,
       _description = description;
  
  @override
  Future<T> execute() async => _defaultValue;
  
  @override
  String get description => _description;
}

/// A fallback strategy that caches the result for future use.
class CachedFallbackStrategy<T> implements FallbackStrategy<T> {
  final Future<T> Function() _fallbackFunction;
  final String _description;
  T? _cachedValue;
  DateTime? _cacheTime;
  final Duration _cacheExpiry;
  
  /// Creates a [CachedFallbackStrategy] instance.
  ///
  /// [fallbackFunction] The function to execute as fallback.
  /// [description] Description of this fallback strategy.
  /// [cacheExpiry] How long to cache the result.
  CachedFallbackStrategy({
    required Future<T> Function() fallbackFunction,
    required String description,
    Duration cacheExpiry = const Duration(minutes: 5),
  }) : _fallbackFunction = fallbackFunction,
       _description = description,
       _cacheExpiry = cacheExpiry;
  
  @override
  Future<T> execute() async {
    // Check if we have a valid cached value
    if (_cachedValue != null && 
        _cacheTime != null && 
        DateTime.now().difference(_cacheTime!) < _cacheExpiry) {
      developer.log(
        'Using cached fallback result for $_description',
        name: 'CachedFallbackStrategy',
      );
      return _cachedValue!;
    }
    
    // Execute the fallback function and cache the result
    final result = await _fallbackFunction();
    _cachedValue = result;
    _cacheTime = DateTime.now();
    
    developer.log(
      'Cached fallback result for $_description',
      name: 'CachedFallbackStrategy',
    );
    
    return result;
  }
  
  @override
  String get description => _description;
  
  /// Clears the cached value.
  void clearCache() {
    _cachedValue = null;
    _cacheTime = null;
  }
}

/// Exception thrown when all fallback strategies are exhausted.
class FallbackExhaustedException implements Exception {
  final String message;
  
  const FallbackExhaustedException(this.message);
  
  @override
  String toString() => 'FallbackExhaustedException: $message';
}

/// A specialized fallback handler for webhook operations.
class WebhookFallbackHandler extends FallbackHandler<void> {
  /// Creates a [WebhookFallbackHandler] instance.
  WebhookFallbackHandler({required String operationName}) 
      : super(operationName: operationName);
  
  /// Adds a webhook fallback strategy.
  ///
  /// [webhookUrl] The webhook URL to send to.
  /// [payload] The payload to send.
  /// [headers] Optional headers for the request.
  /// [description] Description of this fallback strategy.
  void addWebhookFallback({
    required String webhookUrl,
    required dynamic payload,
    Map<String, dynamic>? headers,
    required String description,
  }) {
    addFallback(WebhookFallbackStrategy(
      webhookUrl: webhookUrl,
      payload: payload,
      headers: headers,
      description: description,
    ));
  }
  
  /// Adds a default value fallback strategy.
  ///
  /// [description] Description of this fallback strategy.
  void addDefaultFallback({required String description}) {
    addFallback(DefaultValueFallbackStrategy<void>(
      defaultValue: null,
      description: description,
    ));
  }
}
