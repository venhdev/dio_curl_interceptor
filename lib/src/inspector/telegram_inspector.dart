import 'dart:io';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/types.dart';
import '../core/utils/webhook_utils.dart';
import 'webhook_inspector_base.dart';

/// Options for configuring Telegram webhook integration for cURL logging.
///
/// This class allows you to define rules for when and how cURL logs
/// are sent to Telegram, including URL filtering and status code-based inspection.
class TelegramInspector extends WebhookInspectorBase {
  /// Creates a [TelegramInspector] instance.
  ///
  /// [webhookUrls] A list of Telegram webhook URLs to send logs to.
  /// [includeUrls] A list of URI patterns to include for inspection. If not empty,
  ///   only requests matching any of these patterns will be sent.
  /// [excludeUrls] A list of URI patterns to exclude from inspection. If not empty,
  ///   requests matching any of these patterns will NOT be sent.
  /// [inspectionStatus] A list of [ResponseStatus] types that trigger webhook notifications.
  /// [senderInfo] Optional sender information (username, avatar) for webhook messages.
  const TelegramInspector({
    super.webhookUrls = const <String>[],
    super.includeUrls = const [],
    super.excludeUrls = const [],
    super.inspectionStatus = defaultInspectionStatus,
    super.senderInfo,
  });

  TelegramWebhookSender get S => TelegramWebhookSender(hookUrls: webhookUrls);
  TelegramWebhookSender toSender([Dio? dio]) => TelegramWebhookSender(
        hookUrls: webhookUrls,
        dio: dio,
      );

  @override
  Future<List<Response>> sendCurlLog({
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    SenderInfo? senderInfo,
    Map<String, dynamic>? extraInfo,
  }) async {
    return S.sendCurlLog(
      curl: curl,
      method: method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: responseTime,
      senderInfo: senderInfo ?? this.senderInfo,
      extraInfo: extraInfo,
    );
  }

  @override
  Future<List<Response>> sendBugReport({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
    SenderInfo? senderInfo,
  }) async {
    return S.sendBugReport(
      error: error,
      stackTrace: stackTrace,
      message: message,
      extraInfo: extraInfo,
      senderInfo: senderInfo ?? this.senderInfo,
    );
  }

  @override
  Future<List<Response>> sendFiles({
    required List<String> paths,
    Map<String, dynamic>? payload,
    SenderInfo? senderInfo,
  }) async {
    return S.sendFiles(
      paths: paths,
      payload: payload,
      senderInfo: senderInfo ?? this.senderInfo,
    );
  }

  @override
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    return S.sendMessage(
      content: content,
      senderInfo: senderInfo ?? this.senderInfo,
    );
  }
}

/// A class to handle sending cURL logs and other messages to Telegram webhooks.
///
/// This class provides methods to send various types of information,
/// including cURL commands, bug reports, and simple messages, to Telegram channels.
class TelegramWebhookSender extends WebhookSenderBase {
  /// Creates a [TelegramWebhookSender] instance.
  ///
  /// [hookUrls] A list of Telegram webhook URLs where messages will be sent.
  /// [dio] An optional Dio instance to use for making HTTP requests to webhooks.
  TelegramWebhookSender({
    required super.hookUrls,
    super.dio,
  });

