// Webhook senders used by DiscordSink and TelegramSink. Private to the sinks
// layer — they are not part of the public API. Replace this file with an
// extracted package later if extraction-readiness is acted on.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:type_caster/type_caster.dart';

import '../core/constants.dart';
import '../data/models/discord_webhook_model.dart';
import '../data/models/sender_info.dart';

/// Delivery failure intentionally omits the remote URL and Dio exception,
/// which can contain webhook credentials.
class WebhookDeliveryException implements Exception {
  const WebhookDeliveryException(this.sinkName);
  final String sinkName;

  @override
  String toString() => '$sinkName delivery failed';
}

/// Common base for one-endpoint webhook senders.
abstract class WebhookSenderBase {
  WebhookSenderBase({
    required this.webhookUrl,
    Dio? dio,
  }) : _innerDio = dio ?? Dio();

  final String webhookUrl;
  final Dio _innerDio;

  Future<void> postPayload({
    required dynamic payload,
    Map<String, dynamic>? headers,
    String? contentType,
  }) async {
    try {
      await _innerDio.post(
        webhookUrl,
        data: payload,
        options: Options(
          headers:
              headers ?? {'Content-Type': contentType ?? 'application/json'},
        ),
      );
      return;
    } catch (_) {
      throw const WebhookDeliveryException('Discord');
    }
  }
}

// ─── Discord ────────────────────────────────────────────────────────────────

class DiscordWebhookSender extends WebhookSenderBase {
  DiscordWebhookSender({
    required super.webhookUrl,
    super.dio,
  });

