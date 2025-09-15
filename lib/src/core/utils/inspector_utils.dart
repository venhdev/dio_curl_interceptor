import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

/// Utility class for handling webhook inspections and caching across different webhook services.
///
/// This class provides a unified interface for working with various webhook inspectors
/// (Discord, Telegram, etc.) through the common [WebhookInspectorBase] interface,
/// and also handles caching of curl requests and responses.
class InspectorUtils {
  /// Creates an [InspectorUtils] instance.
  ///
  /// [webhookInspectors] A list of webhook inspectors for different services
  /// (Discord, Telegram, etc.) that will be used for inspection and file sending.
  /// [enableCaching] Whether to enable caching of curl requests and responses.
  InspectorUtils({
    this.webhookInspectors,
    this.enableCaching = true,
  });

  /// The webhook inspectors to use for inspection and file operations.
  /// Supports any service that extends [WebhookInspectorBase] (Discord, Telegram, etc.).
  final List<WebhookInspectorBase>? webhookInspectors;

  /// Whether to enable caching of curl requests and responses.
  /// When enabled, successful responses and errors will be cached using [CachedCurlStorage].
  final bool enableCaching;

  // in future we will add more inspection methods, such as logcat, etc.

  /// Inspects a request/response using all configured webhook inspectors and caches the result.
  ///
  /// This method delegates the inspection to all webhook inspectors,
  /// allowing them to handle the request/response according to their
  /// specific configuration (URL filtering, status code filtering, etc.).
  /// Additionally, if caching is enabled, it caches the curl command and response data.
  ///
  /// [requestOptions] The request options to inspect.
  /// [response] The response to inspect (if available).
  /// [err] Any error that occurred during the request.
  /// [stopwatch] Optional stopwatch for timing information.
  /// [senderInfo] Optional sender information for webhook messages.
  Future<void> inspect({
    required RequestOptions requestOptions,
    required Response? response,
    DioException? err,
    Stopwatch? stopwatch,
    SenderInfo? senderInfo,
  }) async {
    // Handle webhook inspections
    if (webhookInspectors != null && webhookInspectors!.isNotEmpty) {
      for (final webhookInspector in webhookInspectors!) {
        webhookInspector.inspectOn(
          options: requestOptions,
          response: response,
          err: err,
          stopwatch: stopwatch,
          senderInfo: senderInfo,
        );
      }
    }

    // Handle caching if enabled
    if (enableCaching) {
      if (err != null) {
        // Cache error response
        CurlUtils.cacheError(err, stopwatch: stopwatch);
      } else if (response != null) {
        // Cache successful response
        CurlUtils.cacheResponse(response, stopwatch: stopwatch);
      }
    }
  }
}
