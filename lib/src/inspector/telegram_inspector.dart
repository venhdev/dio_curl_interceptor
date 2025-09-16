// ignore_for_file: unintended_html_in_doc_comment

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:type_caster/type_caster.dart';

import '../core/constants.dart';
import '../core/types.dart';
import '../data/models/sender_info.dart';
import '../interceptors/dio_curl_interceptor_base.dart';
import 'webhook_inspector_base.dart';

/// Options for configuring Telegram Bot API integration for cURL logging.
///
/// This class allows you to define rules for when and how cURL logs
/// are sent to Telegram chats via the Telegram Bot API, including URL filtering 
/// and status code-based inspection.
class TelegramInspector extends WebhookInspectorBase {
  /// Creates a [TelegramInspector] instance.
  ///
  /// [botToken] The Telegram bot token obtained from @BotFather.
  /// [chatIds] A list of chat IDs where messages will be sent. Can be:
  ///   - Positive integers for private chats (e.g., 123456789)
  ///   - Negative integers for groups/supergroups (e.g., -1003019608685)
  ///   - Channel usernames with @ prefix (e.g., @channelusername)
  /// [includeUrls] A list of URI patterns to include for inspection. If not empty,
  ///   only requests matching any of these patterns will be sent.
  /// [excludeUrls] A list of URI patterns to exclude from inspection. If not empty,
  ///   requests matching any of these patterns will NOT be sent.
  /// [inspectionStatus] A list of [ResponseStatus] types that trigger webhook notifications.
  /// [senderInfo] Optional sender information (username, avatar) for webhook messages.
  /// [dio] Optional Dio instance for making HTTP requests to Telegram API.
  const TelegramInspector({
    required this.botToken,
    required this.chatIds,
    super.includeUrls = const [],
    super.excludeUrls = const [],
    super.inspectionStatus = defaultInspectionStatus,
    super.senderInfo,
    this.dio,
  }) : super(webhookUrls: const <String>[]);

  /// The Telegram bot token obtained from @BotFather
  final String botToken;

  /// List of chat IDs where messages will be sent
  final List<dynamic> chatIds;

  /// The Dio instance for making HTTP requests to Telegram API
  final Dio? dio;

  TelegramWebhookSender get S => TelegramWebhookSender(
        botToken: botToken,
        chatIds: chatIds,
        dio: dio,
      );
  TelegramWebhookSender toSender([Dio? dio]) => TelegramWebhookSender(
        botToken: botToken,
        chatIds: chatIds,
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

/// A class to handle sending cURL logs and other messages to Telegram via Bot API.
///
/// This class provides methods to send various types of information,
/// including cURL commands, bug reports, and simple messages, to Telegram chats
/// using the official Telegram Bot API.
class TelegramWebhookSender {
  /// Creates a [TelegramWebhookSender] instance.
  ///
  /// [botToken] The Telegram bot token obtained from @BotFather.
  /// [chatIds] A list of chat IDs where messages will be sent.
  /// [dio] An optional Dio instance to use for making HTTP requests to Telegram API.
  TelegramWebhookSender({
    required this.botToken,
    required this.chatIds,
    Dio? dio,
  }) : _dio = dio ?? Dio()
          ..interceptors.add(CurlInterceptor());

  /// The Telegram bot token
  final String botToken;

  /// List of chat IDs where messages will be sent
  final List<dynamic> chatIds;

  /// The Dio instance for making HTTP requests to Telegram API
  final Dio _dio;

  /// Maximum message length allowed by Telegram API
  static const int maxMessageLength = 4096;

  /// Sends a cURL log to all configured Telegram chats.
  ///
  /// This method formats the cURL command and response details into a Telegram message
  /// and sends it using the proper Telegram Bot API.
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
  /// from each successful API call.
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
    final message = createCurlMessage(
      curl: curl,
      method: method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: responseTime,
      extraInfo: extraInfo,
    );

    return await _sendMessage(message);
  }

  /// Sends a bug report or exception details to Telegram chats.
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
    final content = createBugReportMessage(
      error: error,
      stackTrace: stackTrace,
      message: message,
      extraInfo: extraInfo,
    );

    return await _sendMessage(content);
  }

