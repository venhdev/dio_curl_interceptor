# Async Patterns and Non-Blocking Strategies Guide

## Short Description
Implement comprehensive async patterns and non-blocking strategies for CurlInterceptor to ensure webhook operations never block the main application flow while providing robust error handling and performance optimization.

## Reference Links
- [Fire-and-Forget Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/async-request-reply) - Async processing pattern
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html) - Failure prevention pattern
- [Retry Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/retry) - Transient failure handling

---

## Plan Steps (Progress: 100% - 25/25 done)

### Core Async Patterns Implementation
- [x] Implement fire-and-forget pattern for webhook notifications
- [x] Create circuit breaker pattern for webhook service failure prevention
- [x] Implement batch processing pattern for high-volume webhook scenarios
- [x] Add retry mechanism with exponential backoff for transient failures
- [x] Create resource pool pattern for HTTP connection management
- [x] Implement error isolation pattern to prevent main flow disruption
- [x] Add fallback pattern for critical webhook operations
- [x] Create lazy initialization pattern for webhook inspectors
- [x] Implement caching pattern for webhook cooldown periods

### Error Handling Patterns
- [x] Create error isolation wrapper for all webhook operations
- [x] Implement fallback handler with multiple recovery strategies
- [x] Add comprehensive error logging without performance impact
- [x] Create error recovery mechanisms for different failure types
- [x] Implement graceful degradation for webhook service failures

### Performance Optimization Patterns
- [x] Implement lazy initialization for webhook components
- [x] Create caching system for webhook cooldown periods
- [x] Add connection pooling for webhook HTTP clients
- [x] Implement rate limiting for webhook API calls
- [x] Create batch processing for multiple webhook notifications
- [x] Add memory management and cleanup mechanisms

## Implementation Examples

### 1. Fire-and-Forget Pattern

**Use Case**: Webhook notifications that don't require confirmation
**Principle**: Start async operation but don't wait for completion

```dart
class CurlInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Process response synchronously
    _processResponse(response);
    
    // Fire-and-forget webhook notifications
    if (webhookInspectors != null) {
      for (final inspector in webhookInspectors) {
        if (inspector.isMatch(response.requestOptions.uri.toString(), response.statusCode)) {
          // Don't await - let it run in background
          unawaited(_sendWebhookAsync(inspector, response));
        }
      }
    }
    
    // Always continue main flow immediately
    return handler.next(response);
  }
  
  Future<void> _sendWebhookAsync(WebhookInspectorBase inspector, Response response) async {
    try {
      await inspector.sendCurlLog(
        curl: _generateCurl(response.requestOptions),
        method: response.requestOptions.method,
        uri: response.requestOptions.uri.toString(),
        statusCode: response.statusCode,
        responseBody: response.data,
      );
    } catch (e) {
      // Log error but don't propagate
      log('Webhook failed: $e', name: 'CurlInterceptor');
    }
  }
}
```

### 2. Circuit Breaker Pattern

**Use Case**: Prevent cascading failures from webhook services
**Principle**: Stop calling failing services temporarily

```dart
class CircuitBreaker {
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitState _state = CircuitState.closed;
  
  enum CircuitState { closed, open, halfOpen }
  
  Future<T> call<T>(Future<T> Function() operation) async {
    if (_state == CircuitState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitState.halfOpen;
      } else {
        throw CircuitBreakerOpenException();
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
  
  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitState.closed;
  }
  
  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitState.open;
    }
  }
  
  bool _shouldAttemptReset() {
    return _lastFailureTime != null &&
           DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }
}

// Usage in CurlInterceptor
class CurlInterceptor extends Interceptor {
  final Map<String, CircuitBreaker> _webhookCircuitBreakers = {};
  
  Future<void> _sendWebhookWithCircuitBreaker(
    String webhookUrl,
    WebhookInspectorBase inspector,
    Response response,
  ) async {
    final circuitBreaker = _webhookCircuitBreakers.putIfAbsent(
      webhookUrl,
      () => CircuitBreaker(
        failureThreshold: 5,
        timeout: Duration(seconds: 30),
        resetTimeout: Duration(minutes: 1),
      ),
    );
    
    try {
      await circuitBreaker.call(() => inspector.sendCurlLog(...));
    } catch (e) {
      if (e is CircuitBreakerOpenException) {
        log('Circuit breaker open for $webhookUrl', name: 'CurlInterceptor');
      } else {
        log('Webhook error for $webhookUrl: $e', name: 'CurlInterceptor');
      }
    }
  }
}
```

