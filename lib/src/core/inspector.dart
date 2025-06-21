import 'dart:convert';

import 'package:codekit/codekit.dart';
import 'package:dio/dio.dart';

import 'constants.dart';

/// A class to represent a Discord webhook message.
/// This class follows the Discord Webhook API structure.
class DiscordWebhookMessage {
  const DiscordWebhookMessage({
    this.content,
    this.username,
    this.avatarUrl,
    this.embeds,
    this.tts = false,
    this.allowedMentions,
  });

  /// Text message, can contain up to 2000 characters.
  final String? content;

  /// Overrides the predefined username of the webhook.
  final String? username;

  /// Overrides the predefined avatar of the webhook.
  final String? avatarUrl;

  /// Array of embed objects. Webhooks can have multiple custom embeds.
  final List<DiscordEmbed>? embeds;

  /// Makes message to be spoken as with /tts command.
  final bool? tts;

  /// Object allowing to control who will be mentioned by message.
  final Map<String, dynamic>? allowedMentions;

  /// Converts the message to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (content != null) json['content'] = content;
    if (username != null) json['username'] = username;
    if (avatarUrl != null) json['avatar_url'] = avatarUrl;
    if (embeds != null && embeds!.isNotEmpty) {
      json['embeds'] = embeds!.map((embed) => embed.toJson()).toList();
    }
    if (tts != null) json['tts'] = tts;
    if (allowedMentions != null) json['allowed_mentions'] = allowedMentions;

    return json;
  }

  /// Creates a simple message with just content.
  factory DiscordWebhookMessage.simple(String content) {
    return DiscordWebhookMessage(content: content);
  }

  /// Creates a message with a single embed.
  factory DiscordWebhookMessage.withEmbed(DiscordEmbed embed) {
    return DiscordWebhookMessage(embeds: [embed]);
  }
}

/// A class to represent a Discord embed object.
class DiscordEmbed {
  const DiscordEmbed({
    this.title,
    this.description,
    this.url,
    this.color,
    this.author,
    this.fields,
    this.thumbnail,
    this.image,
    this.footer,
    this.timestamp,
  });

  /// Title of embed.
  final String? title;

  /// Description text.
  final String? description;

  /// URL of embed. If title was used, it becomes hyperlink.
  final String? url;

  /// Color code of the embed in decimal format.
  final int? color;

  /// Embed author object.
  final DiscordEmbedAuthor? author;

  /// Array of embed field objects.
  final List<DiscordEmbedField>? fields;

  /// Embed thumbnail object.
  final DiscordEmbedThumbnail? thumbnail;

  /// Embed image object.
  final DiscordEmbedImage? image;

  /// Embed footer object.
  final DiscordEmbedFooter? footer;

  /// ISO8601 timestamp (yyyy-mm-ddThh:mm:ss.msZ).
  final String? timestamp;

  /// Converts the embed to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (title != null) json['title'] = title;
    if (description != null) json['description'] = description;
    if (url != null) json['url'] = url;
    if (color != null) json['color'] = color;
    if (author != null) json['author'] = author!.toJson();
    if (fields != null && fields!.isNotEmpty) {
      json['fields'] = fields!.map((field) => field.toJson()).toList();
    }
    if (thumbnail != null) json['thumbnail'] = thumbnail!.toJson();
    if (image != null) json['image'] = image!.toJson();
    if (footer != null) json['footer'] = footer!.toJson();
    if (timestamp != null) json['timestamp'] = timestamp;

    return json;
  }
}

/// A class to represent a Discord embed author object.
class DiscordEmbedAuthor {
  const DiscordEmbedAuthor({
    this.name,
    this.url,
    this.iconUrl,
  });

  /// Name of author.
  final String? name;

  /// URL of author. If name was used, it becomes a hyperlink.
  final String? url;

  /// URL of author icon.
  final String? iconUrl;

  /// Converts the author to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};

    if (name != null) json['name'] = name;
    if (url != null) json['url'] = url;
    if (iconUrl != null) json['icon_url'] = iconUrl;

    return json;
  }
}

/// A class to represent a Discord embed field object.
class DiscordEmbedField {
  const DiscordEmbedField({
    required this.name,
    required this.value,
    this.inline,
  });

  /// Name of the field.
  final String name;

  /// Value of the field.
  final String value;

  /// If true, fields will be displayed in the same line, 3 per line.
  final bool? inline;

  /// Converts the field to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'name': name,
      'value': value,
    };

    if (inline != null) json['inline'] = inline;

    return json;
  }
}

/// A class to represent a Discord embed thumbnail object.
class DiscordEmbedThumbnail {
  const DiscordEmbedThumbnail({
    required this.url,
  });

  /// URL of thumbnail.
  final String url;

  /// Converts the thumbnail to a JSON map.
  Map<String, dynamic> toJson() {
    return {'url': url};
  }
}

/// A class to represent a Discord embed image object.
class DiscordEmbedImage {
  const DiscordEmbedImage({
    required this.url,
  });

  /// Image URL.
  final String url;

  /// Converts the image to a JSON map.
  Map<String, dynamic> toJson() {
    return {'url': url};
  }
}

/// A class to represent a Discord embed footer object.
class DiscordEmbedFooter {
  const DiscordEmbedFooter({
    required this.text,
    this.iconUrl,
  });

  /// Footer text, doesn't support Markdown.
  final String text;

  /// URL of footer icon.
  final String? iconUrl;

  /// Converts the footer to a JSON map.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'text': text};

    if (iconUrl != null) json['icon_url'] = iconUrl;

    return json;
  }
}

/// A class to handle sending cURL logs to Discord webhooks.
class Inspector {
  Inspector({
    required this.hookUrls,
    Dio? dio,
  }) : _innerDio = dio ?? Dio();

  /// Truncates a string to a specified length, appending '...' if truncated.
  static String _mayTruncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// The Discord webhook URLs to send cURL logs to.
  final List<String> hookUrls;

  /// The Dio instance for making HTTP requests.
  final Dio _innerDio;

  /// Sends a message to all configured Discord webhooks.
  ///
  /// Returns a list of responses from each webhook.
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
        print('Error sending webhook to $hookUrl: $e');
      }
    }

    return responses;
  }

  /// Creates a Discord embed for a cURL request.
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
        value: '```bash\n${_mayTruncate(curl, 1000)}\n```',
      ),
    ];

    if (responseBody != null && responseBody.isNotEmpty) {
      fields.add(DiscordEmbedField(
        name: 'Response Body',
        value: '```json\n${_mayTruncate(responseBody, 1000)}\n```',
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
        value: '```\n${_mayTruncate(stringify(error), 1000)}\n```',
        inline: false,
      ),
    ];

    if (stackTrace != null) {
      fields.add(DiscordEmbedField(
        name: 'Stack Trace',
        value: '```\n${_mayTruncate(stringify(stackTrace), 1000)}\n```',
        inline: false,
      ));
    }

    if (extraInfo != null) {
      fields.add(DiscordEmbedField(
        name: 'Extra Info',
        value: '```json\n${_mayTruncate(jsonEncode(extraInfo), 1000)}\n```',
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
