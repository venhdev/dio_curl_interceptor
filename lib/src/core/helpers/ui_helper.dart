import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import '../../options/curl_options.dart';
import 'status_color_palette.dart';
import 'method_color_palette.dart';

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

// ============================================================================
// UI HELPER CLASS
// ============================================================================

/// Reusable UI helper class for CurlViewer component.
/// Provides color palettes, emojis, and styling utilities for HTTP status codes and methods.
class UiHelper {
  const UiHelper._();

  // ============================================================================
  // HTTP STATUS CODE COLORS
  // ============================================================================

  /// Get color for HTTP status code based on category
  static Color getStatusColor(int statusCode) {
    return getStatusColorFromPalette(statusCode);
  }

  /// Get status color palette for HTTP status code category
  static StatusColorPalette getStatusColorPalette(int statusCode) {
    return getStatusColorPaletteFromPalette(statusCode);
  }

  // ============================================================================
  // HTTP METHOD COLORS
  // ============================================================================

  /// Get color for HTTP method based on standard conventions
  static Color getMethodColor(String method) {
    return getMethodColorFromPalette(method);
  }

  /// Get method color palette for HTTP method
  static MethodColorPalette getMethodColorPalette(String method) {
    return getMethodColorPaletteFromPalette(method);
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

  // ============================================================================
  // DURATION COLORS
  // ============================================================================

  /// Get color for duration based on performance thresholds
  static Color getDurationColor(int? durationMs) {
    if (durationMs == null) return Colors.grey;

    if (durationMs <= 500) {
      return Colors.green; // Excellent - <= 500ms
    } else if (durationMs <= 1000) {
      return Colors.lightGreen; // Good - <= 1000ms
    } else if (durationMs <= 2000) {
      return Colors.orange; // Normal - <= 2000ms
    } else if (durationMs <= 4000) {
      return Colors.deepOrange; // Poor - <= 4000ms
    } else {
      return Colors.red; // Very poor - > 4000ms
    }
  }

  /// Get duration color palette based on performance thresholds
  static MethodColorPalette getDurationColorPalette(int? durationMs) {
    if (durationMs == null)
      return getMethodColorPalette('GET'); // Default to GET colors

    if (durationMs <= 500) {
      return MethodColorPalette(
        primary: Colors.green[600]!,
        secondary: Colors.green[400]!,
        light: Colors.green[100]!,
        lighter: Colors.green[50]!,
        dark: Colors.green[800]!,
        background: Colors.green[50]!,
        border: Colors.green[200]!,
        shadow: Colors.green.withValues(alpha: 0.1),
      );
    } else if (durationMs <= 1000) {
      return MethodColorPalette(
        primary: Colors.lightGreen[600]!,
        secondary: Colors.lightGreen[400]!,
        light: Colors.lightGreen[100]!,
        lighter: Colors.lightGreen[50]!,
        dark: Colors.lightGreen[800]!,
        background: Colors.lightGreen[50]!,
        border: Colors.lightGreen[200]!,
        shadow: Colors.lightGreen.withValues(alpha: 0.1),
      );
    } else if (durationMs <= 2000) {
      return MethodColorPalette(
        primary: Colors.orange[600]!,
        secondary: Colors.orange[400]!,
        light: Colors.orange[100]!,
        lighter: Colors.orange[50]!,
        dark: Colors.orange[800]!,
        background: Colors.orange[50]!,
        border: Colors.orange[200]!,
        shadow: Colors.orange.withValues(alpha: 0.1),
      );
    } else if (durationMs <= 4000) {
      return MethodColorPalette(
        primary: Colors.deepOrange[600]!,
        secondary: Colors.deepOrange[400]!,
        light: Colors.deepOrange[100]!,
        lighter: Colors.deepOrange[50]!,
        dark: Colors.deepOrange[800]!,
        background: Colors.deepOrange[50]!,
        border: Colors.deepOrange[200]!,
        shadow: Colors.deepOrange.withValues(alpha: 0.1),
      );
    } else {
      return MethodColorPalette(
        primary: Colors.red[600]!,
        secondary: Colors.red[400]!,
        light: Colors.red[100]!,
        lighter: Colors.red[50]!,
        dark: Colors.red[800]!,
        background: Colors.red[50]!,
        border: Colors.red[200]!,
        shadow: Colors.red.withValues(alpha: 0.1),
      );
    }
  }

  /// Get emoji for duration based on performance thresholds
  static String getDurationEmoji(int? durationMs) {
    if (durationMs == null) return Emojis.clock;

    if (durationMs <= 500) {
      return '⚡'; // Excellent - Lightning fast
    } else if (durationMs <= 1000) {
      return '🚀'; // Good - Fast
    } else if (durationMs <= 2000) {
      return '🏃'; // Normal - Running
    } else if (durationMs <= 4000) {
      return '🚶'; // Poor - Walking
    } else {
      return '🐌'; // Very poor - Slow
    }
  }
}
