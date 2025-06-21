import 'dart:convert';

import 'package:codekit/codekit.dart';
import 'dart:developer';
import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/types.dart';
import '../data/discord_webhook_model.dart';

const Map<String, String> _replacementsEmbedField = {'```': ''};

const _defaultInspectionStatus = <ResponseStatus>[
  ResponseStatus.clientError,
  ResponseStatus.serverError,
];

/// Options for configuring Discord webhook integration for cURL logging.
///
/// This class allows you to define rules for when and how cURL logs
/// are sent to Discord, including URL filtering and status code-based inspection.
class DiscordInspector {
  /// Creates a [DiscordInspector] instance.
  ///
  /// [webhookUrls] A list of Discord webhook URLs to send logs to.
  /// [includeUrls] A list of URI patterns to include for inspection. If not empty,
  ///   only requests matching any of these patterns will be sent.
  /// [excludeUrls] A list of URI patterns to exclude from inspection. If not empty,
  ///   requests matching any of these patterns will NOT be sent.
  /// [inspectionStatus] A list of [ResponseStatus] types that trigger webhook notifications.
  const DiscordInspector({
    this.webhookUrls = const <String>[],
    this.includeUrls = const [],
    this.excludeUrls = const [],
    this.inspectionStatus = _defaultInspectionStatus,
  });

  /// Adds a single webhook URL to the [webhookUrls] list.
  void addWebhookUrl(String webhookUrl) {
    webhookUrls.add(webhookUrl);
  }

  /// Adds a single URI pattern to the [includeUrls] list.
  void addIncludeUrl(String url) {
    includeUrls.add(url);
  }

  /// Adds a single URI pattern to the [excludeUrls] list.
  void addExcludeUrl(String url) {
    excludeUrls.add(url);
  }

  /// Adds a single [ResponseStatus] to the [inspectionStatus] list.
  void addInspectionStatus(ResponseStatus status) {
    inspectionStatus.add(status);
  }

  /// The type of inspection to perform.
  final List<ResponseStatus> inspectionStatus;

  /// The Discord webhook URL to send cURL logs to.
  /// If empty, webhook functionality will be disabled.
  final List<String> webhookUrls;

  /// List of URI patterns to include for webhook requests.
  /// If not empty, only requests matching any of these patterns will be sent.
  final List<String> includeUrls;

  /// List of URI patterns to exclude for webhook requests.
  /// If not empty, requests matching any of these patterns will NOT be sent.
  final List<String> excludeUrls;

  /// Determines if a given URI and status code match the inspection criteria.
  ///
  /// This method checks against [includeUrls], [excludeUrls], and [inspectionStatus]
  /// to decide if a request should trigger a webhook notification.
  ///
  /// [uri] The URI of the request.
  /// [statusCode] The HTTP status code of the response.
  ///
  /// Returns `true` if the URI and status code match the criteria, `false` otherwise.
  bool isMatch(String uri, int statusCode) {
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
              return false; // Unknown status doesn't match any specific range
          }
        });

    final includeMatch = includeUrls.isEmpty ||
        includeUrls.any((filter) => uri.contains(filter));

    final excludeMatch = excludeUrls.isEmpty ||
        !excludeUrls.any((filter) => uri.contains(filter));

    // If both are provided, both must match.
    return includeMatch && excludeMatch && statusMatch;
  }
}

/// A class to handle sending cURL logs and other messages to Discord webhooks.
///
/// This class provides methods to send various types of information,
/// including cURL commands, bug reports, and simple messages, to Discord channels.
class Inspector {
  /// Creates an [Inspector] instance.
  ///
  /// [hookUrls] A list of Discord webhook URLs where messages will be sent.
  /// [dio] An optional Dio instance to use for making HTTP requests to webhooks.
  ///   If not provided, a new Dio instance will be created.
  Inspector({
    required this.hookUrls,
    Dio? dio,
  }) : _innerDio = dio ?? Dio();

  /// Wraps the given [text] with Markdown backticks, optionally specifying a [language] for syntax highlighting.
  ///
  /// This is a private helper method used to format code snippets or other text
  /// for display in Discord embeds.
  ///
  /// [text] The text content to be wrapped.
  /// [language] An optional language identifier for Markdown syntax highlighting.
  /// Returns the wrapped string.
  static String _wrapWithBackticks(String text, [String? language]) {
    if (language != null && language.isNotEmpty) {
      return '```$language\n$text\n```';
    }
    return '```\n$text\n```';
  }

  /// The Discord webhook URLs to send cURL logs to.
  final List<String> hookUrls;

  /// The Dio instance for making HTTP requests.
  final Dio _innerDio;

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
    final List<Response> responses = [];
    final String jsonPayload = jsonEncode(message.toJson());

