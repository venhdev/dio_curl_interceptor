import 'package:flutter/material.dart';

import 'emojis.dart';
import 'status_color_palette.dart';
import 'method_color_palette.dart';

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
}
