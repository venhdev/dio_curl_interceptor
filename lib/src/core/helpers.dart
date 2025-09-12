import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../dio_curl_interceptor.dart';
import 'constants.dart';

class Helpers {
  const Helpers._();

  static int? tryExtractDuration({
    Stopwatch? stopwatch,
    dynamic xClientTimeHeader,
  }) {
    if (stopwatch != null) {
      return stopwatch.elapsedMilliseconds;
    }
    if (xClientTimeHeader != null) {
      final xClientTimeInt = int.tryParse(xClientTimeHeader);
      if (xClientTimeInt != null) {
        return DateTime.now().millisecondsSinceEpoch - xClientTimeInt;
      }
    }
    return null;
  }

  // /// Wraps the given [text] with Markdown backticks, optionally specifying a [language] for syntax highlighting. <>del
  // ///
  // /// This is a private helper method used to format code snippets or other text
  // /// for display in Discord embeds.
  // ///
  // /// [text] The text content to be wrapped.
  // /// [language] An optional language identifier for Markdown syntax highlighting.
  // /// Returns the wrapped string.
  // static String wrapWithBackticks(String text, [String? language]) {
  //   if (language != null && language.isNotEmpty) {
  //     return '```$language\n$text\n```';
  //   }
  //   return '```\n$text\n```';
  // }

  static String generateCurlFromRequestOptions(
    RequestOptions originRequestOptions,
  ) {
    // make a new instance of options to avoid mutating the original object
    final options = originRequestOptions.copyWith();

    List<String> components = ['curl -i'];
    components.add('-X ${options.method}');

    options.headers.forEach((k, v) {
      if (k != 'Cookie' && k != 'content-length') {
        components.add('-H "$k: $v"');
      }
    });

    if (options.data != null) {
      // FormData can't be JSON-serialized, so keep only their fields attributes
      if (options.data is FormData) {
        final formData = options.data as FormData;
        final Map<String, dynamic> dataMap = Map.fromEntries(formData.fields);

        // Handle file attachments - group files by field name and use filenames as values
        final Map<String, List<String>> fileGroups = {};
        for (final fileEntry in formData.files) {
          final fieldName = fileEntry.key;
          final fileName = fileEntry.value.filename ?? 'unknown_file';

          fileGroups.putIfAbsent(fieldName, () => []).add(fileName);
        }

        // Add file information to the data map
        // For single files, use the filename directly
        // For multiple files with the same field name, use an array of filenames
        fileGroups.forEach((fieldName, fileNames) {
          if (fileNames.length == 1) {
            dataMap[fieldName] = fileNames.first;
          } else {
            dataMap[fieldName] = fileNames;
          }
        });

        options.data = dataMap;
      }

      final data = json.encode(options.data).replaceAll('"', '\\"');
      components.add('-d "$data"');
    }

    components.add('"${options.uri.toString()}"');

    return components.join(' ');
  }

  static String getStatusName(int statusCode) {
    switch (statusCode) {
      // 1xx Informational
      case 100:
        return 'Continue';
      case 101:
        return 'Switching Protocols';
      case 102:
        return 'Processing';
      case 103:
        return 'Early Hints';

      // 2xx Success
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 203:
        return 'Non-Authoritative Information';
      case 204:
        return 'No Content';
      case 205:
        return 'Reset Content';
      case 206:
        return 'Partial Content';
      case 207:
        return 'Multi-Status';
      case 208:
        return 'Already Reported';
      case 226:
        return 'IM Used';

      // 3xx Redirection
      case 300:
        return 'Multiple Choices';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 303:
        return 'See Other';
      case 304:
        return 'Not Modified';
      case 305:
        return 'Use Proxy';
      case 307:
        return 'Temporary Redirect';
      case 308:
        return 'Permanent Redirect';

      // 4xx Client Error
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 402:
        return 'Payment Required';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 406:
        return 'Not Acceptable';
      case 407:
        return 'Proxy Authentication Required';
      case 408:
        return 'Request Timeout';
      case 409:
        return 'Conflict';
      case 410:
        return 'Gone';
      case 411:
        return 'Length Required';
      case 412:
        return 'Precondition Failed';
      case 413:
        return 'Payload Too Large';
      case 414:
        return 'URI Too Long';
      case 415:
        return 'Unsupported Media Type';
      case 416:
        return 'Range Not Satisfiable';
      case 417:
        return 'Expectation Failed';
      case 418:
        return "I'm a teapot";
      case 421:
        return 'Misdirected Request';
      case 422:
        return 'Unprocessable Entity';
      case 423:
        return 'Locked';
      case 424:
        return 'Failed Dependency';
      case 425:
        return 'Too Early';
      case 426:
        return 'Upgrade Required';
      case 428:
        return 'Precondition Required';
      case 429:
        return 'Too Many Requests';
      case 431:
        return 'Request Header Fields Too Large';
      case 451:
        return 'Unavailable For Legal Reasons';

      // 5xx Server Error
      case 500:
        return 'Internal Server Error';
      case 501:
        return 'Not Implemented';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      case 505:
        return 'HTTP Version Not Supported';
      case 506:
        return 'Variant Also Negotiates';
      case 507:
        return 'Insufficient Storage';
      case 508:
        return 'Loop Detected';
      case 510:
        return 'Not Extended';
      case 511:
        return 'Network Authentication Required';

      // Default case for unknown status codes
      default:
        return 'Unknown Status Code';
    }
  }