  /// Sends a cURL log to all configured Telegram webhooks.
  ///
  /// This method formats the cURL command and response details into a Telegram message
  /// and sends it using the [sendToAll] method.
  ///
  /// [curl] The cURL command string.
  /// [method] The HTTP method (e.g., 'GET', 'POST').
  /// [uri] The URI of the request.
  /// [statusCode] The HTTP status code of the response.
  /// [responseBody] (optional) The body of the response.
  /// [responseTime] (optional) The time taken for the response.
  /// [senderInfo] (optional) Sender information for the webhook message.
  /// [extraInfo] (optional) Additional information to include in the message.
  ///
  /// Returns a [Future] that completes with a list of [Response] objects
  /// from each successful webhook call.
  Future<List<Response>> sendCurlLog({
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    SenderInfo? senderInfo,
    Map<String, dynamic>? extraInfo,
  }) async {
    final message = _createCurlMessage(
      curl: curl,
      method: method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: responseTime,
      extraInfo: extraInfo,
    );

    return sendToAll(
      payload: message,
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Sends a bug report or exception details to Telegram webhooks.
  ///
  /// This method creates a Telegram message with details about an error or exception,
  /// including the error message, stack trace, and optional user information.
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
  }) async {
    final content = _createBugReportMessage(
      error: error,
      stackTrace: stackTrace,
      message: message,
      extraInfo: extraInfo,
    );

    final telegramMessage = {
      'text': content,
      'parse_mode': 'HTML',
    };

    return sendToAll(
      payload: telegramMessage,
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Sends a simple message to Telegram webhooks.
  ///
  /// [content] The message content to send.
  /// [senderInfo] Optional sender information for the webhook message.
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    final telegramMessage = {
      'text': content,
      'parse_mode': 'HTML',
    };

    return sendToAll(
      payload: telegramMessage,
      headers: {'Content-Type': 'application/json'},
    );
  }

  @override
  Future<List<Response>> sendFiles({
    required List<String> paths,
    Map<String, dynamic>? payload,
    SenderInfo? senderInfo,
  }) async {
    // Note: Telegram Bot API doesn't support direct file uploads via webhooks
    // This method sends a message with file information instead
    final buffer = StringBuffer();
    buffer.writeln('📎 <b>Files to be uploaded:</b>');
    buffer.writeln('');

    for (var i = 0; i < paths.length; i++) {
      final path = paths[i];
      final file = File(path);
      if (await file.exists()) {
        final size = await file.length();
        buffer.writeln('• <code>${path.split('/').last}</code> ($size bytes)');
      } else {
        buffer
            .writeln('• <code>${path.split('/').last}</code> (file not found)');
      }
    }

    if (payload != null && payload.containsKey('caption')) {
      buffer.writeln('');
      buffer.writeln('<b>Caption:</b> $payload[\'caption\']');
    }

    final telegramMessage = {
      'text': buffer.toString(),
      'parse_mode': 'HTML',
    };

    return sendToAll(
      payload: telegramMessage,
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Creates a formatted cURL message for Telegram.
  String _createCurlMessage({
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    Map<String, dynamic>? extraInfo,
  }) {
    final buffer = StringBuffer();

    // Status emoji based on status code
    final statusEmoji = _getStatusEmoji(statusCode);

    buffer.writeln('$statusEmoji <b>HTTP Request</b>');
    buffer.writeln('');
    buffer.writeln('<b>Method:</b> $method');
    buffer.writeln('<b>URL:</b> <code>$uri</code>');
    buffer.writeln('<b>Status:</b> $statusCode');

    if (responseTime != null) {
      buffer.writeln('<b>Response Time:</b> $responseTime');
    }

    if (curl != null && curl.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('<b>cURL Command:</b>');
      buffer.writeln('<pre><code>$curl</code></pre>');
    }

    if (responseBody != null) {
      buffer.writeln('');
      buffer.writeln('<b>Response Body:</b>');
      final formattedBody = formatEmbedValue(responseBody, lang: 'json');
      buffer.writeln('<pre><code>$formattedBody</code></pre>');
    }

    if (extraInfo != null && extraInfo.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('<b>Extra Info:</b>');
      final formattedInfo = formatEmbedValue(extraInfo, lang: 'json');
      buffer.writeln('<pre><code>$formattedInfo</code></pre>');
    }

    buffer.writeln('');
    buffer.writeln(
        '<i>Timestamp: ${DateTime.now().toUtc().toIso8601String()}</i>');

    return buffer.toString();
  }

  /// Creates a formatted bug report message for Telegram.
  String _createBugReportMessage({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🚨 <b>Bug Report / Exception</b>');
    buffer.writeln('');

    if (message != null) {
      buffer.writeln('<b>Message:</b> $message');
      buffer.writeln('');
    }

    buffer.writeln('<b>Error:</b>');
    buffer.writeln('<pre><code>${formatEmbedValue(error)}</code></pre>');

    if (stackTrace != null) {
      buffer.writeln('');
      buffer.writeln('<b>Stack Trace:</b>');
      buffer.writeln('<pre><code>${formatEmbedValue(stackTrace)}</code></pre>');
    }

    if (extraInfo != null && extraInfo.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('<b>Extra Info:</b>');
      final formattedInfo = formatEmbedValue(extraInfo, lang: 'json');
      buffer.writeln('<pre><code>$formattedInfo</code></pre>');
    }

    buffer.writeln('');
    buffer.writeln(
        '<i>Timestamp: ${DateTime.now().toUtc().toIso8601String()}</i>');

    return buffer.toString();
  }

  /// Returns an appropriate emoji based on the HTTP status code.
  String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return '✅'; // Success
    } else if (statusCode >= 400 && statusCode < 500) {
      return '⚠️'; // Client error
    } else if (statusCode >= 500) {
      return '❌'; // Server error
    } else {
      return 'ℹ️'; // Other
    }
  }
}
