import 'dart:developer';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/helpers/curl_helper.dart';
import '../core/types.dart';
import '../data/models/sender_info.dart';
import '../core/utils/curl_utils.dart';

/// Abstract base class for webhook inspectors.
///
/// This class provides common functionality for sending cURL logs and inspection data
/// to various webhook services like Discord, Telegram, etc.
abstract class WebhookInspectorBase {
  /// Creates a [WebhookInspectorBase] instance.
  ///
  /// [webhookUrls] A list of webhook URLs to send logs to.
  /// [includeUrls] A list of URI patterns to include for inspection. If not empty,
  ///   only requests matching any of these patterns will be sent.
  /// [excludeUrls] A list of URI patterns to exclude from inspection. If not empty,
  ///   requests matching any of these patterns will NOT be sent.
  /// [inspectionStatus] A list of [ResponseStatus] types that trigger webhook notifications.
  /// [senderInfo] Optional sender information (username, avatar) for webhook messages.
  const WebhookInspectorBase({
    required this.webhookUrls,
    this.includeUrls = const [],
    this.excludeUrls = const [],
    this.inspectionStatus = defaultInspectionStatus,
    this.senderInfo,
  });

  /// The webhook URLs to send logs to.
  final List<String> webhookUrls;

  /// List of URI patterns to include for webhook requests.
  /// If not empty, only requests matching any of these patterns will be sent.
  final List<String> includeUrls;

  /// List of URI patterns to exclude for webhook requests.
  /// If not empty, requests matching any of these patterns will NOT be sent.
  final List<String> excludeUrls;

  /// The type of inspection to perform.
  final List<ResponseStatus> inspectionStatus;

  /// Optional sender information for webhook messages.
  final SenderInfo? senderInfo;

  /// Determines if a given URI and status code match the inspection criteria.
  ///
  /// This method checks against [includeUrls], [excludeUrls], and [inspectionStatus]
  /// to decide if a request should trigger a webhook notification.
  ///
  /// [url] The URI of the request.
  /// [statusCode] The HTTP status code of the response.
  ///
  /// Returns `true` if the URI and status code match the criteria, `false` otherwise.
  bool isMatch(String url, int statusCode) {
    final statusMatch = inspectionStatus.isEmpty ||
        inspectionStatus.any((status) {
          switch (status) {
            case ResponseStatus.informational:
              return statusCode >= 100 && statusCode < 200;
            case ResponseStatus.success:
              return statusCode >= 200 && statusCode < 300;
            case ResponseStatus.redirection:
              return statusCode >= 300 && statusCode < 400;
            case ResponseStatus.clientError:
              return statusCode >= 400 && statusCode < 500;
            case ResponseStatus.serverError:
              return statusCode >= 500 && statusCode < 600;
            case ResponseStatus.unknown:
              return true; // Unknown status is always included
          }
        });

    final includeMatch = includeUrls.isEmpty ||
        includeUrls.any((filter) => url.contains(filter));

    final excludeMatch = excludeUrls.isEmpty ||
        !excludeUrls.any((filter) => url.contains(filter));

    // If both are provided, both must match.
    return includeMatch && excludeMatch && statusMatch;
  }

  void inspectOnResponse({
    required Response<dynamic> response,
    Stopwatch? stopwatch,
    SenderInfo? senderInfo,
  }) =>
      inspectOn(
        options: response.requestOptions,
        response: response,
        stopwatch: stopwatch,
        senderInfo: senderInfo,
      );

  void inspectOnError({
    required DioException err,
    Stopwatch? stopwatch,
    SenderInfo? senderInfo,
  }) =>
      inspectOn(
        options: err.requestOptions,
        response: err.response,
        err: err,
        stopwatch: stopwatch,
        senderInfo: senderInfo,
      );

