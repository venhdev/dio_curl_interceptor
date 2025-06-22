import '../core/constants.dart';
import '../inspector/discord_inspector.dart';

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
  factory DiscordEmbed.createCurlEmbed({
    required String curl,
    required String method,
    required String uri,
    required int statusCode,
    dynamic responseBody,
    String? responseTime,
    Map<String, dynamic>? extraInfo,
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
    final List<DiscordEmbedField> fields = [];

    // Split curl command into chunks of 1000 characters
    final int chunkSize = 1000;
    final List<String> curlChunks = [];
    for (var i = 0; i < curl.length; i += chunkSize) {
      curlChunks.add(
        curl.substring(
            i, i + chunkSize < curl.length ? i + chunkSize : curl.length),
      );
    }

    // Create fields for each chunk
    for (var i = 0; i < curlChunks.length; i++) {
      fields.add(
        DiscordEmbedField(
          name: curlChunks.length > 1
              ? 'cURL Command (Part ${i + 1}/${curlChunks.length})'
              : 'cURL Command',
          value: formatEmbedValue(curlChunks[i]),
        ),
      );
    }

    if (responseBody != null) {
      fields.add(
        DiscordEmbedField(
          name: 'Response Body',
          value: formatEmbedValue(responseBody, lang: 'json'),
        ),
      );
    }

    if (extraInfo != null) {
      fields.add(DiscordEmbedField(
        name: 'Extra Info',
        value: formatEmbedValue(extraInfo, lang: 'json'),
        inline: false,
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
      timestamp: DateTime.now().toUtc().toIso8601String(),
    );
  }

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
