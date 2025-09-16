# CurlInterceptor Implementation Best Practices

## Short Description
Create a production-ready CurlInterceptor implementation with step-by-step guidelines for non-blocking behavior, robust error handling, performance optimization, and comprehensive monitoring capabilities.

## Reference Links
- [Production CurlInterceptor Plan](./real_world_curl_interceptor_plan.md) - Main implementation plan
- [Async Patterns Guide](./async_patterns_guide_plan.md) - Async implementation patterns
- [Dio Interceptor Documentation](https://pub.dev/packages/dio) - Official Dio interceptor guide
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/best-practices) - Performance optimization guide

---

## Plan Steps (Progress: 0% - 0/56 done)

### Phase 1: Core Non-Blocking Foundation
- [ ] Create enhanced CurlInterceptor base class with non-blocking architecture
- [ ] Implement error recovery strategy with comprehensive error handling
- [ ] Add performance monitor for tracking interceptor impact
- [ ] Create memory management system with periodic cleanup
- [ ] Implement circuit breaker pattern for webhook services
- [ ] Add batch processing for high-volume webhook scenarios
- [ ] Create resource pooling for HTTP connections
- [ ] Implement fire-and-forget pattern for all webhook operations

### Phase 2: Advanced Features
- [ ] Create adaptive configuration system based on system load
- [ ] Implement load monitoring for dynamic behavior adjustment
- [ ] Add health check system for webhook services
- [ ] Create comprehensive metrics collection
- [ ] Implement smart filtering for high-load scenarios
- [ ] Add configuration validation and fail-safe defaults
- [ ] Create migration tools for backward compatibility

### Phase 3: Configuration and Deployment
- [ ] Create production configuration template
- [ ] Create development configuration template
- [ ] Create testing configuration template
- [ ] Implement configuration validation
- [ ] Add deployment guidelines and checklists
- [ ] Create monitoring and alerting setup
- [ ] Add performance benchmarking tools

## Implementation Examples

### Phase 1: Core Non-Blocking Foundation

#### Enhanced CurlInterceptor Base Class