  static String getStatusEmoji(int statusCode) {
    return UiHelper.getStatusEmoji(statusCode);
  }

  static Ansi getMethodAnsi(String method) {
    switch (method) {
      case 'GET':
        return Ansi.green;
      case 'POST':
        return Ansi.yellow;
      case 'PUT':
        return Ansi.blue;
      case 'PATCH':
        return Ansi.magenta;
      case 'DELETE':
        return Ansi.red;
      default:
        return Ansi.reset;
    }
  }
}

const String topLeft = '╔';
const String topRight = '╗';
const String bottomLeft = '╚';
const String bottomRight = '╝';
const String horizontal = '═';
const String vertical = '║';

const String leftT = '╠';
const String rightT = '╣';

class Pretty {
  const Pretty({
    this.lineLength = kLineLength,
    this.enabled = true,
  });

  factory Pretty.fromOptions(CurlOptions curlOptions) {
    return Pretty(
      lineLength: curlOptions.prettyConfig.lineLength,
      enabled: curlOptions.prettyConfig.blockEnabled,
    );
  }

  final int lineLength;
  final bool enabled;

  String get line => horizontal * lineLength;

  String lineStart([String title = '']) {
    if (!enabled) {
      return '';
    }
    return _customLine(title, sIndent: topLeft, eIndent: topRight);
  }

  String lineEnd([String title = '']) {
    if (!enabled) {
      return '';
    }
    return _customLine(title, sIndent: bottomLeft, eIndent: bottomRight);
  }

  String lineMid([String title = '']) {
    if (!enabled) {
      return '';
    }
    return _customLine(title, sIndent: leftT, eIndent: rightT);
  }

  String _customLine(
    String title, {
    String fillChar = horizontal,
    String sIndent = '',
    String eIndent = '',
  }) {
    // Case 1: No title and no indents, just fill the whole line
    if (title.isEmpty && sIndent.isEmpty && eIndent.isEmpty) {
      return fillChar * lineLength;
    }

    int availableSpaceForContentAndFill =
        lineLength - sIndent.length - eIndent.length;

    String effectiveTitle = '';

    if (title.isNotEmpty) {
      // Calculate the maximum length the actual title content can be, considering 2 spaces for padding
      int maxTitleContentLength = availableSpaceForContentAndFill - 2;

      if (maxTitleContentLength > 0) {
        // Truncate the original title content if it's too long
        String truncatedTitleContent =
            title.substring(0, min(title.length, maxTitleContentLength));
        effectiveTitle = ' $truncatedTitleContent ';
      }
      // If maxTitleContentLength <= 0, effectiveTitle remains empty, which is correct.
    }

    // Now, ensure effectiveTitle (with its padding) does not exceed availableSpaceForContentAndFill
    // This handles cases where maxTitleContentLength was 0 or 1, leading to effectiveTitle being '  ' or ' X '
    // which might still be too long for the available space.
    if (effectiveTitle.length > availableSpaceForContentAndFill) {
      effectiveTitle = ''; // If it still doesn't fit, just make it empty.
    }

    // Calculate remaining space for fill characters
    int fillLength = availableSpaceForContentAndFill - effectiveTitle.length;

    // This should now always be non-negative due to the checks above
    if (fillLength < 0) {
      fillLength = 0;
    }

    int leftFill = fillLength ~/ 2;
    int rightFill = fillLength - leftFill;

    final line = sIndent +
        (fillChar * leftFill) +
        effectiveTitle +
        (fillChar * rightFill) +
        eIndent;
    return line;
  }
}