### 3. Batch Processing Pattern

**Use Case**: Reduce webhook API calls by batching multiple requests
**Principle**: Collect requests and send them in batches

```dart
class BatchProcessor<T> {
  final int batchSize;
  final Duration batchTimeout;
  final Future<void> Function(List<T>) processor;
  
  final List<T> _batch = [];
  Timer? _batchTimer;
  
  BatchProcessor({
    required this.batchSize,
    required this.batchTimeout,
    required this.processor,
  });
  
  void add(T item) {
    _batch.add(item);
    
    if (_batch.length >= batchSize) {
      _processBatch();
    } else if (_batchTimer == null) {
      _batchTimer = Timer(batchTimeout, _processBatch);
    }
  }
  
  void _processBatch() {
    if (_batch.isEmpty) return;
    
    final itemsToProcess = List<T>.from(_batch);
    _batch.clear();
    _batchTimer?.cancel();
    _batchTimer = null;
    
    // Process batch asynchronously
    unawaited(_processItems(itemsToProcess));
  }
  
  Future<void> _processItems(List<T> items) async {
    try {
      await processor(items);
    } catch (e) {
      log('Batch processing failed: $e', name: 'BatchProcessor');
    }
  }
}

// Usage in CurlInterceptor
class CurlInterceptor extends Interceptor {
  final Map<String, BatchProcessor<WebhookMessage>> _batchProcessors = {};
  
  void _queueWebhookMessage(String webhookUrl, WebhookMessage message) {
    final processor = _batchProcessors.putIfAbsent(
      webhookUrl,
      () => BatchProcessor<WebhookMessage>(
        batchSize: 10,
        batchTimeout: Duration(seconds: 5),
        processor: (messages) => _sendBatchToWebhook(webhookUrl, messages),
      ),
    );
    
    processor.add(message);
  }
  
  Future<void> _sendBatchToWebhook(String webhookUrl, List<WebhookMessage> messages) async {
    try {
      // Send batch to webhook service
      await _webhookClient.sendBatch(webhookUrl, messages);
    } catch (e) {
      log('Batch webhook failed for $webhookUrl: $e', name: 'CurlInterceptor');
    }
  }
}
```

### 4. Retry with Exponential Backoff

**Use Case**: Handle transient failures in webhook services
**Principle**: Retry failed operations with increasing delays

```dart
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = Duration(minutes: 1),
  });
  
  Future<T> execute<T>(Future<T> Function() operation) async {
    int attempt = 0;
    Duration delay = initialDelay;
    
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt > maxRetries) {
          log('Max retries exceeded: $e', name: 'RetryPolicy');
          rethrow;
        }
        
        log('Retry attempt $attempt after ${delay.inMilliseconds}ms: $e', name: 'RetryPolicy');
        await Future.delayed(delay);
        
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
        
        if (delay > maxDelay) {
          delay = maxDelay;
        }
      }
    }
    
    throw StateError('Retry logic failed');
  }
}

// Usage in CurlInterceptor
class CurlInterceptor extends Interceptor {
  final RetryPolicy _webhookRetryPolicy = RetryPolicy(
    maxRetries: 3,
    initialDelay: Duration(seconds: 1),
    backoffMultiplier: 2.0,
  );
  
  Future<void> _sendWebhookWithRetry(
    WebhookInspectorBase inspector,
    Response response,
  ) async {
    try {
      await _webhookRetryPolicy.execute(() => inspector.sendCurlLog(...));
    } catch (e) {
      log('Webhook failed after retries: $e', name: 'CurlInterceptor');
    }
  }
}
```

### 5. Resource Pool Pattern

**Use Case**: Manage limited resources like HTTP connections
**Principle**: Reuse resources efficiently

