import 'package:flutter/material.dart';

import '../interfaces/color_palette.dart';

class MethodColorPalette implements ColorPalette {
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

// Export the private class for use in UiHelper
MethodColorPalette getMethodColorPaletteFromPalette(String method) {
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

Color getMethodColorFromPalette(String method) {
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
