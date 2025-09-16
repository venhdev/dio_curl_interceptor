import 'package:flutter/material.dart';

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

// Export the private class for use in UiHelper
StatusColorPalette getStatusColorPaletteFromPalette(int statusCode) {
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

Color getStatusColorFromPalette(int statusCode) {
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
