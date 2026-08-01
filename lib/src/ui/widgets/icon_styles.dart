import 'package:flutter/material.dart';

/// Centralized icon style constants for consistent sizing, spacing, and radii
/// across all UI widgets. Single source of truth — no behavior, just values.
class ActionIconStyle {
  // Private constructor to prevent instantiation
  ActionIconStyle._();

  // ============================================================================
  // ICON SIZES
  // ============================================================================

  /// Extra small — compact clear buttons, dense layouts
  static const double sizeXS = 14;

  /// Small — action buttons in list items (copy, share)
  static const double sizeSM = 16;

  /// Medium — header buttons (reload, close, terminal)
  static const double sizeMD = 18;

  /// Large — popup menu items, prominent actions
  static const double sizeLG = 20;

  /// Extra large — prominent dialog icons (filter, test result)
  static const double sizeXL = 24;

  // ============================================================================
  // BORDER RADII
  // ============================================================================

  /// Small — action buttons (copy, share, clear)
  static const double radiusSM = 6;

  /// Medium — header icon buttons (reload, filter, close)
  static const double radiusMD = 12;

  // ============================================================================
  // PADDING / INSETS
  // ============================================================================

  /// Small — action buttons in list items
  static const EdgeInsets paddingSM = EdgeInsets.all(6);

  // ============================================================================
  // COMMON DECORATIONS (for Container wrappers)
  // ============================================================================

  /// Subtle background + border for action buttons (copy, share)
  static BoxDecoration actionButtonDecoration(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusSM),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      );
}
