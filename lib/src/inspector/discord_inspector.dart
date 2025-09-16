import 'dart:convert';

import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/types.dart';
import '../data/models/sender_info.dart';
import '../core/utils/webhook_utils.dart';
import '../data/models/discord_webhook_model.dart';
import 'webhook_inspector_base.dart';

/// Options for configuring Discord webhook integration for cURL logging.
///
/// This class allows you to define rules for when and how cURL logs
/// are sent to Discord, including URL filtering and status code-based inspection.
class DiscordInspector extends WebhookInspectorBase {
  /// Creates a [DiscordInspector] instance.
  ///
  /// [webhookUrls] A list of Discord webhook URLs to send logs to.
  /// [includeUrls] A list of URI patterns to include for inspection. If not empty,
  ///   only requests matching any of these patterns will be sent.
  /// [excludeUrls] A list of URI patterns to exclude from inspection. If not empty,
  ///   requests matching any of these patterns will NOT be sent.
  /// [inspectionStatus] A list of [ResponseStatus] types that trigger webhook notifications.
  /// [senderInfo] Optional sender information (username, avatar) for webhook messages.
  const DiscordInspector({
    super.webhookUrls = const <String>[],
    super.includeUrls = const [],
    super.excludeUrls = const [],
    super.inspectionStatus = defaultInspectionStatus,
    super.senderInfo,
  });

  DiscordWebhookSender get S => DiscordWebhookSender(hookUrls: webhookUrls);
  DiscordWebhookSender toSender([Dio? dio]) => DiscordWebhookSender(
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

/// A class to handle sending cURL logs and other messages to Discord webhooks.
///
/// This class provides methods to send various types of information,
/// including cURL commands, bug reports, and simple messages, to Discord channels.
class DiscordWebhookSender extends WebhookSenderBase {
  /// Creates an [DiscordWebhookSender] instance.
  ///
  /// [hookUrls] A list of Discord webhook URLs where messages will be sent.
  /// [dio] An optional Dio instance to use for making HTTP requests to webhooks.
  DiscordWebhookSender({
    required super.hookUrls,
    super.dio,
  });

  /// Sends a message to all configured Discord webhooks.
  ///
  /// Returns a list of responses from each webhook.
  /// Sends a [DiscordWebhookMessage] to all configured Discord webhooks.
  ///
  /// This method iterates through the [hookUrls] and sends the provided
  /// [message] to each one. Errors during sending to a specific webhook
  /// are caught and printed, but do not prevent sending to other webhooks.
  ///
  /// [message] The message to be sent to Discord.
  ///
  /// Returns a [Future] that completes with a list of [Response] objects
  /// from each successful webhook call.
  Future<List<Response>> send(DiscordWebhookMessage message) async {
    final String jsonPayload = jsonEncode(message.toJson());
    return sendToAll(
      payload: jsonPayload,
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Sends a cURL log to all configured Discord webhooks.
  /// Sends a cURL log as a Discord embed to all configured webhooks.
  ///
  /// This method formats the cURL command and response details into a Discord embed
  /// and sends it using the [send] method.
  ///
  /// [curl] The cURL command string.
  /// [method] The HTTP method (e.g., 'GET', 'POST').
  /// [uri] The URI of the request.
  /// [statusCode] The HTTP status code of the response.
  /// [responseBody] (optional) The body of the response.
  /// [responseTime] (optional) The time taken for the response.
  /// [senderInfo] (optional) Sender information for the webhook message.
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

    return send(message);
  }

  /// Sends a bug report or exception details to Discord webhooks.
  ///
  /// This method creates a Discord embed with details about an error or exception,
  /// including the error message, stack trace, and optional user information.
  ///
  /// [error]: The error object or message.
  /// [stackTrace]: The stack trace associated with the error.
  /// [message]: An optional descriptive message for the report.
  /// [extraInfo]: Optional additional information about the user or context.
  /// [senderInfo]: Optional sender information for the webhook message.
  Future<List<Response>> sendBugReport({
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
      color: 15548997, // Red color for errors
      fields: fields,
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );

    final discordMessage = DiscordWebhookMessage(
      username: senderInfo?.username ?? kDefaultBugReporterUsername,
      avatarUrl: senderInfo?.avatarUrl,
      embeds: [embed],
    );

    return send(discordMessage);
  }

  /// Sends a simple message to Discord webhooks.
  ///
  /// [content] The message content to send.
  /// [senderInfo] Optional sender information for the webhook message.
  Future<List<Response>> sendMessage({
    required String content,
    SenderInfo? senderInfo,
  }) async {
    final message = DiscordWebhookMessage(
      content: content,
      username: senderInfo?.username ?? kDefaultUsername,
      avatarUrl: senderInfo?.avatarUrl,
    );

    return send(message);
  }
}
