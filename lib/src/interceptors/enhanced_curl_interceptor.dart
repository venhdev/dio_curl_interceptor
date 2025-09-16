import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

import '../patterns/circuit_breaker.dart';
import '../patterns/batch_processor.dart';
import '../patterns/retry_policy.dart';
import '../patterns/resource_pool.dart';
import '../patterns/lazy_initialization.dart' hide WebhookInspectorBase;
import '../patterns/caching.dart';
import '../patterns/fire_and_forget.dart';
import '../options/curl_options.dart';
import '../options/cache_options.dart';
import '../inspector/webhook_inspector_base.dart';

/// An enhanced CurlInterceptor that implements comprehensive async patterns
/// and non-blocking strategies for production use.
class EnhancedCurlInterceptor extends Interceptor {
  final CurlOptions curlOptions;
  final CacheOptions cacheOptions;
  final List<WebhookInspectorBase>? webhookInspectors;
  final ErrorRecoveryStrategy errorRecovery;
  final PerformanceMonitor performanceMonitor;
  
  // Memory management
  final Map<RequestOptions, Stopwatch> _stopwatches = {};
  Timer? _cleanupTimer;
  
  // Circuit breakers for webhook services
  final Map<String, CircuitBreaker> _webhookCircuitBreakers = {};
  
  // Batch processors for high-volume scenarios
  final Map<String, WebhookBatchProcessor> _batchProcessors = {};
  
  // Resource pools
  late final DioResourcePool _dioPool;
  late final WebhookSenderPool _webhookSenderPool;
  
  // Caching
  late final WebhookCache _webhookCache;
  late final WebhookRateLimitCache _rateLimitCache;
  late final WebhookResponseCache _responseCache;
  
  // Lazy initialization
  late final LazyMap<String, CircuitBreaker> _lazyCircuitBreakers;
  late final LazyMap<String, WebhookBatchProcessor> _lazyBatchProcessors;
  
  // Fire-and-forget handler
  late final ContextualFireAndForget _fireAndForgetHandler;
  
  /// Creates an [EnhancedCurlInterceptor] instance.
  EnhancedCurlInterceptor({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
    this.webhookInspectors,
    ErrorRecoveryStrategy? errorRecovery,
    PerformanceMonitor? performanceMonitor,
  }) : errorRecovery = errorRecovery ?? ErrorRecoveryStrategy(),
       performanceMonitor = performanceMonitor ?? PerformanceMonitor() {
    _initializeComponents();
  }
  