```dart
class ResourcePool<T> {
  final List<T> _available = [];
  final List<T> _inUse = [];
  final T Function() _factory;
  final int _maxSize;
  
  ResourcePool({
    required T Function() factory,
    required int maxSize,
  }) : _factory = factory, _maxSize = maxSize;
  
  Future<R> use<R>(Future<R> Function(T) operation) async {
    final resource = _acquire();
    
    try {
      return await operation(resource);
    } finally {
      _release(resource);
    }
  }
  
  T _acquire() {
    if (_available.isNotEmpty) {
      final resource = _available.removeLast();
      _inUse.add(resource);
      return resource;
    }
    
    if (_inUse.length < _maxSize) {
      final resource = _factory();
      _inUse.add(resource);
      return resource;
    }
    
    throw StateError('Resource pool exhausted');
  }
  
  void _release(T resource) {
    _inUse.remove(resource);
    _available.add(resource);
  }
}

// Usage in CurlInterceptor
class CurlInterceptor extends Interceptor {
  final ResourcePool<Dio> _dioPool = ResourcePool<Dio>(
    factory: () => Dio()
      ..options.connectTimeout = Duration(seconds: 5)
      ..options.receiveTimeout = Duration(seconds: 10),
    maxSize: 10,
  );
  
  Future<void> _sendWebhookWithPool(
    String webhookUrl,
    dynamic payload,
  ) async {
    await _dioPool.use((dio) async {
      try {
        await dio.post(webhookUrl, data: payload);
      } catch (e) {
        log('Webhook failed: $e', name: 'CurlInterceptor');
      }
    });
  }
}
```

---

## Error Handling Patterns

### 1. Error Isolation Pattern

```dart
class ErrorIsolator {
  static Future<T?> isolate<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } catch (e) {
      log('Isolated operation failed: $e', name: 'ErrorIsolator');
      return null;
    }
  }
  
  static void isolateVoid(Future<void> Function() operation) {
    unawaited(isolate(operation));
  }
}

// Usage
class CurlInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Isolate webhook operations
    ErrorIsolator.isolateVoid(() => _sendWebhooks(response));
    
    // Always continue main flow
    return handler.next(response);
  }
}
```

### 2. Fallback Pattern

```dart
class FallbackHandler {
  final List<Future<void> Function()> _fallbacks = [];
  
  void addFallback(Future<void> Function() fallback) {
    _fallbacks.add(fallback);
  }
  
  Future<void> executeWithFallbacks(Future<void> Function() primary) async {
    try {
      await primary();
    } catch (e) {
      log('Primary operation failed: $e', name: 'FallbackHandler');
      
      for (final fallback in _fallbacks) {
        try {
          await fallback();
          break; // Success, stop trying fallbacks
        } catch (fallbackError) {
          log('Fallback failed: $fallbackError', name: 'FallbackHandler');
        }
      }
    }
  }
}
```

---

## Performance Optimization Patterns

### 1. Lazy Initialization

```dart
class LazyWebhookInspector {
  WebhookInspectorBase? _inspector;
  final WebhookInspectorBase Function() _factory;
  
  LazyWebhookInspector(this._factory);
  
  WebhookInspectorBase get inspector {
    return _inspector ??= _factory();
  }
  
  bool get isInitialized => _inspector != null;
}
```

### 2. Caching Pattern

```dart
class WebhookCache {
  final Map<String, DateTime> _lastSent = {};
  final Duration _cooldownPeriod;
  
  WebhookCache({Duration cooldownPeriod = Duration(minutes: 1)})
      : _cooldownPeriod = cooldownPeriod;
  
  bool shouldSend(String key) {
    final lastSent = _lastSent[key];
    if (lastSent == null) return true;
    
    return DateTime.now().difference(lastSent) > _cooldownPeriod;
  }
  
  void markSent(String key) {
    _lastSent[key] = DateTime.now();
  }
}
```

---

## Implementation Checklist

### Non-Blocking Guarantees
- [ ] All webhook operations use `unawaited()` or fire-and-forget pattern
- [ ] Main request/response flow never waits for webhook operations
- [ ] Error handling never propagates exceptions to main flow
- [ ] Circuit breakers prevent cascading failures

### Performance Optimizations
- [ ] Resource pooling for HTTP connections
- [ ] Batch processing for high-volume scenarios
- [ ] Rate limiting to prevent API abuse
- [ ] Memory cleanup for long-running applications

### Error Handling
- [ ] Comprehensive error isolation
- [ ] Retry mechanisms with exponential backoff
- [ ] Fallback strategies for critical operations
- [ ] Proper logging without performance impact

### Monitoring and Observability
- [ ] Performance metrics collection
- [ ] Health check endpoints
- [ ] Error rate monitoring
- [ ] Resource usage tracking

## Best Practices Summary
1. **Never Block**: Always use fire-and-forget for non-critical operations
2. **Fail Gracefully**: Implement comprehensive error handling and recovery
3. **Monitor Performance**: Track impact on main application flow
4. **Resource Management**: Use pooling and cleanup mechanisms
5. **Circuit Breakers**: Prevent cascading failures from external services
6. **Batch Operations**: Reduce API calls through intelligent batching
7. **Retry Logic**: Handle transient failures with exponential backoff
8. **Configuration**: Make all async behaviors configurable