    for (final String hookUrl in hookUrls) {
      try {
        final response = await _innerDio.post(
          hookUrl,
          data: jsonPayload,
          options: Options(headers: {'Content-Type': 'application/json'}),
        );
        responses.add(response);
      } catch (e) {
        // Handle errors silently to prevent disrupting the main application
        log('Error sending webhook to $hookUrl: $e', name: 'DiscordInspector');
      }
    }

    return responses;
  }

  /// Creates a Discord embed for a cURL request.
  /// Creates a [DiscordEmbed] object for a cURL request.
  ///
  /// This static method constructs a rich embed message suitable for Discord,
  /// containing details about a cURL request, its response, and timing.
  /// The embed's color changes based on the HTTP status code.
  ///
  /// [curl] The cURL command string.
  /// [method] The HTTP method (e.g., 'GET', 'POST').
  /// [uri] The URI of the request.
  /// [statusCode] The HTTP status code of the response.
  /// [responseBody] (optional) The body of the response.
  /// [responseTime] (optional) The time taken for the response.
  ///
  /// Returns a [DiscordEmbed] object.
  static DiscordEmbed createCurlEmbed({
    required String curl,
    required String method,
    required String uri,
    required int statusCode,
    String? responseBody,
    String? responseTime,
  }) {
    // Determine color based on status code
    int color;
    if (statusCode >= 200 && statusCode < 300) {
      color = 5763719; // Green for success
    } else if (statusCode >= 400 && statusCode < 500) {
      color = 16525609; // Yellow for client errors
    } else if (statusCode >= 500) {
      color = 15548997; // Red for server errors
    } else {
      color = 5814783; // Blue for other status codes
    }

    final List<DiscordEmbedField> fields = [
      DiscordEmbedField(
        name: 'cURL Command',
        value: _wrapWithBackticks(
            stringify(curl,
                maxLen: 1000, replacements: _replacementsEmbedField),
            'bash'),
      ),
    ];

    if (responseBody != null && responseBody.isNotEmpty) {
      fields.add(DiscordEmbedField(
        name: 'Response Body',
        value: _wrapWithBackticks(
            stringify(responseBody,
                maxLen: 1000, replacements: _replacementsEmbedField),
            'json'),
      ));
    }

    return DiscordEmbed(
      title: '$method $uri',
      description: 'Status Code: $statusCode',
      color: color,
      fields: fields,
      footer: DiscordEmbedFooter(
        text: 'Response Time: ${responseTime ?? kNA}',
      ),
      timestamp: DateTime.now().toIso8601String(),
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
  /// [username] (optional) The username to display for the webhook message.
  /// [avatarUrl] (optional) The avatar URL to display for the webhook message.
  ///
  /// Returns a [Future] that completes with a list of [Response] objects
  /// from each successful webhook call.
  Future<List<Response>> sendCurlLog({
    required String curl,
    required String method,
    required String uri,
    required int statusCode,
    String? responseBody,
    String? responseTime,
    String? username,
    String? avatarUrl,
  }) async {
    final embed = createCurlEmbed(
      curl: curl,
      method: method,
      uri: uri,
      statusCode: statusCode,
      responseBody: responseBody,
      responseTime: responseTime,
    );

    final message = DiscordWebhookMessage(
      username: username ?? 'Dio cURL Interceptor',
      avatarUrl: avatarUrl,
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
  /// [userInfo]: Optional additional information about the user or context.
  Future<List<Response>> sendBugReport({
    required Object error,
    StackTrace? stackTrace,
    String? message,
    Map<String, dynamic>? extraInfo,
    String? username,
    String? avatarUrl,
  }) async {
    final List<DiscordEmbedField> fields = [
      DiscordEmbedField(
        name: 'Error',
        value: _wrapWithBackticks(stringify(error,
            maxLen: 1000, replacements: _replacementsEmbedField)),
        inline: false,
      ),
    ];

    if (stackTrace != null) {
      fields.add(DiscordEmbedField(
        name: 'Stack Trace',
        value: _wrapWithBackticks(stringify(stackTrace,
            maxLen: 1000, replacements: _replacementsEmbedField)),
        inline: false,
      ));
    }

    if (extraInfo != null) {
      fields.add(DiscordEmbedField(
        name: 'Extra Info',
        value: _wrapWithBackticks(
            stringify(extraInfo,
                maxLen: 1000,
                replacements: _replacementsEmbedField,
                jsonIndent: '  '),
            'json'),
        inline: false,
      ));
    }

    final embed = DiscordEmbed(
      title: 'Bug Report / Exception',
      description: message ?? 'An unhandled exception occurred.',
      color: 15548997, // Red color for errors
      fields: fields,
      timestamp: DateTime.now().toIso8601String(),
    );

    final discordMessage = DiscordWebhookMessage(
      username: username ?? 'Bug Reporter',
      avatarUrl: avatarUrl,
      embeds: [embed],
    );

    return send(discordMessage);
  }
}
