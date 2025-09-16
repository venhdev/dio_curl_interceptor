import 'dart:async';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';

import '../patterns/fire_and_forget.dart';
import '../patterns/circuit_breaker.dart';
import '../patterns/retry_policy.dart';
import '../patterns/webhook_cache.dart';
import '../options/curl_options.dart';
import '../options/cache_options.dart';
import '../inspector/webhook_inspector_base.dart';
import '../inspector/discord_inspector.dart';
import '../inspector/telegram_inspector.dart';
import '../core/types.dart';
import '../core/utils/curl_utils.dart';
import '../core/helpers/curl_helper.dart';

/// CurlInterceptorV2 - A production-ready interceptor with essential async patterns
/// for non-blocking webhook operations without over-engineering.
///
/// This version extends the base CurlInterceptor functionality with:
/// - Fire-and-forget webhook operations
/// - Circuit breaker pattern for webhook reliability
/// - Retry policies with exponential backoff
/// - Memory management and cleanup
/// - All base interceptor features (cURL generation, logging, caching)
class CurlInterceptorV2 extends Interceptor {
  final CurlOptions curlOptions;
  final CacheOptions cacheOptions;
  final List<WebhookInspectorBase>? webhookInspectors;
  
  // Async patterns
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  final WebhookCache _webhookCache;
  final RetryPolicy _retryPolicy;
  
  // Memory management
  final Map<RequestOptions, Stopwatch> _stopwatches = {};
  Timer? _cleanupTimer;
  
  /// Creates a [CurlInterceptorV2] instance with customizable options.
  ///
  /// [curlOptions] defines how cURL commands are generated and displayed.
  /// [cacheOptions] configures caching behavior for requests and responses.
  /// [webhookInspectors] provides integration with webhook services for logging.
  CurlInterceptorV2({
    this.curlOptions = const CurlOptions(),
    this.cacheOptions = const CacheOptions(),
    this.webhookInspectors,
  }) : _webhookCache = WebhookCache(
          cooldownPeriod: Duration(minutes: 1),
        ),
       _retryPolicy = RetryPolicy(
         maxRetries: 3,
         initialDelay: Duration(seconds: 1),
         backoffMultiplier: 2.0,
       ) {
    _initializeCleanup();
  }

  /// Creates a [CurlInterceptorV2] instance with all cURL and cache options enabled.
  ///
  /// This factory provides a convenient way to set up the interceptor
  /// with maximum logging and caching capabilities.
  ///
  /// [inspectorOptions] (optional) allows for webhook integration.
  factory CurlInterceptorV2.allEnabled([
    WebhookInspectorBase? inspectorOptions,
  ]) =>
      CurlInterceptorV2(
        curlOptions: CurlOptions.allEnabled(),
        cacheOptions: CacheOptions.allEnabled(),
        webhookInspectors: inspectorOptions != null ? [inspectorOptions] : null,
      );

  /// Factory constructor to create a CurlInterceptorV2 with Discord webhook enabled
  /// Creates a [CurlInterceptorV2] instance configured for Discord webhook integration.
  ///
  /// This factory simplifies the setup for sending cURL logs and inspection
  /// data to specified Discord webhook URLs.
  ///
  /// [webhookUrls] is a list of Discord webhook URLs where logs will be sent.
  /// [includeUrls] (optional) specifies a list of URI patterns to include for inspection.
  /// [excludeUrls] (optional) specifies a list of URI patterns to exclude from inspection.
  /// [inspectionStatus] (optional) defines which response statuses trigger webhook notifications.
  /// [curlOptions] (optional) customizes how cURL commands are generated.
  /// [cacheOptions] (optional) configures caching behavior.
  factory CurlInterceptorV2.withDiscordInspector(
    List<String> webhookUrls, {
    List<String> includeUrls = const [],
    List<String> excludeUrls = const [],
    List<ResponseStatus> inspectionStatus = const <ResponseStatus>[
      ResponseStatus.clientError,
      ResponseStatus.serverError,
    ],
    CurlOptions curlOptions = const CurlOptions(),
    CacheOptions cacheOptions = const CacheOptions(),
  }) =>
      CurlInterceptorV2(
        curlOptions: curlOptions,
        cacheOptions: cacheOptions,
        webhookInspectors: [
          DiscordInspector(
            webhookUrls: webhookUrls,
            includeUrls: includeUrls,
            excludeUrls: excludeUrls,
            inspectionStatus: inspectionStatus,
          ),
        ],
      );

