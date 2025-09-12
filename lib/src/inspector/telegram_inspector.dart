import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/types.dart';
import '../core/utils/webhook_utils.dart';
import '../interceptors/dio_curl_interceptor_base.dart';
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
    this.dio,
  });

  /// The Dio instance for making HTTP requests to Telegram API
  final Dio? dio;

  TelegramWebhookSender get S => TelegramWebhookSender(hookUrls: webhookUrls);
  TelegramWebhookSender toSender([Dio? dio]) => TelegramWebhookSender(
        hookUrls: webhookUrls,
        dio: dio ?? this.dio,
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
    Dio? dio,
  }) : _dio = dio ?? Dio()
          ..interceptors.add(CurlInterceptor());

  /// The Dio instance for making HTTP requests to Telegram API
  final Dio _dio;

  /// Sends a cURL log to all configured Telegram webhooks.
  ///
  /// This method formats the cURL command and response details into a Telegram message
  /// and sends it using the proper Telegram API format.
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

    final List<Response> responses = [];

    for (final String hookUrl in hookUrls) {
      try {
        // Extract chat_id from the webhook URL
        final chatId = _extractChatIdFromUrl(hookUrl);
        if (chatId == null) {
          log('Warning: No chat_id found in Telegram webhook URL: $hookUrl',
              name: 'TelegramWebhookSender');
          continue;
        }

        final telegramMessage = {
          'chat_id':
              chatId.startsWith('@') ? chatId.trim() : _parseChatId(chatId),
          'text': message,
          'parse_mode': 'HTML',
        };

        // Construct the proper Telegram API URL
        final apiUrl = _constructTelegramApiUrl(hookUrl);

        final response = await _dio.post(
          apiUrl,
          data: telegramMessage,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        responses.add(response);
      } catch (e) {
        log('Error sending cURL log to Telegram webhook $hookUrl: $e',
            name: 'TelegramWebhookSender');
      }
    }

    return responses;
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

    final List<Response> responses = [];

    for (final String hookUrl in hookUrls) {
      try {
        // Extract chat_id from the webhook URL
        final chatId = _extractChatIdFromUrl(hookUrl);
        if (chatId == null) {
          log('Warning: No chat_id found in Telegram webhook URL: $hookUrl',
              name: 'TelegramWebhookSender');
          continue;
        }

        final telegramMessage = {
          'chat_id': chatId,
          'text': content,
          'parse_mode': 'HTML',
        };

        // Construct the proper Telegram API URL
        final apiUrl = _constructTelegramApiUrl(hookUrl);

        final response = await _dio.post(
          apiUrl,
          data: telegramMessage,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        responses.add(response);
      } catch (e) {
        log('Error sending bug report to Telegram webhook $hookUrl: $e',
            name: 'TelegramWebhookSender');
      }
    }

    return responses;
  }

  /// Sends a simple message to Telegram webhooks.
  ///
  /// [content] The message content to send.
  /// [senderInfo] Optional sender information for the webhook message.
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    final List<Response> responses = [];

    for (final String hookUrl in hookUrls) {
      try {
        // Extract chat_id from the webhook URL or use a default
        final chatId = _extractChatIdFromUrl(hookUrl);
        if (chatId == null) {
          log('Warning: No chat_id found in Telegram webhook URL: $hookUrl',
              name: 'TelegramWebhookSender');
          continue;
        }

        final telegramMessage = {
          'chat_id': chatId,
          'text': content,
          'parse_mode': 'HTML',
        };

        // Construct the proper Telegram API URL
        final apiUrl = _constructTelegramApiUrl(hookUrl);

        final response = await _dio.post(
          apiUrl,
          data: telegramMessage,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        responses.add(response);
      } catch (e) {
        log('Error sending message to Telegram webhook $hookUrl: $e',
            name: 'TelegramWebhookSender');
      }
    }

    return responses;
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
      buffer.writeln('<b>Caption:</b> ${payload['caption']}');
    }

    final content = buffer.toString();
    final List<Response> responses = [];

    for (final String hookUrl in hookUrls) {
      try {
        // Extract chat_id from the webhook URL
        final chatId = _extractChatIdFromUrl(hookUrl);
        if (chatId == null) {
          log('Warning: No chat_id found in Telegram webhook URL: $hookUrl',
              name: 'TelegramWebhookSender');
          continue;
        }

        final telegramMessage = {
          'chat_id': chatId,
          'text': content,
          'parse_mode': 'HTML',
        };

        // Construct the proper Telegram API URL
        final apiUrl = _constructTelegramApiUrl(hookUrl);

        final response = await _dio.post(
          apiUrl,
          data: telegramMessage,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        responses.add(response);
      } catch (e) {
        log('Error sending files info to Telegram webhook $hookUrl: $e',
            name: 'TelegramWebhookSender');
      }
    }

    return responses;
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

  /// Extracts chat_id from a Telegram webhook URL.
  ///
  /// Supports URLs in the format:
  /// - https://api.telegram.org/bot<token>/sendMessage?chat_id=<chat_id>
  /// - https://api.telegram.org/bot<token>/sendMessage#chat_id=<chat_id>
  /// - https://api.telegram.org/bot<token>/sendMessage (returns null, requires manual chat_id)
  String? _extractChatIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Check query parameters first
      final chatIdFromQuery = uri.queryParameters['chat_id'];
      if (chatIdFromQuery != null && chatIdFromQuery.isNotEmpty) {
        return chatIdFromQuery;
      }

      // Check fragment (hash) parameters
      final fragmentParams = uri.fragment
          .split('&')
          .where((param) => param.startsWith('chat_id='));
      final chatIdFromFragment =
          fragmentParams.isNotEmpty ? fragmentParams.first.split('=')[1] : null;
      if (chatIdFromFragment != null && chatIdFromFragment.isNotEmpty) {
        return chatIdFromFragment;
      }

      return null;
    } catch (e) {
      log('Error parsing Telegram webhook URL: $e',
          name: 'TelegramWebhookSender');
      return null;
    }
  }

  /// Parses chat ID, handling both positive and negative integers
  dynamic _parseChatId(String chatId) {
    try {
      // Handle negative numbers (like -1003019608685)
      if (chatId.startsWith('-')) {
        return int.parse(chatId);
      }
      // Handle positive numbers
      return int.parse(chatId);
    } catch (e) {
      // If parsing fails, return as string (for usernames)
      return chatId;
    }
  }

  /// Constructs the proper Telegram API URL for sendMessage.
  ///
  /// Converts URLs like:
  /// - https://api.telegram.org/bot<token>/sendMessage?chat_id=<chat_id>
  ///   to https://api.telegram.org/bot<token>/sendMessage
  String _constructTelegramApiUrl(String webhookUrl) {
    try {
      final uri = Uri.parse(webhookUrl);

      // Remove query parameters and fragment, keep only the base path
      return Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.port,
        path: uri.path,
      ).toString();
    } catch (e) {
      log('Error constructing Telegram API URL: $e',
          name: 'TelegramWebhookSender');
      return webhookUrl; // Return original URL as fallback
    }
  }
}