```dart
import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

class ProductionCurlInterceptor extends Interceptor {
  final CurlOptions curlOptions;
  final CacheOptions cacheOptions;
  final List<WebhookInspectorBase>? webhookInspectors;
  final ErrorRecoveryStrategy errorRecovery;
  final PerformanceMonitor performanceMonitor;
  
  // Memory management
  final Map<RequestOptions, Stopwatch> _stopwatches = {};
  final Timer _cleanupTimer;
  final int _maxStopwatchAge = 5; // minutes
  
  // Circuit breakers for webhook services
  final Map<String, CircuitBreaker> _webhookCircuitBreakers = {};
  
  // Batch processors for high-volume scenarios
  final Map<String, BatchProcessor<WebhookMessage>> _batchProcessors = {};
  
  ProductionCurlInterceptor({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
    this.webhookInspectors,
    this.errorRecovery = const ErrorRecoveryStrategy(),
    this.performanceMonitor = const PerformanceMonitor(),
  }) : _cleanupTimer = Timer.periodic(
         Duration(minutes: _maxStopwatchAge),
         _cleanupOrphanedStopwatches,
       );
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final stopwatch = Stopwatch();
    
    try {
      // Start performance monitoring
      performanceMonitor.startRequest(options);
      
      // Handle request logging (synchronous)
      if (curlOptions.printOnRequest) {
        _logRequest(options);
      }
      
      // Start stopwatch for response time measurement
      if (curlOptions.responseTime) {
        stopwatch.start();
        _stopwatches[options] = stopwatch;
      }
      
      // Queue webhook notifications (fire-and-forget)
      if (webhookInspectors != null) {
        _queueWebhookNotifications(options, null);
      }
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Request processing error: $e', name: 'CurlInterceptor');
    } finally {
      // Always continue main flow
      return handler.next(options);
    }
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final stopwatch = _stopwatches.remove(response.requestOptions);
    stopwatch?.stop();
    
    try {
      // Record performance metrics
      performanceMonitor.recordResponse(response, stopwatch);
      
      // Handle response logging (synchronous)
      if (curlOptions.responseVisible) {
        _logResponse(response, stopwatch);
      }
      
      // Cache response if enabled (synchronous)
      if (cacheOptions.cacheResponse) {
        _cacheResponse(response, stopwatch);
      }
      
      // Queue webhook notifications (fire-and-forget)
      if (webhookInspectors != null) {
        _queueWebhookNotifications(response.requestOptions, response);
      }
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Response processing error: $e', name: 'CurlInterceptor');
    } finally {
      // Always continue main flow
      return handler.next(response);
    }
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final stopwatch = _stopwatches.remove(err.requestOptions);
    stopwatch?.stop();
    
    try {
      // Record error metrics
      performanceMonitor.recordError(err, stopwatch);
      
      // Handle error logging (synchronous)
      if (curlOptions.errorVisible) {
        _logError(err, stopwatch);
      }
      
      // Cache error if enabled (synchronous)
      if (cacheOptions.cacheError) {
        _cacheError(err, stopwatch);
      }
      
      // Queue webhook notifications (fire-and-forget)
      if (webhookInspectors != null) {
        _queueWebhookNotifications(err.requestOptions, err.response, err);
      }
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Error processing error: $e', name: 'CurlInterceptor');
    } finally {
      // Always continue main flow
      return handler.next(err);
    }
  }
  
  // Fire-and-forget webhook notifications
  void _queueWebhookNotifications(
    RequestOptions options,
    Response? response,
    [DioException? error]
  ) {
    if (webhookInspectors == null) return;
    
    final uri = options.uri.toString();
    final statusCode = response?.statusCode ?? error?.response?.statusCode ?? -1;
    
    for (final inspector in webhookInspectors!) {
      if (inspector.isMatch(uri, statusCode)) {
        // Fire-and-forget webhook notification
        unawaited(_sendWebhookNotification(inspector, options, response, error));
      }
    }
  }
  
  Future<void> _sendWebhookNotification(
    WebhookInspectorBase inspector,
    RequestOptions options,
    Response? response,
    DioException? error,
  ) async {
    try {
      final webhookUrl = _getWebhookUrl(inspector);
      final circuitBreaker = _getCircuitBreaker(webhookUrl);
      
      await circuitBreaker.call(() async {
        final message = _createWebhookMessage(inspector, options, response, error);
        
        if (curlOptions.batchWebhooks) {
          _getBatchProcessor(webhookUrl).add(message);
        } else {
          await inspector.sendCurlLog(
            curl: _generateCurl(options),
            method: options.method,
            uri: uri,
            statusCode: statusCode,
            responseBody: response?.data,
            responseTime: _calculateResponseTime(stopwatch),
            extraInfo: error != null ? {
              'type': error.type.name,
              'message': error.message,
            } : null,
          );
        }
      });
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Webhook notification failed: $e', name: 'CurlInterceptor');
    }
  }
  
  // Memory cleanup
  void _cleanupOrphanedStopwatches() {
    final now = DateTime.now();
    _stopwatches.removeWhere((key, stopwatch) {
      final age = now.difference(stopwatch.startTime);
      return age.inMinutes > _maxStopwatchAge;
    });
  }
  
  // Circuit breaker management
  CircuitBreaker _getCircuitBreaker(String webhookUrl) {
    return _webhookCircuitBreakers.putIfAbsent(
      webhookUrl,
      () => CircuitBreaker(
        failureThreshold: 5,
        timeout: Duration(seconds: 30),
        resetTimeout: Duration(minutes: 1),
      ),
    );
  }
  
  // Batch processor management
  BatchProcessor<WebhookMessage> _getBatchProcessor(String webhookUrl) {
    return _batchProcessors.putIfAbsent(
      webhookUrl,
      () => BatchProcessor<WebhookMessage>(
        batchSize: 10,
        batchTimeout: Duration(seconds: 5),
        processor: (messages) => _sendBatchToWebhook(webhookUrl, messages),
      ),
    );
  }
  
  // Dispose resources
  void dispose() {
    _cleanupTimer.cancel();
    _stopwatches.clear();
    _webhookCircuitBreakers.clear();
    _batchProcessors.clear();
  }
}
```