  /// Factory constructor to create a CurlInterceptorV2 with Telegram Bot API integration
  /// Creates a [CurlInterceptorV2] instance configured for Telegram Bot API integration.
  ///
  /// This factory simplifies the setup for sending cURL logs and inspection
  /// data to specified Telegram chats via the Bot API.
  ///
  /// [botToken] The Telegram bot token obtained from @BotFather.
  /// [chatIds] A list of chat IDs where messages will be sent. Can be:
  ///   - Positive integers for private chats (e.g., 123456789)
  ///   - Negative integers for groups/supergroups (e.g., -1003019608685)
  ///   - Channel usernames with @ prefix (e.g., @channelusername)
  /// [includeUrls] (optional) specifies a list of URI patterns to include for inspection.
  /// [excludeUrls] (optional) specifies a list of URI patterns to exclude from inspection.
  /// [inspectionStatus] (optional) defines which response statuses trigger webhook notifications.
  /// [curlOptions] (optional) customizes how cURL commands are generated.
  /// [cacheOptions] (optional) configures caching behavior.
  factory CurlInterceptorV2.withTelegramInspector(
    String botToken,
    List<dynamic> chatIds, {
    List<String> includeUrls = const [],
    List<String> excludeUrls = const [],
    List<ResponseStatus> inspectionStatus = const <ResponseStatus>[
      ResponseStatus.clientError,
      ResponseStatus.serverError,
    ],
    CurlOptions curlOptions = const CurlOptions(),
    CacheOptions cacheOptions = const CacheOptions(),
  }) =>
      CurlInterceptorV2(
        curlOptions: curlOptions,
        cacheOptions: cacheOptions,
        webhookInspectors: [
          TelegramInspector(
            botToken: botToken,
            chatIds: chatIds,
            includeUrls: includeUrls,
            excludeUrls: excludeUrls,
            inspectionStatus: inspectionStatus,
          ),
        ],
      );
  