  /// Sends a simple message to Telegram chats.
  ///
  /// [content] The message content to send.
  /// [senderInfo] Optional sender information for the webhook message.
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    return await _sendMessage(content);
  }

  /// Core method to send a message to all configured Telegram chats.
  ///
  /// This method handles the actual API communication with Telegram Bot API,
  /// including message truncation, error handling, and rate limiting.
  Future<List<Response>> _sendMessage(String message) async {
    final List<Response> responses = [];

    // Try HTML formatting first
    try {
      final truncatedMessage = _truncateMessage(message);
      responses.addAll(await _sendHtmlMessage(truncatedMessage));
    } catch (e) {
      log('HTML message sending failed, trying plain text fallback: $e',
          name: 'TelegramWebhookSender');
      
      // Fallback to plain text
      try {
        final plainTextMessage = _convertToPlainText(message);
        responses.addAll(await _sendPlainTextMessage(plainTextMessage));
      } catch (fallbackError) {
        log('Plain text fallback also failed: $fallbackError',
            name: 'TelegramWebhookSender');
      }
    }

    return responses;
  }

  /// Sends an HTML-formatted message to all configured chats.
  Future<List<Response>> _sendHtmlMessage(String message) async {
    final List<Response> responses = [];

    for (final dynamic chatId in chatIds) {
      try {
        final telegramMessage = {
          'chat_id': chatId,
          'text': message,
          'parse_mode': 'HTML',
        };

        final response = await _dio.post(
          'https://api.telegram.org/bot$botToken/sendMessage',
          data: telegramMessage,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final responseData = response.data;
        if (responseData is Map<String, dynamic> && 
            responseData['ok'] == true) {
          responses.add(response);
        } else {
          throw Exception('Telegram API error: $responseData');
        }
      } catch (e) {
        log('Error sending HTML message to Telegram chat $chatId: $e',
            name: 'TelegramWebhookSender');
        rethrow;
      }
    }

    return responses;
  }

  /// Sends a plain text message to all configured chats.
  Future<List<Response>> _sendPlainTextMessage(String message) async {
    final List<Response> responses = [];

    for (final dynamic chatId in chatIds) {
      try {
        final telegramMessage = {
          'chat_id': chatId,
          'text': message,
          // No parse_mode for plain text
        };

        final response = await _dio.post(
          'https://api.telegram.org/bot$botToken/sendMessage',
          data: telegramMessage,
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );

        final responseData = response.data;
        if (responseData is Map<String, dynamic> && 
            responseData['ok'] == true) {
          responses.add(response);
        } else {
          log('Telegram API returned error for plain text: $responseData',
              name: 'TelegramWebhookSender');
        }
      } catch (e) {
        log('Error sending plain text message to Telegram chat $chatId: $e',
            name: 'TelegramWebhookSender');
      }
    }

    return responses;
  }

  /// Converts HTML content to plain text for fallback sending.
  String _convertToPlainText(String htmlContent) {
    // Simple HTML to plain text conversion
    String plainText = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    // Truncate if still too long
    if (plainText.length > maxMessageLength) {
      const truncationIndicator = '\n\n⚠️ Message truncated due to length limit';
      final maxContentLength = maxMessageLength - truncationIndicator.length;
      plainText = plainText.substring(0, maxContentLength) + truncationIndicator;
    }

    return plainText;
  }

  /// Finds a safe truncation point that doesn't break HTML tags.
  ///
  /// This method scans backwards from the desired length to find a position
  /// that is outside of any HTML tags, ensuring valid HTML structure.
  ///
  /// [message] The message to find a safe truncation point for.
  /// [maxLength] The maximum desired length for the truncated message.
  /// Returns the index of a safe truncation point.
  int _findSafeTruncationPoint(String message, int maxLength) {
    if (maxLength >= message.length) {
      return message.length;
    }

    // Start from the desired length and work backwards
    int safePoint = maxLength;
    bool insideTag = false;
    bool insideEntity = false;
    
    // Scan backwards to find a safe point
    for (int i = maxLength - 1; i >= 0; i--) {
      final char = message[i];
      
      // Handle HTML entities (like &amp;, &lt;, etc.)
      if (char == ';' && i > 0 && message[i - 1] != ';') {
        // Check if this is the end of an HTML entity
        int entityStart = i - 1;
        while (entityStart >= 0 && 
               message[entityStart] != '&' && 
               message[entityStart] != ' ' && 
               message[entityStart] != '\n') {
          entityStart--;
        }
        if (entityStart >= 0 && message[entityStart] == '&') {
          insideEntity = true;
          i = entityStart;
          continue;
        }
      }
      
      if (char == '&' && !insideEntity) {
        insideEntity = true;
        continue;
      }
      
      if (insideEntity) {
        if (char == ' ' || char == '\n' || char == '<' || char == '>') {
          insideEntity = false;
        } else {
          continue;
        }
      }
      
      // Handle HTML tags
      if (char == '>') {
        insideTag = false;
        safePoint = i + 1;
        break;
      }
      
      if (char == '<') {
        insideTag = true;
        continue;
      }
      
      if (insideTag) {
        continue;
      }
      
      // Found a safe point outside of tags and entities
      if (char == '\n' || char == ' ' || char == '.' || char == '!' || char == '?') {
        safePoint = i + 1;
        break;
      }
    }
    
    // Ensure we don't truncate in the middle of a word if possible
    if (safePoint < maxLength && safePoint > 0) {
      // Look for word boundaries near the safe point
      for (int i = safePoint; i < maxLength && i < message.length; i++) {
        if (message[i] == ' ' || message[i] == '\n') {
          safePoint = i;
          break;
        }
      }
    }
    
    return safePoint;
  }

  /// Closes any open HTML tags in the truncated content to ensure valid HTML structure.
  ///
  /// This method parses the content and closes any unclosed HTML tags,
  /// ensuring that the resulting HTML is valid and won't cause parsing errors.
  ///
  /// [content] The content that may have unclosed HTML tags.
  /// Returns the content with all HTML tags properly closed.
  String _closeOpenTags(String content) {
    final List<String> openTags = [];
    final StringBuffer result = StringBuffer();
    int i = 0;
    
    while (i < content.length) {
      if (content[i] == '<') {
        // Find the end of the tag
        int tagEnd = content.indexOf('>', i);
        if (tagEnd == -1) {
          // Incomplete tag at the end, just append the rest
          result.write(content.substring(i));
          break;
        }
        
        final String tag = content.substring(i + 1, tagEnd);
        result.write(content.substring(i, tagEnd + 1));
        
        // Handle the tag
        if (tag.startsWith('/')) {
          // Closing tag - remove from open tags
          final String tagName = tag.substring(1).split(' ')[0];
          for (int j = openTags.length - 1; j >= 0; j--) {
            if (openTags[j] == tagName) {
              openTags.removeAt(j);
              break;
            }
          }
        } else if (!tag.endsWith('/') && !_isSelfClosingTag(tag)) {
          // Opening tag - add to open tags
          final String tagName = tag.split(' ')[0];
          openTags.add(tagName);
        }
        
        i = tagEnd + 1;
      } else {
        result.write(content[i]);
        i++;
      }
    }
    
    // Close any remaining open tags in reverse order
    for (int j = openTags.length - 1; j >= 0; j--) {
      result.write('</${openTags[j]}>');
    }
    
    return result.toString();
  }

  /// Checks if a tag is self-closing (like <br>, <hr>, etc.).
  ///
  /// [tag] The tag content without angle brackets.
  /// Returns true if the tag is self-closing.
  bool _isSelfClosingTag(String tag) {
    const selfClosingTags = {
      'br', 'hr', 'img', 'input', 'meta', 'link', 'area', 'base',
      'col', 'embed', 'source', 'track', 'wbr'
    };
    
    final tagName = tag.split(' ')[0].toLowerCase();
    return selfClosingTags.contains(tagName);
  }

  /// Truncates a message using HTML-aware truncation to maintain valid HTML structure.
  ///
  /// This method combines safe truncation point finding with HTML tag closing
  /// to ensure the resulting message has valid HTML that won't cause parsing errors.
  ///
  /// [message] The message to truncate.
  /// Returns the truncated message with valid HTML structure.
  String _truncateMessageHtmlAware(String message) {
    if (message.length <= maxMessageLength) {
      return message;
    }

    const truncationIndicator = '\n\n⚠️ <i>Message truncated due to length limit</i>';
    final maxContentLength = maxMessageLength - truncationIndicator.length;
    
    // Find a safe truncation point that doesn't break HTML tags
    final safeTruncationPoint = _findSafeTruncationPoint(message, maxContentLength);
    
    // Truncate at the safe point
    final truncatedContent = message.substring(0, safeTruncationPoint);
    
    // Close any open HTML tags
    final validHtmlContent = _closeOpenTags(truncatedContent);
    
    return validHtmlContent + truncationIndicator;
  }

  /// Truncates a message to fit within Telegram's character limit.
  ///
  /// If the message exceeds [maxMessageLength], it will be truncated and
  /// a truncation indicator will be added. Uses HTML-aware truncation to
  /// maintain valid HTML structure.
  String _truncateMessage(String message) {
    try {
      return _truncateMessageHtmlAware(message);
    } catch (e) {
      // Fallback to simple truncation if HTML parsing fails
      log('HTML-aware truncation failed, falling back to simple truncation: $e',
          name: 'TelegramWebhookSender');
      
      if (message.length <= maxMessageLength) {
        return message;
      }

      const truncationIndicator = '\n\n⚠️ <i>Message truncated due to length limit</i>';
      final maxContentLength = maxMessageLength - truncationIndicator.length;
      
      return message.substring(0, maxContentLength) + truncationIndicator;
    }
  }

  /// Escapes HTML entities in text to prevent Telegram API parsing errors.
  ///
  /// This method properly escapes special characters that could break HTML parsing
  /// in Telegram messages, including quotes, angle brackets, and ampersands.
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Formats a value for Telegram messages without markdown code blocks.
  ///
  /// This method formats structured data for Telegram without adding markdown
  /// backticks, since Telegram uses HTML formatting instead of markdown.
  String _formatForTelegram(dynamic rawValue) {
    if (rawValue is Map || rawValue is List) {
      // Use proper JSON formatting for structured data
      try {
        return indentJson(rawValue, indent: '  ');
      } catch (e) {
        // Fallback to stringify if JSON encoding fails
        return stringify(rawValue, maxLen: 1000, replacements: const {'```': ''});
      }
    } else {
      // Use stringify for other types
      return stringify(rawValue, maxLen: 1000, replacements: const {'```': ''});
    }
  }

  /// Creates a formatted cURL message for Telegram.
  String createCurlMessage({
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
    buffer.writeln('<b>Method:</b> ${_escapeHtml(method)}');
    buffer.writeln('<b>URL:</b> <code>${_escapeHtml(uri)}</code>');
    buffer.writeln('<b>Status:</b> $statusCode');

    if (responseTime != null) {
      buffer.writeln('<b>Response Time:</b> ${_escapeHtml(responseTime)}');
    }

    if (curl != null && curl.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('<b>cURL Command:</b>');
      buffer.writeln('<pre><code>${_escapeHtml(curl)}</code></pre>');
    }

    if (responseBody != null) {
      buffer.writeln('');
      buffer.writeln('<b>Response Body:</b>');
      final formattedBody = _formatForTelegram(responseBody);
      buffer.writeln('<pre><code>${_escapeHtml(formattedBody)}</code></pre>');
    }

    if (extraInfo != null && extraInfo.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('<b>Extra Info:</b>');
      final formattedInfo = _formatForTelegram(extraInfo);
      buffer.writeln('<pre><code>${_escapeHtml(formattedInfo)}</code></pre>');
    }

    buffer.writeln('');
    buffer.writeln(
        '<i>Timestamp: ${_escapeHtml(DateTime.now().toUtc().toIso8601String())}</i>');

    return buffer.toString();
  }

  /// Creates a formatted bug report message for Telegram.
  String createBugReportMessage({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('🚨 <b>Bug Report / Exception</b>');
    buffer.writeln('');

    if (message != null) {
      buffer.writeln('<b>Message:</b> ${_escapeHtml(message)}');
      buffer.writeln('');
    }

    buffer.writeln('<b>Error:</b>');
    buffer.writeln('<pre><code>${_escapeHtml(_formatForTelegram(error))}</code></pre>');

    if (stackTrace != null) {
      buffer.writeln('');
      buffer.writeln('<b>Stack Trace:</b>');
      buffer.writeln('<pre><code>${_escapeHtml(_formatForTelegram(stackTrace))}</code></pre>');
    }

    if (extraInfo != null && extraInfo.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('<b>Extra Info:</b>');
      final formattedInfo = _formatForTelegram(extraInfo);
      buffer.writeln('<pre><code>${_escapeHtml(formattedInfo)}</code></pre>');
    }

    buffer.writeln('');
    buffer.writeln(
        '<i>Timestamp: ${_escapeHtml(DateTime.now().toUtc().toIso8601String())}</i>');

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