#### 1.2 Error Recovery Strategy

```dart
class ErrorRecoveryStrategy {
  final bool enableRetry;
  final int maxRetries;
  final Duration initialRetryDelay;
  final double retryBackoffMultiplier;
  final Duration maxRetryDelay;
  final bool enableCircuitBreaker;
  final int circuitBreakerThreshold;
  final Duration circuitBreakerTimeout;
  
  const ErrorRecoveryStrategy({
    this.enableRetry = true,
    this.maxRetries = 3,
    this.initialRetryDelay = Duration(seconds: 1),
    this.retryBackoffMultiplier = 2.0,
    this.maxRetryDelay = Duration(minutes: 1),
    this.enableCircuitBreaker = true,
    this.circuitBreakerThreshold = 5,
    this.circuitBreakerTimeout = Duration(minutes: 1),
  });
  
  Future<T> executeWithRecovery<T>(
    Future<T> Function() operation,
    String operationName,
  ) async {
    if (!enableRetry) {
      return await operation();
    }
    
    int attempt = 0;
    Duration delay = initialRetryDelay;
    
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;
        
        if (attempt > maxRetries) {
          developer.log(
            'Max retries exceeded for $operationName: $e',
            name: 'ErrorRecoveryStrategy',
          );
          rethrow;
        }
        
        developer.log(
          'Retry attempt $attempt for $operationName after ${delay.inMilliseconds}ms: $e',
          name: 'ErrorRecoveryStrategy',
        );
        
        await Future.delayed(delay);
        
        delay = Duration(
          milliseconds: (delay.inMilliseconds * retryBackoffMultiplier).round(),
        );
        
        if (delay > maxRetryDelay) {
          delay = maxRetryDelay;
        }
      }
    }
    
    throw StateError('Retry logic failed for $operationName');
  }
}
```

#### 1.3 Performance Monitor

```dart
class PerformanceMonitor {
  final bool enabled;
  final Duration metricsInterval;
  
  // Metrics
  int _requestsProcessed = 0;
  int _webhookFailures = 0;
  int _errorsProcessed = 0;
  final List<Duration> _processingTimes = [];
  DateTime? _lastMetricsReport;
  
  const PerformanceMonitor({
    this.enabled = true,
    this.metricsInterval = Duration(minutes: 5),
  });
  
  void startRequest(RequestOptions options) {
    if (!enabled) return;
    
    _requestsProcessed++;
    _lastMetricsReport ??= DateTime.now();
    
    // Report metrics periodically
    if (_shouldReportMetrics()) {
      _reportMetrics();
    }
  }
  
  void recordResponse(Response response, Stopwatch? stopwatch) {
    if (!enabled) return;
    
    if (stopwatch != null) {
      _processingTimes.add(stopwatch.elapsed);
      
      // Keep only recent processing times
      if (_processingTimes.length > 1000) {
        _processingTimes.removeRange(0, 500);
      }
    }
  }
  
  void recordError(DioException error, Stopwatch? stopwatch) {
    if (!enabled) return;
    
    _errorsProcessed++;
    
    if (stopwatch != null) {
      _processingTimes.add(stopwatch.elapsed);
    }
  }
  
  void recordWebhookFailure() {
    if (!enabled) return;
    
    _webhookFailures++;
  }
  
  bool _shouldReportMetrics() {
    if (_lastMetricsReport == null) return false;
    
    return DateTime.now().difference(_lastMetricsReport!) > metricsInterval;
  }
  
  void _reportMetrics() {
    if (!enabled) return;
    
    final avgProcessingTime = _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a + b) / _processingTimes.length
        : Duration.zero;
    
    developer.log(
      'CurlInterceptor Metrics - '
      'Requests: $_requestsProcessed, '
      'Errors: $_errorsProcessed, '
      'Webhook Failures: $_webhookFailures, '
      'Avg Processing Time: ${avgProcessingTime.inMicroseconds}μs',
      name: 'PerformanceMonitor',
    );
    
    _lastMetricsReport = DateTime.now();
  }
  
  Map<String, dynamic> getMetrics() {
    final avgProcessingTime = _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a + b) / _processingTimes.length
        : Duration.zero;
    
    return {
      'requestsProcessed': _requestsProcessed,
      'errorsProcessed': _errorsProcessed,
      'webhookFailures': _webhookFailures,
      'averageProcessingTime': avgProcessingTime.inMicroseconds,
      'processingTimeSamples': _processingTimes.length,
    };
  }
}
```

