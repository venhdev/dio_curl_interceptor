import 'package:flutter/material.dart';

/// Base interface for all color palettes used in the CurlViewer
///
/// This ensures type safety and consistency across different palette types
/// (StatusColorPalette, MethodColorPalette, etc.)
abstract class ColorPalette {
  /// Primary color of the palette
  Color get primary;

  /// Secondary color of the palette
  Color get secondary;

  /// Light version of the primary color
  Color get light;

  /// Lighter version of the primary color
  Color get lighter;

  /// Dark version of the primary color
  Color get dark;

  /// Background color using this palette
  Color get background;

  /// Border color for outlines
  Color get border;

  /// Shadow color for drop shadows
  Color get shadow;
}