/// Reusable UI helper class for CurlViewer component.
/// Provides color palettes, emojis, and styling utilities for HTTP status codes and methods.
class UiHelper {
  const UiHelper._();

  // ============================================================================
  // HTTP STATUS CODE COLORS
  // ============================================================================

  /// Get color for HTTP status code based on category
  static Color getStatusColor(int statusCode) {
    if (statusCode >= 100 && statusCode < 200) {
      return _StatusColors.informational.primary; // 1xx Informational - Blue
    } else if (statusCode >= 200 && statusCode < 300) {
      return _StatusColors.success.primary; // 2xx Success - Green
    } else if (statusCode >= 300 && statusCode < 400) {
      return _StatusColors
          .redirection.primary; // 3xx Redirection - Light Blue/Cyan
    } else if (statusCode >= 400 && statusCode < 500) {
      return _StatusColors.clientError.primary; // 4xx Client Error - Orange
    } else if (statusCode >= 500 && statusCode < 600) {
      return _StatusColors.serverError.primary; // 5xx Server Error - Red
    } else {
      return _StatusColors.unknown.primary; // Unknown - Grey
    }
  }

  /// Get status color palette for HTTP status code category
  static StatusColorPalette getStatusColorPalette(int statusCode) {
    if (statusCode >= 100 && statusCode < 200) {
      return _StatusColors.informational;
    } else if (statusCode >= 200 && statusCode < 300) {
      return _StatusColors.success;
    } else if (statusCode >= 300 && statusCode < 400) {
      return _StatusColors.redirection;
    } else if (statusCode >= 400 && statusCode < 500) {
      return _StatusColors.clientError;
    } else if (statusCode >= 500 && statusCode < 600) {
      return _StatusColors.serverError;
    } else {
      return _StatusColors.unknown;
    }
  }

  // ============================================================================
  // HTTP METHOD COLORS
  // ============================================================================

  /// Get color for HTTP method based on standard conventions
  static Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return _MethodColors.get.primary; // Blue
      case 'POST':
        return _MethodColors.post.primary; // Green
      case 'PUT':
        return _MethodColors.put.primary; // Orange
      case 'PATCH':
        return _MethodColors.patch.primary; // Orange
      case 'DELETE':
        return _MethodColors.delete.primary; // Red
      case 'HEAD':
        return _MethodColors.head.primary; // Brown/Orange
      default:
        return _MethodColors.unknown.primary; // Grey
    }
  }

  /// Get method color palette for HTTP method
  static MethodColorPalette getMethodColorPalette(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return _MethodColors.get;
      case 'POST':
        return _MethodColors.post;
      case 'PUT':
        return _MethodColors.put;
      case 'PATCH':
        return _MethodColors.patch;
      case 'DELETE':
        return _MethodColors.delete;
      case 'HEAD':
        return _MethodColors.head;
      default:
        return _MethodColors.unknown;
    }
  }

  // ============================================================================
  // EMOJIS
  // ============================================================================

  /// Get emoji for HTTP status code
  static String getStatusEmoji(int statusCode) {
    if (statusCode == 418) {
      return Emojis.teapot; // Special case for "I'm a teapot"
    }

    if (statusCode >= 100 && statusCode < 200) {
      return Emojis.info; // 1xx Informational
    } else if (statusCode >= 200 && statusCode < 300) {
      return Emojis.success; // 2xx Success
    } else if (statusCode >= 300 && statusCode < 400) {
      return Emojis.redirect; // 3xx Redirection
    } else if (statusCode >= 400 && statusCode < 500) {
      return Emojis.error; // 4xx Client Error
    } else if (statusCode >= 500 && statusCode < 600) {
      return Emojis.alert; // 5xx Server Error
    } else {
      return Emojis.unknown; // Unknown status code
    }
  }

  /// Get emoji for HTTP method
  static String getMethodEmoji(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Emojis.get;
      case 'POST':
        return Emojis.post;
      case 'PUT':
        return Emojis.put;
      case 'PATCH':
        return Emojis.patch;
      case 'DELETE':
        return Emojis.delete;
      case 'HEAD':
        return Emojis.head;
      default:
        return Emojis.unknown;
    }
  }
}

// ============================================================================
// STATUS COLOR PALETTES
// ============================================================================

class _StatusColors {
  const _StatusColors._();