  Future<void> send(DiscordWebhookMessage message) async {
    final String jsonPayload = jsonEncode(message.toJson());
    await postPayload(
      payload: jsonPayload,
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<void> sendCurlLog({
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    SenderInfo? senderInfo,
    Map<String, dynamic>? extraInfo,
  }) async {
    final embed = DiscordEmbed.createCurlEmbed(
      curl: curl ?? kNA,
      method: method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: responseTime,
      extraInfo: extraInfo,
    );
    final message = DiscordWebhookMessage(
      username: senderInfo?.username ?? kDefaultUsername,
      avatarUrl: senderInfo?.avatarUrl,
      embeds: [embed],
    );
    await send(message);
  }

  Future<void> sendBugReport({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
    SenderInfo? senderInfo,
  }) async {
    final List<DiscordEmbedField> fields = [
      DiscordEmbedField(
        name: 'Error',
        value: formatEmbedValue(error),
        inline: false,
      ),
    ];
    if (stackTrace != null) {
      fields.add(DiscordEmbedField(
        name: 'Stack Trace',
        value: formatEmbedValue(stackTrace),
        inline: false,
      ));
    }
    if (extraInfo != null) {
      fields.add(DiscordEmbedField(
        name: 'Extra Info',
        value: formatEmbedValue(extraInfo, lang: 'json'),
        inline: false,
      ));
    }
    final embed = DiscordEmbed(
      title: 'Bug Report / Exception',
      description: message ?? 'An unhandled exception occurred.',
      color: 15548997,
      fields: fields,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );
    final discordMessage = DiscordWebhookMessage(
      username: senderInfo?.username ?? kDefaultBugReporterUsername,
      avatarUrl: senderInfo?.avatarUrl,
      embeds: [embed],
    );
    await send(discordMessage);
  }

  Future<void> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    final message = DiscordWebhookMessage(
      content: content,
      username: senderInfo?.username ?? kDefaultUsername,
      avatarUrl: senderInfo?.avatarUrl,
    );
    await send(message);
  }
}

// ─── Telegram ────────────────────────────────────────────────────────────────

class TelegramWebhookSender {
  TelegramWebhookSender({
    required this.botToken,
    required this.chatId,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  final String botToken;
  final String chatId;
  final Dio _dio;
  static const int maxMessageLength = 4096;

  Future<void> sendCurlLog({
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
    await _sendMessage(message);
  }

  Future<void> sendBugReport({
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
    await _sendMessage(content);
  }

  Future<void> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    await _sendMessage(content);
  }

  Future<void> _sendMessage(String message) async {
    try {
      final truncatedMessage = _truncateMessage(message);
      await _sendHtmlMessage(truncatedMessage);
    } catch (_) {
      try {
        final plainTextMessage = _convertToPlainText(message);
        await _sendPlainTextMessage(plainTextMessage);
      } catch (_) {
        throw const WebhookDeliveryException('Telegram');
      }
    }
  }

  Future<void> _sendHtmlMessage(String message) async {
    final response = await _dio.post(
      'https://api.telegram.org/bot$botToken/sendMessage',
      data: {
        'chat_id': chatId,
        'text': message,
        'parse_mode': 'HTML',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final responseData = response.data;
    if (responseData is Map<String, dynamic> && responseData['ok'] == true) {
      return;
    } else {
      throw const WebhookDeliveryException('Telegram');
    }
  }

  Future<void> _sendPlainTextMessage(String message) async {
    final response = await _dio.post(
      'https://api.telegram.org/bot$botToken/sendMessage',
      data: {'chat_id': chatId, 'text': message},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final responseData = response.data;
    if (responseData is Map<String, dynamic> && responseData['ok'] == true) {
      return;
    } else {
      throw const WebhookDeliveryException('Telegram');
    }
  }

  String _convertToPlainText(String htmlContent) {
    String plainText = htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (plainText.length > maxMessageLength) {
      const truncationIndicator =
          '\n\n⚠️ Message truncated due to length limit';
      final maxContentLength = maxMessageLength - truncationIndicator.length;
      plainText =
          plainText.substring(0, maxContentLength) + truncationIndicator;
    }
    return plainText;
  }

  String _truncateMessage(String message) {
    try {
      if (message.length <= maxMessageLength) return message;
      const indicator = '\n\n⚠️ <i>Message truncated due to length limit</i>';
      final max = maxMessageLength - indicator.length;
      // Naive close: drop everything after `max`, then drop any unclosed <pre>.
      final cut = message.substring(0, max);
      final cleaned =
          cut.contains('<pre>') && !cut.contains('</pre>') ? '$cut</pre>' : cut;
      return cleaned + indicator;
    } catch (_) {
      if (message.length <= maxMessageLength) return message;
      const indicator = '\n\n⚠️ <i>Message truncated due to length limit</i>';
      return message.substring(0, maxMessageLength - indicator.length) +
          indicator;
    }
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  String _formatForTelegram(dynamic rawValue) {
    if (rawValue is Map || rawValue is List) {
      try {
        return indentJson(rawValue, indent: '  ');
      } catch (_) {
        return stringify(rawValue,
            maxLen: 1000, replacements: const {'```': ''});
      }
    }
    return stringify(rawValue, maxLen: 1000, replacements: const {'```': ''});
  }

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
    final emoji = _getStatusEmoji(statusCode);
    buffer.writeln('$emoji <b>HTTP Request</b>');
    buffer.writeln();
    buffer.writeln('<b>Method:</b> ${_escapeHtml(method)}');
    buffer.writeln('<b>URL:</b> <code>${_escapeHtml(uri)}</code>');
    buffer.writeln('<b>Status:</b> $statusCode');
    if (responseTime != null) {
      buffer.writeln('<b>Response Time:</b> ${_escapeHtml(responseTime)}');
    }
    if (curl != null && curl.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('<b>cURL Command:</b>');
      buffer.writeln('<pre><code>${_escapeHtml(curl)}</code></pre>');
    }
    if (responseBody != null) {
      buffer.writeln();
      buffer.writeln('<b>Response Body:</b>');
      final formatted = _formatForTelegram(responseBody);
      buffer.writeln('<pre><code>${_escapeHtml(formatted)}</code></pre>');
    }
    if (extraInfo != null && extraInfo.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('<b>Extra Info:</b>');
      final formatted = _formatForTelegram(extraInfo);
      buffer.writeln('<pre><code>${_escapeHtml(formatted)}</code></pre>');
    }
    buffer.writeln();
    buffer.writeln(
        '<i>Timestamp: ${_escapeHtml(DateTime.now().toUtc().toIso8601String())}</i>');
    return buffer.toString();
  }

  String _createBugReportMessage({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 <b>Bug Report / Exception</b>');
    buffer.writeln();
    if (message != null) {
      buffer.writeln('<b>Message:</b> ${_escapeHtml(message)}');
      buffer.writeln();
    }
    buffer.writeln('<b>Error:</b>');
    buffer.writeln(
        '<pre><code>${_escapeHtml(_formatForTelegram(error))}</code></pre>');
    if (stackTrace != null) {
      buffer.writeln();
      buffer.writeln('<b>Stack Trace:</b>');
      buffer.writeln(
          '<pre><code>${_escapeHtml(_formatForTelegram(stackTrace))}</code></pre>');
    }
    if (extraInfo != null && extraInfo.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('<b>Extra Info:</b>');
      final formatted = _formatForTelegram(extraInfo);
      buffer.writeln('<pre><code>${_escapeHtml(formatted)}</code></pre>');
    }
    buffer.writeln();
    buffer.writeln(
        '<i>Timestamp: ${_escapeHtml(DateTime.now().toUtc().toIso8601String())}</i>');
    return buffer.toString();
  }

  String _getStatusEmoji(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return '✅';
    if (statusCode >= 400 && statusCode < 500) return '⚠️';
    if (statusCode >= 500) return '❌';
    return 'ℹ️';
  }
}