### Phase 2: Advanced Features

#### Adaptive Configuration

```dart
class AdaptiveCurlInterceptor extends ProductionCurlInterceptor {
  final LoadMonitor _loadMonitor;
  final AdaptiveConfig _adaptiveConfig;
  
  AdaptiveCurlInterceptor({
    super.curlOptions,
    super.cacheOptions,
    super.webhookInspectors,
    super.errorRecovery,
    super.performanceMonitor,
    required LoadMonitor loadMonitor,
    required AdaptiveConfig adaptiveConfig,
  }) : _loadMonitor = loadMonitor,
       _adaptiveConfig = adaptiveConfig;
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Adjust behavior based on current load
    if (_loadMonitor.isHighLoad()) {
      _adaptToHighLoad(options);
    }
    
    super.onRequest(options, handler);
  }
  
  void _adaptToHighLoad(RequestOptions options) {
    // Reduce logging verbosity during high load
    if (_adaptiveConfig.reduceLoggingOnHighLoad) {
      // Skip non-critical logging
      if (!_isHighValueRequest(options)) {
        return;
      }
    }
    
    // Increase batch sizes for webhooks
    if (_adaptiveConfig.increaseBatchSizeOnHighLoad) {
      _adjustBatchSizes(2.0); // Double batch sizes
    }
  }
  
  bool _isHighValueRequest(RequestOptions options) {
    // Define criteria for high-value requests
    return options.method != 'GET' || 
           options.uri.path.contains('/api/') ||
           options.uri.path.contains('/auth/');
  }
  
  void _adjustBatchSizes(double multiplier) {
    for (final processor in _batchProcessors.values) {
      processor.adjustBatchSize(multiplier);
    }
  }
}

class LoadMonitor {
  final int _maxRequestsPerSecond;
  final Duration _measurementWindow;
  
  final Queue<DateTime> _requestTimes = Queue();
  
  LoadMonitor({
    int maxRequestsPerSecond = 100,
    Duration measurementWindow = Duration(seconds: 10),
  }) : _maxRequestsPerSecond = maxRequestsPerSecond,
       _measurementWindow = measurementWindow;
  
  void recordRequest() {
    final now = DateTime.now();
    _requestTimes.add(now);
    
    // Remove old requests outside measurement window
    while (_requestTimes.isNotEmpty &&
           now.difference(_requestTimes.first) > _measurementWindow) {
      _requestTimes.removeFirst();
    }
  }
  
  bool isHighLoad() {
    final now = DateTime.now();
    final recentRequests = _requestTimes.where((time) =>
        now.difference(time) <= _measurementWindow).length;
    
    return recentRequests > _maxRequestsPerSecond;
  }
  
  double getCurrentLoad() {
    final now = DateTime.now();
    final recentRequests = _requestTimes.where((time) =>
        now.difference(time) <= _measurementWindow).length;
    
    return recentRequests / _maxRequestsPerSecond;
  }
}

class AdaptiveConfig {
  final bool reduceLoggingOnHighLoad;
  final bool increaseBatchSizeOnHighLoad;
  final bool enableCircuitBreakerOnHighLoad;
  final double highLoadThreshold;
  
  const AdaptiveConfig({
    this.reduceLoggingOnHighLoad = true,
    this.increaseBatchSizeOnHighLoad = true,
    this.enableCircuitBreakerOnHighLoad = true,
    this.highLoadThreshold = 0.8,
  });
}
```