  static const informational = StatusColorPalette(
    primary: Color(0xFF2196F3), // Blue
    secondary: Color(0xFF64B5F6),
    light: Color(0xFFBBDEFB),
    lighter: Color(0xFFE3F2FD),
    dark: Color(0xFF1976D2),
    background: Color(0x1A2196F3),
    backgroundLight: Color(0x0D2196F3),
    border: Color(0x4D2196F3),
    borderStrong: Color(0x662196F3),
    shadow: Color(0x1A2196F3),
  );

  static const success = StatusColorPalette(
    primary: Color(0xFF4CAF50), // Green
    secondary: Color(0xFF81C784),
    light: Color(0xFFC8E6C9),
    lighter: Color(0xFFE8F5E8),
    dark: Color(0xFF388E3C),
    background: Color(0x1A4CAF50),
    backgroundLight: Color(0x0D4CAF50),
    border: Color(0x4D4CAF50),
    borderStrong: Color(0x664CAF50),
    shadow: Color(0x1A4CAF50),
  );

  static const redirection = StatusColorPalette(
    primary: Color(0xFF00BCD4), // Light Blue/Cyan
    secondary: Color(0xFF4DD0E1),
    light: Color(0xFFB2EBF2),
    lighter: Color(0xFFE0F7FA),
    dark: Color(0xFF0097A7),
    background: Color(0x1A00BCD4),
    backgroundLight: Color(0x0D00BCD4),
    border: Color(0x4D00BCD4),
    borderStrong: Color(0x6600BCD4),
    shadow: Color(0x1A00BCD4),
  );

  static const clientError = StatusColorPalette(
    primary: Color(0xFFFF9800), // Orange
    secondary: Color(0xFFFFB74D),
    light: Color(0xFFFFE0B2),
    lighter: Color(0xFFFFF3E0),
    dark: Color(0xFFF57C00),
    background: Color(0x1AFF9800),
    backgroundLight: Color(0x0DFF9800),
    border: Color(0x4DFF9800),
    borderStrong: Color(0x66FF9800),
    shadow: Color(0x1AFF9800),
  );

  static const serverError = StatusColorPalette(
    primary: Color(0xFFF44336), // Red
    secondary: Color(0xFFE57373),
    light: Color(0xFFFFCDD2),
    lighter: Color(0xFFFFEBEE),
    dark: Color(0xFFD32F2F),
    background: Color(0x1AF44336),
    backgroundLight: Color(0x0DF44336),
    border: Color(0x4DF44336),
    borderStrong: Color(0x66F44336),
    shadow: Color(0x1AF44336),
  );

  static const unknown = StatusColorPalette(
    primary: Color(0xFF9E9E9E), // Grey
    secondary: Color(0xFFBDBDBD),
    light: Color(0xFFE0E0E0),
    lighter: Color(0xFFF5F5F5),
    dark: Color(0xFF616161),
    background: Color(0x1A9E9E9E),
    backgroundLight: Color(0x0D9E9E9E),
    border: Color(0x4D9E9E9E),
    borderStrong: Color(0x669E9E9E),
    shadow: Color(0x1A9E9E9E),
  );
}

class StatusColorPalette {
  const StatusColorPalette({
    required this.primary,
    required this.secondary,
    required this.light,
    required this.lighter,
    required this.dark,
    required this.background,
    required this.backgroundLight,
    required this.border,
    required this.borderStrong,
    required this.shadow,
  });

  final Color primary;
  final Color secondary;
  final Color light;
  final Color lighter;
  final Color dark;
  final Color background;
  final Color backgroundLight;
  final Color border;
  final Color borderStrong;
  final Color shadow;
}

// ============================================================================
// METHOD COLOR PALETTES
// ============================================================================

class _MethodColors {
  const _MethodColors._();

  static const get = MethodColorPalette(
    primary: Color(0xFF2196F3), // Blue
    secondary: Color(0xFF64B5F6),
    light: Color(0xFFBBDEFB),
    lighter: Color(0xFFE3F2FD),
    dark: Color(0xFF1976D2),
    background: Color(0x1A2196F3),
    border: Color(0x4D2196F3),
    shadow: Color(0x1A2196F3),
  );

  static const post = MethodColorPalette(
    primary: Color(0xFF4CAF50), // Green
    secondary: Color(0xFF81C784),
    light: Color(0xFFC8E6C9),
    lighter: Color(0xFFE8F5E8),
    dark: Color(0xFF388E3C),
    background: Color(0x1A4CAF50),
    border: Color(0x4D4CAF50),
    shadow: Color(0x1A4CAF50),
  );