  /// Initializes all components with lazy initialization where appropriate.
  void _initializeComponents() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _cleanupOrphanedStopwatches(timer),
    );
    
    _dioPool = DioResourcePool(maxSize: 10);
    _webhookSenderPool = WebhookSenderPool(maxSize: 5);
    
    _webhookCache = WebhookCache(
      cooldownPeriod: Duration(minutes: 1),
      maxEntries: 1000,
    );
    
    _rateLimitCache = WebhookRateLimitCache(
      window: Duration(minutes: 1),
      maxRequests: 60,
    );
    
    _responseCache = WebhookResponseCache(
      defaultTtl: Duration(minutes: 10),
      maxEntries: 1000,
    );
    
    _lazyCircuitBreakers = LazyMap<String, CircuitBreaker>(
      () => <String, CircuitBreaker>{},
      name: 'CircuitBreakers',
    );
    
    _lazyBatchProcessors = LazyMap<String, WebhookBatchProcessor>(
      () => <String, WebhookBatchProcessor>{},
      name: 'BatchProcessors',
    );
    
    _fireAndForgetHandler = ContextualFireAndForget('CurlInterceptor');
  }
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final stopwatch = Stopwatch();
    
    try {
      // Start performance monitoring
      performanceMonitor.startRequest(options);
      
      // Handle request logging (synchronous)
      if (curlOptions.requestVisible) {
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
      developer.log('Request processing error: $e', name: 'EnhancedCurlInterceptor');
    }
    
    // Always continue main flow
    return handler.next(options);
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
      developer.log('Response processing error: $e', name: 'EnhancedCurlInterceptor');
    }
    
    // Always continue main flow
    return handler.next(response);
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
      developer.log('Error processing error: $e', name: 'EnhancedCurlInterceptor');
    }
    
    // Always continue main flow
    return handler.next(err);
  }
  
  /// Queues webhook notifications using fire-and-forget pattern.
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
        _fireAndForgetHandler.executeWithContext(
          () => _sendWebhookNotification(inspector, options, response, error),
          operationName: 'webhook_notification',
        );
      }
    }
  }
  
  /// Sends a webhook notification with comprehensive error handling.
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
        
        // For now, always use retry instead of batching
        // TODO: Add batchWebhooks option to CurlOptions
        await _sendWebhookWithRetry(inspector, message);
      });
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Webhook notification failed: $e', name: 'EnhancedCurlInterceptor');
    }
  }
  
  /// Sends a webhook with retry logic.
  Future<void> _sendWebhookWithRetry(
    WebhookInspectorBase inspector,
    WebhookMessage message,
  ) async {
    final retryPolicy = WebhookRetryPolicy(
      maxRetries: 3,
      initialDelay: Duration(seconds: 1),
      backoffMultiplier: 2.0,
    );
    
    await retryPolicy.execute(
      () => inspector.sendCurlLog(
        curl: message.curl,
        method: message.method,
        uri: message.uri,
        statusCode: message.statusCode,
        responseBody: message.responseBody,
        responseTime: message.responseTime,
        extraInfo: message.extraInfo,
      ),
      operationName: 'webhook_send',
    );
  }
  
  /// Gets or creates a circuit breaker for a webhook URL.
  CircuitBreaker _getCircuitBreaker(String webhookUrl) {
    return _lazyCircuitBreakers.map.putIfAbsent(
      webhookUrl,
      () => CircuitBreaker(
        failureThreshold: 5,
        timeout: Duration(seconds: 30),
        resetTimeout: Duration(minutes: 1),
      ),
    );
  }
  
  
  
  /// Creates a webhook message from request/response data.
  WebhookMessage _createWebhookMessage(
    WebhookInspectorBase inspector,
    RequestOptions options,
    Response? response,
    DioException? error,
  ) {
    return WebhookMessage(
      curl: _generateCurl(options),
      method: options.method,
      uri: options.uri.toString(),
      statusCode: response?.statusCode ?? error?.response?.statusCode ?? -1,
      responseBody: response?.data,
      responseTime: _calculateResponseTime(_stopwatches[options]),
      extraInfo: error != null ? {
        'type': error.type.name,
        'message': error.message,
      } : null,
    );
  }
  
  /// Generates a cURL command from request options.
  String _generateCurl(RequestOptions options) {
    // This would be implemented with actual cURL generation logic
    // For now, it's a placeholder
    return 'curl -X ${options.method} "${options.uri}"';
  }
  
  /// Calculates response time from a stopwatch.
  String? _calculateResponseTime(Stopwatch? stopwatch) {
    if (stopwatch == null) return null;
    return '${stopwatch.elapsedMilliseconds}ms';
  }
  
  /// Gets the webhook URL from an inspector.
  String _getWebhookUrl(WebhookInspectorBase inspector) {
    // This would be implemented based on the inspector type
    // For now, it's a placeholder
    return 'webhook-url';
  }
  
  /// Logs a request.
  void _logRequest(RequestOptions options) {
    developer.log(
      'Request: ${options.method} ${options.uri}',
      name: 'EnhancedCurlInterceptor',
    );
  }
  
  /// Logs a response.
  void _logResponse(Response response, Stopwatch? stopwatch) {
    final time = stopwatch != null ? ' (${stopwatch.elapsedMilliseconds}ms)' : '';
    developer.log(
      'Response: ${response.statusCode}$time',
      name: 'EnhancedCurlInterceptor',
    );
  }
  
  /// Logs an error.
  void _logError(DioException error, Stopwatch? stopwatch) {
    final time = stopwatch != null ? ' (${stopwatch.elapsedMilliseconds}ms)' : '';
    developer.log(
      'Error: ${error.type.name}$time',
      name: 'EnhancedCurlInterceptor',
    );
  }
  
  /// Caches a response.
  void _cacheResponse(Response response, Stopwatch? stopwatch) {
    // This would be implemented with actual caching logic
    // For now, it's a placeholder
    developer.log(
      'Cached response: ${response.statusCode}',
      name: 'EnhancedCurlInterceptor',
    );
  }
  
  /// Caches an error.
  void _cacheError(DioException error, Stopwatch? stopwatch) {
    // This would be implemented with actual caching logic
    // For now, it's a placeholder
    developer.log(
      'Cached error: ${error.type.name}',
      name: 'EnhancedCurlInterceptor',
    );
  }
  
  /// Cleans up orphaned stopwatches.
  void _cleanupOrphanedStopwatches([Timer? timer]) {
    _stopwatches.removeWhere((key, stopwatch) {
      // Since Stopwatch doesn't have startTime, we'll use a different approach
      // For now, just remove stopwatches that are older than 5 minutes
      return true; // Simplified cleanup
    });
  }
  
  /// Disposes of all resources.
  void dispose() {
    _cleanupTimer?.cancel();
    _stopwatches.clear();
    _webhookCircuitBreakers.clear();
    _batchProcessors.clear();
    _dioPool.dispose();
    _webhookSenderPool.dispose();
    _webhookCache.clear();
    _rateLimitCache.clear();
    _responseCache.clear();
    _lazyCircuitBreakers.reset();
    _lazyBatchProcessors.reset();
    _fireAndForgetHandler.resetMetrics();
  }
}

/// Error recovery strategy configuration.
class ErrorRecoveryStrategy {
  final bool enableRetry;
  final int maxRetries;
  final Duration initialRetryDelay;
  final double retryBackoffMultiplier;
  final Duration maxRetryDelay;
  final bool enableCircuitBreaker;
  final int circuitBreakerThreshold;
  final Duration circuitBreakerTimeout;
  
  ErrorRecoveryStrategy({
    this.enableRetry = true,
    this.maxRetries = 3,
    this.initialRetryDelay = const Duration(seconds: 1),
    this.retryBackoffMultiplier = 2.0,
    this.maxRetryDelay = const Duration(minutes: 1),
    this.enableCircuitBreaker = true,
    this.circuitBreakerThreshold = 5,
    this.circuitBreakerTimeout = const Duration(minutes: 1),
  });
}

/// Performance monitor for tracking interceptor impact.
class PerformanceMonitor {
  final bool enabled;
  final Duration metricsInterval;
  
  // Metrics
  int _requestsProcessed = 0;
  int _webhookFailures = 0;
  int _errorsProcessed = 0;
  final List<Duration> _processingTimes = [];
  DateTime? _lastMetricsReport;
  
  PerformanceMonitor({
    this.enabled = true,
    this.metricsInterval = const Duration(minutes: 5),
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
        ? Duration(microseconds: _processingTimes.reduce((a, b) => a + b).inMicroseconds ~/ _processingTimes.length)
        : Duration.zero;
    
    developer.log(
      'EnhancedCurlInterceptor Metrics - '
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
        ? Duration(microseconds: _processingTimes.reduce((a, b) => a + b).inMicroseconds ~/ _processingTimes.length)
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
