/// Syntax highlighting color tokens and typography for the JSON tree viewer.
library;

import 'package:flutter/material.dart';

/// Styling and theme configuration for JSON syntax rendering.
class JsonTreeTheme {
  final Color keyColor;
  final Color stringColor;
  final Color numberColor;
  final Color booleanColor;
  final Color nullColor;
  final Color punctuationColor;
  final Color indentGuideColor;
  final Color searchHighlightColor;
  final Color searchActiveColor;
  final Color badgeBackgroundColor;
  final TextStyle fontStyle;
  final double indentWidth;

  const JsonTreeTheme({
    required this.keyColor,
    required this.stringColor,
    required this.numberColor,
    required this.booleanColor,
    required this.nullColor,
    required this.punctuationColor,
    required this.indentGuideColor,
    required this.searchHighlightColor,
    required this.searchActiveColor,
    required this.badgeBackgroundColor,
    this.fontStyle = const TextStyle(
      fontSize: 12.5,
      height: 1.4,
      fontFamily: 'monospace',
    ),
    this.indentWidth = 16.0,
  });

  /// Standard dark theme syntax tokens.
  factory JsonTreeTheme.dark() {
    return const JsonTreeTheme(
      keyColor: Color(0xFF64B5F6), // Blue 300
      stringColor: Color(0xFF81C784), // Green 300
      numberColor: Color(0xFFFFB74D), // Amber 300
      booleanColor: Color(0xFFBA68C8), // Purple 300
      nullColor: Color(0xFFB0BEC5), // BlueGrey 200
      punctuationColor: Color(0xFF9E9E9E), // Grey 500
      indentGuideColor: Color(0x2AFFFFFF), // Muted white guide line
      searchHighlightColor: Color(0x66FFD54F), // Amber highlight
      searchActiveColor: Color(0xFFFFB300), // Active amber
      badgeBackgroundColor: Color(0x3342A5F5),
    );
  }

  /// Standard light theme syntax tokens.
  factory JsonTreeTheme.light() {
    return const JsonTreeTheme(
      keyColor: Color(0xFF1565C0), // Blue 800
      stringColor: Color(0xFF2E7D32), // Green 800
      numberColor: Color(0xFFE65100), // Orange 900
      booleanColor: Color(0xFF6A1B9A), // Purple 900
      nullColor: Color(0xFF757575), // Grey 600
      punctuationColor: Color(0xFF616161), // Grey 700
      indentGuideColor: Color(0x1F000000), // Muted black guide line
      searchHighlightColor: Color(0x66FFE082), // Soft amber highlight
      searchActiveColor: Color(0xFFFFCA28), // Active amber
      badgeBackgroundColor: Color(0x1F1976D2),
    );
  }

  /// Selects theme automatically based on the current Flutter [BuildContext].
  factory JsonTreeTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? JsonTreeTheme.dark() : JsonTreeTheme.light();
  }
}