#### 2.2 Health Check System

```dart
class CurlInterceptorHealth {
  final ProductionCurlInterceptor _interceptor;
  final List<HealthCheck> _healthChecks;
  
  CurlInterceptorHealth(this._interceptor) : _healthChecks = [
    WebhookConnectivityCheck(),
    MemoryUsageCheck(),
    CircuitBreakerHealthCheck(),
    PerformanceHealthCheck(),
  ];
  
  Future<HealthStatus> checkHealth() async {
    final issues = <String>[];
    final warnings = <String>[];
    
    for (final check in _healthChecks) {
      try {
        final result = await check.check(_interceptor);
        
        if (result.status == HealthStatusType.unhealthy) {
          issues.addAll(result.issues);
        } else if (result.status == HealthStatusType.degraded) {
          warnings.addAll(result.issues);
        }
      } catch (e) {
        issues.add('Health check ${check.runtimeType} failed: $e');
      }
    }
    
    return HealthStatus(
      status: issues.isEmpty 
          ? (warnings.isEmpty ? HealthStatusType.healthy : HealthStatusType.degraded)
          : HealthStatusType.unhealthy,
      issues: issues,
      warnings: warnings,
      timestamp: DateTime.now(),
    );
  }
}

abstract class HealthCheck {
  Future<HealthCheckResult> check(ProductionCurlInterceptor interceptor);
}

class WebhookConnectivityCheck extends HealthCheck {
  @override
  Future<HealthCheckResult> check(ProductionCurlInterceptor interceptor) async {
    final issues = <String>[];
    
    if (interceptor.webhookInspectors != null) {
      for (final inspector in interceptor.webhookInspectors!) {
        try {
          // Test webhook connectivity
          await inspector.testConnectivity();
        } catch (e) {
          issues.add('Webhook ${inspector.runtimeType} connectivity failed: $e');
        }
      }
    }
    
    return HealthCheckResult(
      status: issues.isEmpty ? HealthStatusType.healthy : HealthStatusType.unhealthy,
      issues: issues,
    );
  }
}

class MemoryUsageCheck extends HealthCheck {
  @override
  Future<HealthCheckResult> check(ProductionCurlInterceptor interceptor) async {
    final issues = <String>[];
    
    // Check stopwatch map size
    if (interceptor._stopwatches.length > 1000) {
      issues.add('Too many active stopwatches: ${interceptor._stopwatches.length}');
    }
    
    // Check circuit breaker count
    if (interceptor._webhookCircuitBreakers.length > 100) {
      issues.add('Too many circuit breakers: ${interceptor._webhookCircuitBreakers.length}');
    }
    
    return HealthCheckResult(
      status: issues.isEmpty ? HealthStatusType.healthy : HealthStatusType.unhealthy,
      issues: issues,
    );
  }
}

enum HealthStatusType { healthy, degraded, unhealthy }

class HealthStatus {
  final HealthStatusType status;
  final List<String> issues;
  final List<String> warnings;
  final DateTime timestamp;
  
  HealthStatus({
    required this.status,
    required this.issues,
    required this.warnings,
    required this.timestamp,
  });
}

class HealthCheckResult {
  final HealthStatusType status;
  final List<String> issues;
  
  HealthCheckResult({
    required this.status,
    required this.issues,
  });
}
```

### Phase 3: Configuration and Usage

#### Production Configuration