  void inspectOn({
    required RequestOptions options,
    required Response<dynamic>? response,
    DioException? err,
    Stopwatch? stopwatch,
    SenderInfo? senderInfo,
  }) {
    final uri = options.uri.toString();
    final statusCode = response?.statusCode ?? -1;

    if (isMatch(uri, statusCode)) {
      final String? curl = genCurl(options);
      final dynamic responseBody = response?.data;
      int? duration = CurlHelper.tryExtractDuration(
        stopwatch: stopwatch,
        xClientTimeHeader: options.headers[kXClientTime],
      );

      // Use provided senderInfo or fall back to class-level senderInfo
      final effectiveSenderInfo = senderInfo ?? this.senderInfo;

      sendCurlLog(
        curl: curl,
        method: options.method,
        uri: uri,
        statusCode: statusCode,
        senderInfo: effectiveSenderInfo,
        responseTime: '$duration ms',
        responseBody: responseBody,
        extraInfo: err != null
            ? {'type': err.type.name, 'message': err.message}
            : null,
      );
    }
  }

  /// Abstract method to send cURL log to the webhook service.
  ///
  /// This method must be implemented by concrete webhook inspector classes
  /// to handle the specific format and API requirements of each service.
  ///
  /// [curl] The cURL command string.
  /// [method] The HTTP method (e.g., 'GET', 'POST').
  /// [uri] The URI of the request.
  /// [statusCode] The HTTP status code of the response.
  /// [responseBody] (optional) The body of the response.
  /// [responseTime] (optional) The time taken for the response.
  /// [senderInfo] (optional) Sender information for the webhook message.
  /// [extraInfo] (optional) Additional information to include in the message.
  Future<List<Response>> sendCurlLog({
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    SenderInfo? senderInfo,
    Map<String, dynamic>? extraInfo,
  });

  /// Abstract method to send a bug report or exception details to the webhook service.
  ///
  /// [error] The error object or message.
  /// [stackTrace] The stack trace associated with the error.
  /// [message] An optional descriptive message for the report.
  /// [extraInfo] Optional additional information about the user or context.
  /// [senderInfo] Optional sender information for the webhook message.
  Future<List<Response>> sendBugReport({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
    SenderInfo? senderInfo,
  });

  /// Abstract method to send a simple message to the webhook service.
  ///
  /// [content] The message content to send.
  /// [senderInfo] Optional sender information for the webhook message.
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  });
}

/// Abstract base class for webhook senders.
///
/// This class provides common functionality for sending data to various webhook services.
abstract class WebhookSenderBase {
  /// Creates a [WebhookSenderBase] instance.
  ///
  /// [hookUrls] A list of webhook URLs where messages will be sent.
  /// [dio] An optional Dio instance to use for making HTTP requests to webhooks.
  WebhookSenderBase({
    required this.hookUrls,
    Dio? dio,
  }) : _innerDio = dio ?? Dio();

  /// The webhook URLs to send messages to.
  final List<String> hookUrls;

  /// The Dio instance for making HTTP requests.
  final Dio _innerDio;

  /// Sends a message to all configured webhooks.
  ///
  /// This method iterates through the [hookUrls] and sends the provided
  /// [payload] to each one. Errors during sending to a specific webhook
  /// are caught and logged, but do not prevent sending to other webhooks.
  ///
  /// [payload] The payload to be sent to webhooks.
  /// [headers] Optional headers for the request.
  /// [contentType] Optional content type for the request.
  ///
  /// Returns a [Future] that completes with a list of [Response] objects
  /// from each successful webhook call.
  Future<List<Response>> sendToAll({
    required dynamic payload,
    Map<String, dynamic>? headers,
    String? contentType,
  }) async {
    final List<Response> responses = [];

    for (final String hookUrl in hookUrls) {
      try {
        final response = await _innerDio.post(
          hookUrl,
          data: payload,
          options: Options(
            headers:
                headers ?? {'Content-Type': contentType ?? 'application/json'},
          ),
        );
        responses.add(response);
      } catch (e) {
        // Handle errors silently to prevent disrupting the main application
        log('Error sending webhook to $hookUrl: $e', name: 'WebhookSenderBase');
      }
    }

    return responses;
  }
}
