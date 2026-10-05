import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../../options/curl_options.dart';
import 'status_color.dart';

// ============================================================================
// EMOJIS CLASS
// ============================================================================

class Emojis {
  const Emojis._();

  // Status codes
  static const String info = 'ℹ️'; // 1xx
  static const String success = '✅'; // 2xx
  static const String redirect = '🔄'; // 3xx
  static const String error = '❌'; // 4xx
  static const String alert = '🚨'; // 5xx
  static const String clock = '⏱️'; // response time
  static const String teapot = '☕'; // 418
  static const String unknown = '❓'; // Unknown

  // Request/response headers & body
  static const String requestHeaders = '⬆️'; // Request Headers
  static const String requestBody = '📦'; // Request Body
  static const String responseHeaders = '⬇️'; // Response Headers
  static const String responseBody = '📥'; // Response Body

  static const String link = '🔗'; // Link
}

// ============================================================================
// PRETTY CLASS
// ============================================================================

const String topLeft = '╔';
const String topRight = '╗';
const String bottomLeft = '╚';
const String bottomRight = '╝';
const String horizontal = '═';
const String vertical = '║';

const String leftT = '╠';
const String rightT = '╣';

class Pretty {
  const Pretty({this.lineLength = kLineLength, this.enabled = true});

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
        String truncatedTitleContent = title.substring(
          0,
          min(title.length, maxTitleContentLength),
        );
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

    final line =
        sIndent +
        (fillChar * leftFill) +
        effectiveTitle +
        (fillChar * rightFill) +
        eIndent;
    return line;
  }
}

// ============================================================================
// UI HELPER CLASS
// ============================================================================

/// Provides status-code colors and emojis for cURL output and viewer rows.
class UiHelper {
  const UiHelper._();

  // ============================================================================
  // HTTP STATUS CODE COLORS
  // ============================================================================

  /// Get color for HTTP status code based on category
  static Color getStatusColor(int statusCode) {
    return statusColorForCode(statusCode);
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
}
