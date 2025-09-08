import 'package:dio/dio.dart';
import 'package:dio_curl_interceptor/dio_curl_interceptor.dart';

/// Utility class for handling webhook inspections across different webhook services.
///
/// This class provides a unified interface for working with various webhook inspectors
/// (Discord, Telegram, etc.) through the common [WebhookInspectorBase] interface.
class InspectorUtils {
  /// Creates an [InspectorUtils] instance.
  ///
  /// [webhookInspectors] A list of webhook inspectors for different services
  /// (Discord, Telegram, etc.) that will be used for inspection and file sending.
  InspectorUtils({
    this.webhookInspectors,
  });

  /// The webhook inspectors to use for inspection and file operations.
  /// Supports any service that extends [WebhookInspectorBase] (Discord, Telegram, etc.).
  final List<WebhookInspectorBase>? webhookInspectors;

  // in future we will add more inspection methods, such as logcat, etc.

  /// Inspects a request/response using all configured webhook inspectors.
  ///
  /// This method delegates the inspection to all webhook inspectors,
  /// allowing them to handle the request/response according to their
  /// specific configuration (URL filtering, status code filtering, etc.).
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
  }

}