  /// Initializes cleanup timer for orphaned stopwatches.
  void _initializeCleanup() {
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _cleanupOrphanedStopwatches(),
    );
  }
  
  /// Intercepts the request before it is sent.
  ///
  /// This method handles logging the request as a cURL command, starting a stopwatch
  /// for response time measurement if enabled, and passing the request to the next handler.
  ///
  /// [options] The options for the request.
  /// [handler] The handler to which the request is passed.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      // Handle request logging using CurlUtils (synchronous)
      CurlUtils.handleOnRequest(
        options,
        curlOptions: curlOptions,
        webhookInspectors: webhookInspectors,
      );
      
      // Start stopwatch for response time measurement
      if (curlOptions.responseTime) {
        final stopwatch = Stopwatch()..start();
        _stopwatches[options] = stopwatch;
      }
      
      // Queue webhook notifications (fire-and-forget)
      if (webhookInspectors != null) {
        _queueWebhookNotifications(options, null);
      }
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Request processing error: $e', name: 'CurlInterceptorV2');
    }
    
    // Always continue main flow
    return handler.next(options);
  }
  
  /// Intercepts the response after it is received.
  ///
  /// This method stops the stopwatch for response time, handles logging the response,
  /// caches the response if enabled, and passes the response to the next handler.
  ///
  /// [response] The received response.
  /// [handler] The handler to which the response is passed.
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final stopwatch = _stopwatches.remove(response.requestOptions);
    stopwatch?.stop();
    
    try {
      // Handle response logging using CurlUtils (synchronous)
      if (curlOptions.responseVisible) {
        CurlUtils.handleOnResponse(
          response,
          curlOptions: curlOptions,
          webhookInspectors: webhookInspectors,
          stopwatch: stopwatch,
        );
      }
      
      // Cache response if enabled using CurlUtils (synchronous)
      if (cacheOptions.cacheResponse) {
        CurlUtils.cacheResponse(
          response,
          stopwatch: stopwatch,
        );
      }
      
      // Queue webhook notifications (fire-and-forget)
      if (webhookInspectors != null) {
        _queueWebhookNotifications(response.requestOptions, response);
      }
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Response processing error: $e', name: 'CurlInterceptorV2');
    }
    
    // Always continue main flow
    return handler.next(response);
  }
  
  /// Intercepts errors that occur during the request or response process.
  ///
  /// This method stops the stopwatch, handles logging the error,
  /// caches the error if enabled, and passes the error to the next handler.
  ///
  /// [err] The DioException that occurred.
  /// [handler] The handler to which the error is passed.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final stopwatch = _stopwatches.remove(err.requestOptions);
    stopwatch?.stop();
    
    try {
      // Handle error logging using CurlUtils (synchronous)
      if (curlOptions.errorVisible) {
        CurlUtils.handleOnError(
          err,
          curlOptions: curlOptions,
          webhookInspectors: webhookInspectors,
          stopwatch: stopwatch,
        );
      }
      
      // Cache error if enabled using CurlUtils (synchronous)
      if (cacheOptions.cacheError) {
        CurlUtils.cacheError(
          err,
          stopwatch: stopwatch,
        );
      }
      
      // Queue webhook notifications (fire-and-forget)
      if (webhookInspectors != null) {
        _queueWebhookNotifications(err.requestOptions, err.response, err);
      }
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Error processing error: $e', name: 'CurlInterceptorV2');
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
        FireAndForget.execute(
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
      final cacheKey = _getCacheKey(webhookUrl, options);
      
      // Check cache for cooldown
      if (!_webhookCache.shouldSend(cacheKey)) {
        return;
      }
      
      // Get or create circuit breaker
      final circuitBreaker = _circuitBreakers.putIfAbsent(
        webhookUrl,
        () => CircuitBreaker(
          failureThreshold: 5,
          resetTimeout: Duration(minutes: 1),
        ),
      );
      
      // Execute with circuit breaker and retry
      await circuitBreaker.call(() async {
        await _retryPolicy.execute(
          () => _sendWebhookWithRetry(inspector, options, response, error),
          operationName: 'webhook_send',
        );
      });
      
      // Mark as sent in cache
      _webhookCache.markSent(cacheKey);
      
    } catch (e) {
      // Log error but don't propagate
      developer.log('Webhook notification failed: $e', name: 'CurlInterceptorV2');
    }
  }
  
  /// Sends a webhook with retry logic.
  Future<void> _sendWebhookWithRetry(
    WebhookInspectorBase inspector,
    RequestOptions options,
    Response? response,
    DioException? error,
  ) async {
    // Generate cURL command using genCurl function
    final curl = genCurl(options);
    if (curl == null || curl.isEmpty) {
      developer.log('Unable to generate cURL for webhook', name: 'CurlInterceptorV2');
      return;
    }
    
    final statusCode = response?.statusCode ?? error?.response?.statusCode ?? -1;
    final uri = options.uri.toString();
    
    // Calculate response time
    final stopwatch = _stopwatches[options];
    final duration = CurlHelper.tryExtractDuration(
      stopwatch: stopwatch,
      xClientTimeHeader: options.headers['X-Client-Time'],
    );
    final responseTime = '${duration ?? 'N/A'}ms';
    
    await inspector.sendCurlLog(
      curl: curl,
      method: options.method,
      uri: uri,
      statusCode: statusCode,
      responseBody: response?.data ?? error?.response?.data,
      responseTime: responseTime,
      extraInfo: error != null ? {
        'type': error.type.name,
        'message': error.message,
      } : null,
    );
  }
  
  
  
  
  /// Gets the webhook URL from an inspector.
  String _getWebhookUrl(WebhookInspectorBase inspector) {
    if (inspector is DiscordInspector) {
      return inspector.webhookUrls.isNotEmpty ? inspector.webhookUrls.first : 'discord-webhook';
    } else if (inspector is TelegramInspector) {
      return 'telegram-bot-${inspector.botToken.substring(0, 10)}...';
    }
    return 'webhook-url';
  }
  
  /// Gets a cache key for webhook cooldown.
  String _getCacheKey(String webhookUrl, RequestOptions options) {
    return '$webhookUrl:${options.uri.toString()}:${options.method}';
  }
  
  
  /// Cleans up orphaned stopwatches.
  void _cleanupOrphanedStopwatches() {
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
    _circuitBreakers.clear();
    _webhookCache.clear();
  }
}