  static const put = MethodColorPalette(
    primary: Color(0xFFFF9800), // Orange
    secondary: Color(0xFFFFB74D),
    light: Color(0xFFFFE0B2),
    lighter: Color(0xFFFFF3E0),
    dark: Color(0xFFF57C00),
    background: Color(0x1AFF9800),
    border: Color(0x4DFF9800),
    shadow: Color(0x1AFF9800),
  );

  static const patch = MethodColorPalette(
    primary: Color(0xFFFF9800), // Orange (same as PUT)
    secondary: Color(0xFFFFB74D),
    light: Color(0xFFFFE0B2),
    lighter: Color(0xFFFFF3E0),
    dark: Color(0xFFF57C00),
    background: Color(0x1AFF9800),
    border: Color(0x4DFF9800),
    shadow: Color(0x1AFF9800),
  );

  static const delete = MethodColorPalette(
    primary: Color(0xFFF44336), // Red
    secondary: Color(0xFFE57373),
    light: Color(0xFFFFCDD2),
    lighter: Color(0xFFFFEBEE),
    dark: Color(0xFFD32F2F),
    background: Color(0x1AF44336),
    border: Color(0x4DF44336),
    shadow: Color(0x1AF44336),
  );

  static const head = MethodColorPalette(
    primary: Color(0xFF795548), // Brown
    secondary: Color(0xFFA1887F),
    light: Color(0xFFD7CCC8),
    lighter: Color(0xFFEFEBE9),
    dark: Color(0xFF5D4037),
    background: Color(0x1A795548),
    border: Color(0x4D795548),
    shadow: Color(0x1A795548),
  );

  static const unknown = MethodColorPalette(
    primary: Color(0xFF9E9E9E), // Grey
    secondary: Color(0xFFBDBDBD),
    light: Color(0xFFE0E0E0),
    lighter: Color(0xFFF5F5F5),
    dark: Color(0xFF616161),
    background: Color(0x1A9E9E9E),
    border: Color(0x4D9E9E9E),
    shadow: Color(0x1A9E9E9E),
  );
}

class MethodColorPalette {
  const MethodColorPalette({
    required this.primary,
    required this.secondary,
    required this.light,
    required this.lighter,
    required this.dark,
    required this.background,
    required this.border,
    required this.shadow,
  });

  final Color primary;
  final Color secondary;
  final Color light;
  final Color lighter;
  final Color dark;
  final Color background;
  final Color border;
  final Color shadow;
}

// ============================================================================
// EMOJI CONSTANTS
// ============================================================================

class Emojis {
  const Emojis._();

  // Status codes
  static const String info = 'ℹ️'; // 1xx
  static const String success = '✅'; // 2xx
  static const String redirect = '🔄'; // 3xx
  static const String error = '❌'; // 4xx
  static const String alert = '🚨'; // 5xx
  static const String warning = '⚠️';
  static const String question = '❓';
  static const String loading = '⏳';
  static const String clock = '⏱️'; // response time
  static const String doc = '📄'; // response body
  static const String teapot = '☕'; // 418
  static const String unknown = '❓'; // Unknown

  // Request methods
  static const String get = '🔍'; // GET
  static const String post = '📤'; // POST
  static const String put = '📥'; // PUT
  static const String patch = '📝'; // PATCH
  static const String delete = '🗑️'; // DELETE
  static const String head = '📄'; // HEAD

  // Request/response headers & body
  static const String requestHeaders = '⬆️'; // Request Headers
  static const String requestBody = '📦'; // Request Body
  static const String responseHeaders = '⬇️'; // Response Headers
  static const String responseBody = '📥'; // Response Body

  // Misc
  static const String package = '📦'; // Package
  static const String link = '🔗'; // Link
  static const String document = '🧾'; // Document
  static const String image = '🖼️'; // Image
  static const String audio = '🔊'; // Audio
  static const String video = '📹'; // Video
  static const String folder = '📁'; // Folder
  static const String database = '🗃️'; // Database
  static const String cloud = '☁️'; // Cloud
  static const String star = '⭐️'; // Star
  static const String gear = '⚙️'; // Gear
  static const String pin = '📌'; // Pin
  static const String lightBulb = '💡'; // Light bulb
  static const String lock = '🔒'; // Lock
  static const String key = '🔑'; // Key
  static const String tag = '🏷️'; // Tag
}