```dart
// Production-ready configuration
final productionInterceptor = ProductionCurlInterceptor(
  curlOptions: CurlOptions(
    printOnRequest: false,  // Disable console logging in production
    printOnResponse: false,
    printOnError: false,
    responseTime: true,     // Keep timing for monitoring
    batchWebhooks: true,    // Enable batching for performance
  ),
  cacheOptions: CacheOptions(
    cacheResponse: false,   // Disable response caching in production
    cacheError: true,       // Keep error caching for debugging
  ),
  webhookInspectors: [
    DiscordInspector(
      webhookUrls: [webhookUrl],
      inspectionStatus: [ResponseStatus.serverError], // Only log server errors
    ),
  ],
  errorRecovery: ErrorRecoveryStrategy(
    enableRetry: true,
    maxRetries: 3,
    enableCircuitBreaker: true,
  ),
  performanceMonitor: PerformanceMonitor(
    enabled: true,
    metricsInterval: Duration(minutes: 5),
  ),
);

// Add to Dio instance
final dio = Dio();
dio.interceptors.add(productionInterceptor);
```

#### Development Configuration

```dart
// Development configuration with full logging
final developmentInterceptor = ProductionCurlInterceptor(
  curlOptions: CurlOptions.allEnabled(),
  cacheOptions: CacheOptions.allEnabled(),
  webhookInspectors: [
    DiscordInspector(
      webhookUrls: [webhookUrl],
      inspectionStatus: ResponseStatus.values, // Log all statuses
    ),
  ],
  errorRecovery: ErrorRecoveryStrategy(
    enableRetry: false, // Disable retries in development
  ),
  performanceMonitor: PerformanceMonitor(
    enabled: true,
    metricsInterval: Duration(minutes: 1), // More frequent reporting
  ),
);
```

#### Testing Configuration

```dart
// Testing configuration with minimal overhead
final testingInterceptor = ProductionCurlInterceptor(
  curlOptions: CurlOptions(
    printOnRequest: false,
    printOnResponse: false,
    printOnError: false,
    responseTime: false,
  ),
  cacheOptions: CacheOptions(
    cacheResponse: false,
    cacheError: false,
  ),
  webhookInspectors: null, // Disable webhooks in tests
  performanceMonitor: PerformanceMonitor(enabled: false),
);
```

---

## Implementation Checklist

### Phase 1: Core Foundation
- [ ] Implement non-blocking webhook notifications
- [ ] Add comprehensive error handling
- [ ] Implement memory cleanup mechanisms
- [ ] Add performance monitoring
- [ ] Create circuit breaker pattern
- [ ] Implement batch processing

### Phase 2: Advanced Features
- [ ] Add adaptive configuration
- [ ] Implement load monitoring
- [ ] Create health check system
- [ ] Add metrics collection
- [ ] Implement resource pooling

### Phase 3: Configuration
- [ ] Create production configuration
- [ ] Create development configuration
- [ ] Create testing configuration
- [ ] Add configuration validation
- [ ] Create migration guide

### Testing and Validation
- [ ] Unit tests for all components
- [ ] Integration tests with real webhooks
- [ ] Load testing scenarios
- [ ] Error scenario testing
- [ ] Performance benchmarking

---

## Deployment Guidelines

### Pre-Production Checklist
- [ ] Validate all configurations are production-ready
- [ ] Implement health check endpoints
- [ ] Set up metrics collection and alerting
- [ ] Validate performance under expected load
- [ ] Test failure modes and recovery scenarios

### Production Monitoring
- [ ] Monitor latency impact and resource usage
- [ ] Track webhook failure rates and circuit breaker states
- [ ] Regular health check monitoring
- [ ] Monitor memory and CPU usage patterns

### Maintenance
- [ ] Ensure memory cleanup mechanisms are working
- [ ] Monitor and reset circuit breakers as needed
- [ ] Adjust batch sizes and timeouts based on usage patterns
- [ ] Update configurations based on monitoring data
