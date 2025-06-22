import 'dart:convert';
import 'dart:developer';

import 'package:codekit/codekit.dart';
import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../core/helpers.dart';
import '../core/types.dart';
import '../core/utils/curl_utils.dart';
import '../data/discord_webhook_model.dart';

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
    this.inspectionStatus = defaultInspectionStatus,
  });

  DiscordWebhookSender get S => DiscordWebhookSender(hookUrls: webhookUrls);
  DiscordWebhookSender toSender([Dio? dio]) => DiscordWebhookSender(
        hookUrls: webhookUrls,
        dio: dio,
      );

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

  void inspectOnResponse({
    required Response<dynamic> response,
    Stopwatch? stopwatch,
    String? username,
    String? avatarUrl,
  }) =>
      inspectOn(
        options: response.requestOptions,
        response: response,
        stopwatch: stopwatch,
        username: username,
        avatarUrl: avatarUrl,
      );

  void inspectOnError({
    required DioException err,
    Stopwatch? stopwatch,
    String? username,
    String? avatarUrl,
  }) =>
      inspectOn(
        options: err.requestOptions,
        response: err.response,
        err: err,
        stopwatch: stopwatch,
        username: username,
        avatarUrl: avatarUrl,
      );

  void inspectOn({
    required RequestOptions options,
    required Response<dynamic>? response,
    DioException? err,
    Stopwatch? stopwatch,
    String? username,
    String? avatarUrl,
  }) {
    final uri = options.uri.toString();
    final statusCode = response?.statusCode ?? -1;

    if (isMatch(uri, statusCode)) {
      final String? curl = genCurl(options);
      final dynamic responseBody = response?.data;
      int? duration = Helpers.tryExtractDuration(
        stopwatch: stopwatch,
        xClientTimeHeader: options.headers[kXClientTime],
      );

      S.sendCurlLog(
        curl: curl,
        method: options.method,
        uri: uri,
        statusCode: statusCode,
        username: username,
        avatarUrl: avatarUrl,
        responseTime: '$duration ms',
        responseBody: responseBody,
        extraInfo: err != null
            ? {'type': err.type.name, 'message': err.message}
            : null,
      );
    }
  }

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
}

/// A class to handle sending cURL logs and other messages to Discord webhooks.
///
/// This class provides methods to send various types of information,
/// including cURL commands, bug reports, and simple messages, to Discord channels.
class DiscordWebhookSender {
  /// Creates an [DiscordWebhookSender] instance.
  ///
  /// [hookUrls] A list of Discord webhook URLs where messages will be sent.
  /// [dio] An optional Dio instance to use for making HTTP requests to webhooks.
  ///   If not provided, a new Dio instance will be created.
  DiscordWebhookSender({
    required this.hookUrls,
    Dio? dio,
  }) : _innerDio = dio ?? Dio();

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
    required String? curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    String? username,
    String? avatarUrl,
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
        value: formatEmbedValue(extraInfo, 'json'),
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

String formatEmbedValue(dynamic rawValue, [String? language]) =>
    _wrapWithBackticks(
      stringify(rawValue, maxLen: 1000, replacements: _replacementsEmbedField),
      language,
    );

const Map<String, String> _replacementsEmbedField = {'```': ''};

String _wrapWithBackticks(String text, [String? language]) {
  if (language != null && language.isNotEmpty) {
    return '```$language\n$text\n```';
  }
  return '```\n$text\n```';
}
